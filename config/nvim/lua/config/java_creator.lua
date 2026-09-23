-- ~/.config/nvim/lua/config/java_creator.lua
local M = {}

local is_windows = vim.uv.os_uname().sysname:find("Windows") ~= nil

----------------------------------------------------------------------
-- Async UI Prompts (Flattened Callback Hell via Coroutines)
----------------------------------------------------------------------

local ui = {}

function ui.select(items, opts)
	local co = coroutine.running()
	vim.ui.select(items, opts, function(choice, idx)
		-- vim.schedule prevents the "cannot resume non-suspended coroutine"
		-- race condition if the UI plugin executes synchronously.
		vim.schedule(function()
			coroutine.resume(co, choice, idx)
		end)
	end)
	return coroutine.yield()
end

function ui.input(opts)
	local co = coroutine.running()
	vim.ui.input(opts, function(input)
		vim.schedule(function()
			coroutine.resume(co, input)
		end)
	end)
	return coroutine.yield()
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------

-- Allows keymaps.lua to call setup() safely without errors
function M.setup(opts)
	M._setup_done = true
end

----------------------------------------------------------------------
-- Low-level helpers
----------------------------------------------------------------------

local function safe_mkdir(path)
	local ok, err = pcall(vim.fn.mkdir, path, "p")
	if not ok then
		vim.notify("Failed to create directory: " .. path .. "\nError: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	return true
end

local function safe_write(path, content)
	local file, err = io.open(path, "w")
	if not file then
		vim.notify("Failed to open file for writing: " .. path .. "\nError: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	local write_ok, write_err = pcall(function()
		file:write(content)
	end)
	file:close()
	if not write_ok then
		vim.notify("Failed to write content to: " .. path .. "\nError: " .. tostring(write_err), vim.log.levels.ERROR)
		return false
	end
	return true
end

local function refresh_jdtls()
	local ok, jdtls = pcall(require, "jdtls")
	if ok and jdtls.update_project_config then
		-- Delay ensures filesystem has synced before LSP parses
		vim.defer_fn(function()
			jdtls.update_project_config()
		end, 500)
	end
end

local function generate_build_wrapper(project_path, builder_type)
	if builder_type:find("maven") then
		vim.fn.jobstart(string.format("cd %s && mvn wrapper:wrapper", vim.fn.shellescape(project_path)))
	elseif builder_type:find("gradle") then
		vim.fn.jobstart(string.format("cd %s && gradle wrapper", vim.fn.shellescape(project_path)))
	end
end

local PLAIN_ROOT_MARKERS = {
	"pom.xml",
	"build.gradle",
	"build.gradle.kts",
	"build.xml",
	"run.sh",
	"run.bat",
	".project",
	".classpath",
	"nbproject",
}

local function is_root_marker(name)
	if vim.tbl_contains(PLAIN_ROOT_MARKERS, name) then
		return true
	end
	return name == ".idea" or name:match("%.iml$") ~= nil
end

local function find_project_root()
	if vim.fs and vim.fs.root then
		local root = vim.fs.root(0, is_root_marker)
		if root then
			return root
		end
	end
	local found = vim.fs.find(is_root_marker, { upward = true, path = vim.fn.expand("%:p:h"), limit = 1 })
	if found and #found > 0 then
		return vim.fs.dirname(found[1])
	end
	return nil
end

local function extract_package(filepath)
	local f = io.open(filepath, "r")
	if not f then
		return ""
	end
	local pkg = ""
	for line in f:lines() do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed:match("^package%s") then
			pkg = trimmed:match("^package%s+([%w_.]+)%s*;") or ""
			break
		elseif trimmed ~= "" and not trimmed:match("^//") and not trimmed:match("^/%*") then
			break
		end
	end
	f:close()
	return pkg
end

local function resolve_source_root(filepath)
	local dir = vim.fs.dirname(filepath)
	local pkg = extract_package(filepath)
	if pkg == "" then
		return dir
	end

	local pkg_parts = vim.split(pkg, ".", { plain = true })
	local root = dir
	for i = #pkg_parts, 1, -1 do
		if vim.fs.basename(root) == pkg_parts[i] then
			root = vim.fs.dirname(root)
		else
			return dir
		end
	end
	return root
end

local function collect_java_files(dirs)
	local files = {}
	local function scan(d)
		local handle = vim.uv.fs_scandir(d)
		if not handle then
			return
		end
		while true do
			local name, ftype = vim.uv.fs_scandir_next(handle)
			if not name then
				break
			end
			local full = d .. "/" .. name
			if ftype == "directory" then
				scan(full)
			elseif name:match("%.java$") then
				table.insert(files, full)
			end
		end
	end
	for _, d in ipairs(dirs) do
		scan(d)
	end
	return files
end

local function find_main_classes(src_roots)
	local candidates = {}
	for _, file in ipairs(collect_java_files(src_roots)) do
		local f = io.open(file, "r")
		if f then
			local content = f:read("*a")
			f:close()
			if content:find("public%s+static%s+void%s+main") then
				local class_name = vim.fn.fnamemodify(file, ":t:r")
				local pkg = extract_package(file)
				local fq = pkg ~= "" and (pkg .. "." .. class_name) or class_name
				table.insert(candidates, { class = fq, file = file })
			end
		end
	end
	return candidates
end

local function parse_eclipse_source_dirs(classpath_file)
	local f = io.open(classpath_file, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()
	local dirs = {}
	for entry in content:gmatch("<classpathentry[^>]+>") do
		if entry:find('kind="src"') then
			local path = entry:match('path="([^"]+)"')
			if path and not path:find("^/") then
				table.insert(dirs, path)
			end
		end
	end
	return dirs
end

local function parse_eclipse_lib_jars(classpath_file, root)
	local f = io.open(classpath_file, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()

	local m2_repo = vim.fn.expand("$HOME/.m2/repository")
	local jars = {}
	for entry in content:gmatch("<classpathentry[^>]+>") do
		if entry:find('kind="lib"') then
			local path = entry:match('path="([^"]+)"')
			if path then
				if path:match("^/") or path:match("^%a:[\\/]") then
					table.insert(jars, path)
				else
					table.insert(jars, root .. "/" .. path)
				end
			end
		elseif entry:find('kind="var"') then
			local path = entry:match('path="([^"]+)"')
			if path then
				table.insert(jars, (path:gsub("^M2_REPO/", m2_repo .. "/")))
			end
		end
	end
	return jars
end

local function parse_iml_lib_jars(iml_file)
	local module_dir = vim.fs.dirname(iml_file)
	local f = io.open(iml_file, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()

	local jars = {}
	for url in content:gmatch('url="jar://([^"]+)!/?"') do
		table.insert(jars, (url:gsub("%$MODULE_DIR%$", module_dir)))
	end
	return jars
end

----------------------------------------------------------------------
-- Terminal Engine Execution
----------------------------------------------------------------------

--- Run a (usually short-lived) compile+run command and **keep the
--- terminal open** so the user can actually read the program output.
--- Snacks defaults `interactive = true` → `auto_close = true`, which
--- closes the window the instant a successful `java` process exits —
--- exactly the "shows Compiling… then nothing" bug.
function M._execute_in_terminal(cmd)
	local ok, snacks = pcall(require, "snacks")
	if ok and snacks.terminal then
		snacks.terminal(cmd, {
			interactive = true,
			auto_close = false, -- keep output visible after exit
			win = {
				position = "bottom",
				height = 0.45,
			},
		})
	else
		-- Reliable native fallback: open a bottom split then start the
		-- job *in that buffer* via termopen (jobstart+term after a bare
		-- split is fragile and can leave an empty window).
		vim.cmd("botright split")
		vim.cmd("resize 12")
		vim.fn.termopen(cmd)
		vim.cmd("startinsert")
	end
end

----------------------------------------------------------------------
-- Generic compile + run
----------------------------------------------------------------------

function M._run_generic(root, src_roots, extra_cp)
	local java_files = collect_java_files(src_roots)
	if #java_files == 0 then
		vim.notify("No .java files found under: " .. table.concat(src_roots, ", "), vim.log.levels.ERROR)
		return
	end

	local candidates = find_main_classes(src_roots)
	if #candidates == 0 then
		vim.notify("Could not find a main method under: " .. table.concat(src_roots, ", "), vim.log.levels.ERROR)
		return
	end

	local bin_dir = root .. "/.nvim-java-bin"
	if not safe_mkdir(bin_dir) then
		return
	end

	local sep = is_windows and ";" or ":"
	local cp_parts = { bin_dir }
	for _, libdir in ipairs({ root .. "/lib", root .. "/libs" }) do
		if vim.fn.isdirectory(libdir) == 1 then
			table.insert(cp_parts, libdir .. "/*")
		end
	end
	for _, entry in ipairs(extra_cp or {}) do
		table.insert(cp_parts, entry)
	end
	local cp = table.concat(cp_parts, sep)

	local escaped_files = {}
	for _, f in ipairs(java_files) do
		table.insert(escaped_files, vim.fn.shellescape(f))
	end

	local function compile_and_run(main_class)
		-- Explicit echo lines so the user always sees progress even when
		-- the terminal stays open after a fast successful run.
		local cmd = string.format(
			"cd %s && echo Compiling... && javac -d %s -cp %s %s && echo Running... && echo -------------------------- && java -cp %s %s && echo -------------------------- && echo '(process exited — close this terminal with :q or sc)'",
			vim.fn.shellescape(root),
			vim.fn.shellescape(bin_dir),
			vim.fn.shellescape(cp),
			table.concat(escaped_files, " "),
			vim.fn.shellescape(cp),
			vim.fn.shellescape(main_class)
		)
		M._execute_in_terminal(cmd)
	end

	if #candidates == 1 then
		compile_and_run(candidates[1].class)
		return
	end

	coroutine.wrap(function()
		local labels = {}
		for _, c in ipairs(candidates) do
			table.insert(labels, string.format("%s  (%s)", c.class, vim.fs.basename(c.file)))
		end
		local _, idx = ui.select(labels, { prompt = "Multiple main classes found — run which one?" })
		if idx then
			compile_and_run(candidates[idx].class)
		end
	end)()
end

local function resolve_maven_classpath(root, mvn_bin)
	local cp_file = vim.fn.tempname()
	local cmd = string.format(
		"cd %s && %s -q dependency:build-classpath -Dmdep.outputFile=%s",
		vim.fn.shellescape(root),
		mvn_bin,
		vim.fn.shellescape(cp_file)
	)
	vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil
	end
	local f = io.open(cp_file, "r")
	if not f then
		return nil
	end
	local cp = (f:read("*a") or ""):gsub("%s+$", "")
	f:close()
	os.remove(cp_file)
	return cp ~= "" and cp or nil
end

local function resolve_gradle_classpath(root, gradlew)
	local init_file = vim.fn.tempname() .. ".gradle"
	local wrote = safe_write(
		init_file,
		"allprojects { tasks.register('nvimPrintRuntimeClasspath') { doLast { println sourceSets.main.runtimeClasspath.asPath } } }"
	)
	if not wrote then
		return nil
	end

	local cmd = string.format(
		"cd %s && %s -q --init-script %s nvimPrintRuntimeClasspath",
		vim.fn.shellescape(root),
		gradlew,
		vim.fn.shellescape(init_file)
	)
	local output = vim.fn.system(cmd)
	os.remove(init_file)
	if vim.v.shell_error ~= 0 then
		return nil
	end
	local cp = output:gsub("%s+$", "")
	return cp ~= "" and cp or nil
end

----------------------------------------------------------------------
-- Validation
----------------------------------------------------------------------

local JAVA_RESERVED_WORDS = {
	["abstract"] = true,
	["assert"] = true,
	["boolean"] = true,
	["break"] = true,
	["byte"] = true,
	["case"] = true,
	["catch"] = true,
	["char"] = true,
	["class"] = true,
	["const"] = true,
	["continue"] = true,
	["default"] = true,
	["do"] = true,
	["double"] = true,
	["else"] = true,
	["enum"] = true,
	["extends"] = true,
	["final"] = true,
	["finally"] = true,
	["float"] = true,
	["for"] = true,
	["goto"] = true,
	["if"] = true,
	["implements"] = true,
	["import"] = true,
	["instanceof"] = true,
	["int"] = true,
	["interface"] = true,
	["long"] = true,
	["native"] = true,
	["new"] = true,
	["package"] = true,
	["private"] = true,
	["protected"] = true,
	["public"] = true,
	["return"] = true,
	["short"] = true,
	["static"] = true,
	["strictfp"] = true,
	["super"] = true,
	["switch"] = true,
	["synchronized"] = true,
	["this"] = true,
	["throw"] = true,
	["throws"] = true,
	["transient"] = true,
	["try"] = true,
	["void"] = true,
	["volatile"] = true,
	["while"] = true,
	["true"] = true,
	["false"] = true,
	["null"] = true,
	["var"] = true,
	["record"] = true,
	["yield"] = true,
}

local function is_valid_java_identifier(s)
	if not s or s == "" then
		return false
	end
	if not s:match("^[A-Za-z_$][A-Za-z0-9_$]*$") then
		return false
	end
	return not JAVA_RESERVED_WORDS[s]
end

local function validate_package_name(pkg)
	if pkg == "" then
		return true
	end
	for segment in (pkg .. "."):gmatch("(.-)%.") do
		if not is_valid_java_identifier(segment) then
			return false, string.format("'%s' is not a valid Java package segment", segment)
		end
	end
	return true
end

local function validate_class_name(name)
	if not is_valid_java_identifier(name) then
		return false, string.format("'%s' is not a valid Java class name", name)
	end
	return true
end

local function validate_project_name(name)
	name = name:gsub("%s+", "-")
	if name == "" or name == "." or name == ".." then
		return false, "Project name can't be empty, '.', or '..'"
	end
	if not name:match("^[A-Za-z0-9_.%-]+$") then
		return false, "Project name can only contain letters, digits, '_', '-', and '.'"
	end
	return true, name
end

----------------------------------------------------------------------
-- Templates
----------------------------------------------------------------------

local templates = {}

-- A uniform, robust gitignore for modern Java development
local GITIGNORE_CONTENT = [[
target/
build/
.gradle/
bin/
*.class
.settings/
.classpath
.project
.idea/
*.iml
.DS_Store
.nvim-java-bin/
]]

function templates.no_build_tools(opts)
	local src_dir = opts.project_path .. "/src"
	local bin_dir = opts.project_path .. "/bin"
	local lib_dir = opts.project_path .. "/lib"
	local vscode_dir = opts.project_path .. "/.vscode"

	safe_mkdir(src_dir)
	safe_mkdir(bin_dir)
	safe_mkdir(lib_dir)
	safe_mkdir(vscode_dir)

	local package_path = opts.package_name:gsub("%.", "/")
	local class_dir = package_path ~= "" and (src_dir .. "/" .. package_path) or src_dir
	safe_mkdir(class_dir)

	local package_header = opts.package_name ~= "" and ("package " .. opts.package_name .. ";\n\n") or ""
	local java_content = package_header
		.. "public class "
		.. opts.class_name
		.. ' {\n    public static void main(String[] args) {\n        System.out.println("Hello, World from '
		.. opts.project_name
		.. '!");\n    }\n}\n'
	local java_file_path = class_dir .. "/" .. opts.class_name .. ".java"
	safe_write(java_file_path, java_content)

	local project_content = [=[<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
	<name>]=] .. opts.project_name .. [=[</name>
	<comment></comment>
	<projects></projects>
	<buildSpec>
		<buildCommand><name>org.eclipse.jdt.core.javabuilder</name><arguments></arguments></buildCommand>
	</buildSpec>
	<natures><nature>org.eclipse.jdt.core.javanature</nature></natures>
</projectDescription>
]=]
	safe_write(opts.project_path .. "/.project", project_content)
	safe_write(
		opts.project_path .. "/.classpath",
		[=[<?xml version="1.0" encoding="UTF-8"?>
<classpath>
	<classpathentry kind="src" path="src"/>
	<classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
	<classpathentry kind="output" path="bin"/>
</classpath>
]=]
	)
	safe_write(
		opts.project_path .. "/.vscode/settings.json",
		[=[{"java.project.sourcePaths": ["src"],"java.project.outputPath": "bin","java.project.referencedLibraries": ["lib/**/*.jar"]}]=]
	)

	local full_main_class = opts.package_name ~= "" and (opts.package_name .. "." .. opts.class_name) or opts.class_name

	-- Portable bash runner (Git Bash / WSL / macOS / Linux).
	-- Avoids process substitution so it works under bash 3.x and plain sh.
	local run_script_content = string.format(
		[[#!/usr/bin/env bash
set -eu
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
mkdir -p bin

# Collect sources without process substitution (portable)
JAVA_FILES=$(find src -name '*.java' 2>/dev/null || true)
if [ -z "$JAVA_FILES" ]; then
  echo "No .java files found under src/" >&2
  exit 1
fi

CP="bin"
if [ -d lib ]; then
  for jar in lib/*.jar; do
    [ -f "$jar" ] && CP="$CP:$jar"
  done
fi

echo "Compiling project..."
# shellcheck disable=SC2086
javac -d bin -sourcepath src -cp "$CP" $JAVA_FILES
echo "Running..."
echo "--------------------------"
java -cp "$CP" %s
echo "--------------------------"
echo "(process exited — close this terminal with :q or sc)"
]],
		full_main_class
	)

	local run_script_path = opts.project_path .. "/run.sh"
	safe_write(run_script_path, run_script_content)
	pcall(vim.fn.setfperm, run_script_path, "rwxr-xr-x")

	-- Native Windows batch companion (used when is_windows + run.bat exists).
	local run_bat_content = string.format(
		[[@echo off
setlocal EnableDelayedExpansion
cd /d "%%~dp0"
if not exist bin mkdir bin

set "JAVA_FILES="
for /r src %%%%f in (*.java) do set "JAVA_FILES=!JAVA_FILES! "%%%%f""

if "!JAVA_FILES!"=="" (
  echo No .java files found under src\
  exit /b 1
)

set "CP=bin"
if exist lib\ (
  for %%%%j in (lib\*.jar) do set "CP=!CP!;%%%%j"
)

echo Compiling project...
javac -d bin -sourcepath src -cp "!CP!" !JAVA_FILES!
if errorlevel 1 (
  echo Compilation failed.
  exit /b 1
)
echo Running...
echo --------------------------
java -cp "!CP!" %s
echo --------------------------
echo (process exited — close this terminal with :q or sc)
]],
		full_main_class
	)
	safe_write(opts.project_path .. "/run.bat", run_bat_content)

	safe_write(opts.project_path .. "/.gitignore", GITIGNORE_CONTENT)

	return java_file_path
end

function templates.maven(opts)
	local package_path = opts.package_name:gsub("%.", "/")
	local main_src_dir = opts.project_path .. "/src/main/java/" .. package_path
	local test_src_dir = opts.project_path .. "/src/test/java/" .. package_path
	safe_mkdir(main_src_dir)
	safe_mkdir(test_src_dir)
	safe_mkdir(opts.project_path .. "/src/main/resources")

	local package_header = opts.package_name ~= "" and ("package " .. opts.package_name .. ";\n\n") or ""
	local java_file_path = main_src_dir .. "/" .. opts.class_name .. ".java"
	safe_write(
		java_file_path,
		package_header
			.. "public class "
			.. opts.class_name
			.. ' {\n    public static void main(String[] args) {\n        System.out.println("Hello from Maven!");\n    }\n}\n'
	)
	safe_write(
		test_src_dir .. "/" .. opts.class_name .. "Test.java",
		package_header
			.. "import org.junit.jupiter.api.Test;\nimport static org.junit.jupiter.api.Assertions.assertTrue;\n\npublic class "
			.. opts.class_name
			.. "Test {\n    @Test\n    public void shouldAnswerWithTrue() {\n        assertTrue(true);\n    }\n}\n"
	)

	local full_main_class = opts.package_name ~= "" and (opts.package_name .. "." .. opts.class_name) or opts.class_name
	local pom_content = [=[<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>]=] .. (opts.package_name ~= "" and opts.package_name or "com.example") .. [=[</groupId>
    <artifactId>]=] .. opts.project_name:lower() .. [=[</artifactId>
    <version>1.0-SNAPSHOT</version>
    <properties>
        <maven.compiler.source>]=] .. opts.java_version .. [=[</maven.compiler.source>
        <maven.compiler.target>]=] .. opts.java_version .. [=[</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <exec.mainClass>]=] .. full_main_class .. [=[</exec.mainClass>
    </properties>
    <dependencies>
        <dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter-api</artifactId><version>5.11.0</version><scope>test</scope></dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin><groupId>org.codehaus.mojo</groupId><artifactId>exec-maven-plugin</artifactId><version>3.1.1</version><configuration><mainClass>]=] .. full_main_class .. [=[</mainClass></configuration></plugin>
        </plugins>
    </build>
</project>
]=]
	safe_write(opts.project_path .. "/pom.xml", pom_content)
	safe_write(opts.project_path .. "/.gitignore", GITIGNORE_CONTENT)
	return java_file_path
end

function templates.gradle(opts)
	local package_path = opts.package_name:gsub("%.", "/")
	local main_src_dir = opts.project_path .. "/src/main/java/" .. package_path
	local test_src_dir = opts.project_path .. "/src/test/java/" .. package_path
	safe_mkdir(main_src_dir)
	safe_mkdir(test_src_dir)
	safe_mkdir(opts.project_path .. "/src/main/resources")

	local package_header = opts.package_name ~= "" and ("package " .. opts.package_name .. ";\n\n") or ""
	local java_file_path = main_src_dir .. "/" .. opts.class_name .. ".java"
	safe_write(
		java_file_path,
		package_header
			.. "public class "
			.. opts.class_name
			.. ' {\n    public static void main(String[] args) {\n        System.out.println("Hello from Gradle project!");\n    }\n}\n'
	)

	local full_main_class = opts.package_name ~= "" and (opts.package_name .. "." .. opts.class_name) or opts.class_name

	local build_gradle_content = [=[plugins {
    application
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter:5.11.0")
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(]=] .. opts.java_version .. [=[))
    }
}

application {
    mainClass.set("]=] .. full_main_class .. [=[")
}

tasks.named<Test>("test") {
    useJUnitPlatform()
}
]=]
	safe_write(opts.project_path .. "/build.gradle.kts", build_gradle_content)
	safe_write(
		opts.project_path .. "/settings.gradle.kts",
		'rootProject.name = "' .. opts.project_name:lower() .. '"\n'
	)
	safe_write(opts.project_path .. "/.gitignore", GITIGNORE_CONTENT)
	return java_file_path
end

function templates.spring_boot_maven(opts)
	local package_path = opts.package_name:gsub("%.", "/")
	local main_src_dir = opts.project_path .. "/src/main/java/" .. package_path
	local test_src_dir = opts.project_path .. "/src/test/java/" .. package_path
	safe_mkdir(main_src_dir)
	safe_mkdir(test_src_dir)
	safe_mkdir(opts.project_path .. "/src/main/resources")
	safe_write(
		opts.project_path .. "/src/main/resources/application.properties",
		"# Spring Application Properties\nserver.port=8080\n"
	)

	local package_header = opts.package_name ~= "" and ("package " .. opts.package_name .. ";\n\n") or ""
	local java_content = package_header
		.. "import org.springframework.boot.SpringApplication;\nimport org.springframework.boot.autoconfigure.SpringBootApplication;\n\n@SpringBootApplication\npublic class "
		.. opts.class_name
		.. " {\n    public static void main(String[] args) {\n        SpringApplication.run("
		.. opts.class_name
		.. '.class, args);\n        System.out.println("Spring Boot Application started successfully!");\n    }\n}\n'
	local java_file_path = main_src_dir .. "/" .. opts.class_name .. ".java"
	safe_write(java_file_path, java_content)

	local pom_content = [=[<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-parent</artifactId><version>3.4.0</version><relativePath/></parent>
    <groupId>]=] .. (opts.package_name ~= "" and opts.package_name or "com.example") .. [=[</groupId>
    <artifactId>]=] .. opts.project_name:lower() .. [=[</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <properties><java.version>]=] .. opts.java_version .. [=[</java.version></properties>
    <dependencies>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
    </dependencies>
    <build><plugins><plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin></plugins></build>
</project>
]=]
	safe_write(opts.project_path .. "/pom.xml", pom_content)
	safe_write(opts.project_path .. "/.gitignore", GITIGNORE_CONTENT)
	return java_file_path
end

function templates.spring_boot_gradle(opts)
	local package_path = opts.package_name:gsub("%.", "/")
	local main_src_dir = opts.project_path .. "/src/main/java/" .. package_path
	local test_src_dir = opts.project_path .. "/src/test/java/" .. package_path
	safe_mkdir(main_src_dir)
	safe_mkdir(test_src_dir)
	safe_mkdir(opts.project_path .. "/src/main/resources")
	safe_write(
		opts.project_path .. "/src/main/resources/application.properties",
		"# Spring Application Properties\nserver.port=8080\n"
	)

	local package_header = opts.package_name ~= "" and ("package " .. opts.package_name .. ";\n\n") or ""
	local java_file_path = main_src_dir .. "/" .. opts.class_name .. ".java"
	safe_write(
		java_file_path,
		package_header
			.. "import org.springframework.boot.SpringApplication;\nimport org.springframework.boot.autoconfigure.SpringBootApplication;\n\n@SpringBootApplication\npublic class "
			.. opts.class_name
			.. " {\n    public static void main(String[] args) {\n        SpringApplication.run("
			.. opts.class_name
			.. '.class, args);\n        System.out.println("Spring Boot Application started successfully!");\n    }\n}\n'
	)

	local build_gradle_content = [=[plugins {
    java
    id("org.springframework.boot") version "3.4.0"
    id("io.spring.dependency-management") version "1.1.4"
}

group = "]=] .. (opts.package_name ~= "" and opts.package_name or "com.example") .. [=["
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(]=] .. opts.java_version .. [=[))
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.named<Test>("test") {
    useJUnitPlatform()
}
]=]
	safe_write(opts.project_path .. "/build.gradle.kts", build_gradle_content)
	safe_write(
		opts.project_path .. "/settings.gradle.kts",
		'rootProject.name = "' .. opts.project_name:lower() .. '"\n'
	)
	safe_write(opts.project_path .. "/.gitignore", GITIGNORE_CONTENT)
	return java_file_path
end

----------------------------------------------------------------------
-- Project scaffold wizard
----------------------------------------------------------------------

function M.scaffold_project()
	coroutine.wrap(function()
		local choices = {
			{ id = "no_build_tools", label = "No Build Tools", desc = "Standalone Java project (src/bin/lib)" },
			{ id = "maven", label = "Maven (Quickstart)", desc = "Standard Apache Maven project archetype" },
			{ id = "gradle", label = "Gradle (Kotlin DSL)", desc = "Standard Gradle build system project" },
			{ id = "spring_boot_maven", label = "Spring Boot (Maven)", desc = "Spring Boot Web App with Maven" },
			{ id = "spring_boot_gradle", label = "Spring Boot (Gradle)", desc = "Spring Boot Web App with Gradle" },
		}

		local display_options = vim.tbl_map(function(item)
			return string.format("%s - %s", item.label, item.desc)
		end, choices)

		local _, type_idx = ui.select(display_options, { prompt = "Select Java Project Type:" })
		if not type_idx then
			return
		end
		local selected_type = choices[type_idx]

		local selected_version = ui.select({ "21", "17" }, { prompt = "Select Java Version (JDK):" })
		if not selected_version then
			return
		end

		local project_name = ui.input({ prompt = "Project Name: ", default = "my-java-app" })
		if not project_name or project_name:gsub("%s+", "") == "" then
			vim.notify("Project creation canceled: Project name cannot be empty", vim.log.levels.WARN)
			return
		end

		local ok, sanitized_or_err = validate_project_name(project_name)
		if not ok then
			vim.notify("Project creation canceled: " .. sanitized_or_err, vim.log.levels.ERROR)
			return
		end
		project_name = sanitized_or_err

		local base_dir = vim.fn.getcwd()
		local project_path = base_dir .. "/" .. project_name
		if vim.fn.isdirectory(project_path) == 1 then
			vim.notify("Error: Directory already exists at " .. project_path, vim.log.levels.ERROR)
			return
		end

		local package_name = ui.input({ prompt = "Group ID / Package Name: ", default = "com.example" })
		if not package_name then
			return
		end
		package_name = package_name:gsub("^%s*(.-)%s*$", "%1")

		local pkg_ok, pkg_err = validate_package_name(package_name)
		if not pkg_ok then
			vim.notify("Project creation canceled: " .. pkg_err, vim.log.levels.ERROR)
			return
		end

		local default_class = selected_type.id:find("spring") and "Application" or "Main"
		local class_name = ui.input({ prompt = "Main Class Name: ", default = default_class })
		if not class_name then
			return
		end
		class_name = class_name ~= "" and class_name or default_class

		local class_ok, class_err = validate_class_name(class_name)
		if not class_ok then
			vim.notify("Project creation canceled: " .. class_err, vim.log.levels.ERROR)
			return
		end

		if not safe_mkdir(project_path) then
			return
		end

		local opts = {
			project_path = project_path,
			project_name = project_name,
			package_name = package_name,
			class_name = class_name,
			java_version = selected_version,
		}

		local created_file = templates[selected_type.id](opts)

		if created_file then
			vim.cmd("edit " .. vim.fn.fnameescape(created_file))
			vim.notify(
				"Java project [" .. selected_type.label .. "] scaffolded successfully at " .. project_path,
				vim.log.levels.INFO
			)
			vim.cmd("checktime")
			refresh_jdtls()
			generate_build_wrapper(project_path, selected_type.id)
		end
	end)()
end

----------------------------------------------------------------------
-- Intelligent “New Java Type” generator
----------------------------------------------------------------------

local function detect_source_root()
	local root = find_project_root()
	if not root then
		local buf = vim.fn.expand("%:p")
		if buf ~= "" and vim.fn.filereadable(buf) == 1 then
			return vim.fs.dirname(buf)
		end
		return vim.fn.getcwd()
	end

	if vim.fn.filereadable(root .. "/.classpath") == 1 then
		local dirs = parse_eclipse_source_dirs(root .. "/.classpath")
		if #dirs > 0 then
			return root .. "/" .. dirs[1]
		end
	end

	for _, candidate in ipairs({ root .. "/src/main/java", root .. "/src", root }) do
		if vim.fn.isdirectory(candidate) == 1 then
			return candidate
		end
	end
	return root
end

local function guess_current_package()
	local file = vim.fn.expand("%:p")
	if file == "" or not file:match("%.java$") then
		return ""
	end
	return extract_package(file)
end

function M.new_java_type()
	coroutine.wrap(function()
		local src_root = detect_source_root()
		local default_pkg = guess_current_package()

		local kinds = {
			{ id = "class", label = "Class" },
			{ id = "interface", label = "Interface" },
			{ id = "enum", label = "Enum" },
			{ id = "record", label = "Record (Java 16+)" },
			{ id = "abstract", label = "Abstract Class" },
			{ id = "annotation", label = "Annotation" },
		}

		local labels = vim.tbl_map(function(k)
			return k.label
		end, kinds)
		local _, idx = ui.select(labels, { prompt = "New Java type:" })
		if not idx then
			return
		end
		local kind = kinds[idx].id

		local prompt = "Name"
		if default_pkg ~= "" then
			prompt = prompt .. " (package defaults to " .. default_pkg .. ")"
		end

		local input = ui.input({ prompt = prompt .. ": ", default = "" })
		if not input or input:match("^%s*$") then
			return
		end

		input = input:gsub("%s+", "")
		local package_name, class_name

		if input:find("%.") then
			package_name = input:match("(.+)%.(.+)$") or ""
			class_name = input:match(".+%.(.+)$") or input
		else
			package_name = default_pkg
			class_name = input
		end

		local ok, err = validate_class_name(class_name)
		if not ok then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		if package_name ~= "" then
			local pkg_ok, pkg_err = validate_package_name(package_name)
			if not pkg_ok then
				vim.notify(pkg_err, vim.log.levels.ERROR)
				return
			end
		end

		local rel_dir = package_name:gsub("%.", "/")
		local dir = rel_dir ~= "" and (src_root .. "/" .. rel_dir) or src_root
		if not safe_mkdir(dir) then
			return
		end

		local path = dir .. "/" .. class_name .. ".java"
		if vim.fn.filereadable(path) == 1 then
			vim.notify("File already exists: " .. path, vim.log.levels.ERROR)
			return
		end

		local package_header = package_name ~= "" and ("package " .. package_name .. ";\n\n") or ""
		local body
		if kind == "interface" then
			body = "public interface " .. class_name .. " {\n    \n}\n"
		elseif kind == "enum" then
			body = "public enum " .. class_name .. " {\n    \n}\n"
		elseif kind == "record" then
			body = "public record " .. class_name .. "() {\n    \n}\n"
		elseif kind == "abstract" then
			body = "public abstract class " .. class_name .. " {\n    \n}\n"
		elseif kind == "annotation" then
			body = "public @interface " .. class_name .. " {\n    \n}\n"
		else
			body = "public class " .. class_name .. " {\n    \n}\n"
		end

		if not safe_write(path, package_header .. body) then
			return
		end

		vim.cmd("edit " .. vim.fn.fnameescape(path))
		vim.schedule(function()
			vim.cmd("normal! Gkk$")
		end)
		vim.notify(string.format("Created %s %s", kind, class_name), vim.log.levels.INFO)

		refresh_jdtls()
	end)()
end

----------------------------------------------------------------------
-- Top-level “New …” menu
----------------------------------------------------------------------

function M.new()
	coroutine.wrap(function()
		local choice = ui.select(
			{ "New Project", "New File (Class / Interface / Enum / …)" },
			{ prompt = "Java Creator:" }
		)
		if not choice then
			return
		end
		if choice:find("Project") then
			M.scaffold_project()
		else
			M.new_java_type()
		end
	end)()
end

----------------------------------------------------------------------
-- Run project
----------------------------------------------------------------------

function M.run_project()
	-- Early sanity: without javac/java on PATH the terminal will just print
	-- cryptic shell errors. Fail fast with a clear message.
	if vim.fn.executable("javac") ~= 1 or vim.fn.executable("java") ~= 1 then
		vim.notify("javac/java not found on PATH. Install a JDK and ensure both are available.", vim.log.levels.ERROR)
		return
	end

	local root = find_project_root()

	if not root then
		local file = vim.fn.expand("%:p")
		if vim.bo.filetype ~= "java" or file == "" then
			vim.notify("No active Java file or recognized Java project root found.", vim.log.levels.ERROR)
			return
		end
		local src_root = resolve_source_root(file)
		M._run_generic(src_root, { src_root })
		return
	end

	local run_cmd = nil

	if vim.fn.filereadable(root .. "/pom.xml") == 1 then
		local f = io.open(root .. "/pom.xml", "r")
		local pom_content = f and f:read("*a") or ""
		if f then
			f:close()
		end

		local is_spring = pom_content:find("spring%-boot") ~= nil
		local has_exec_plugin = pom_content:find("exec%-maven%-plugin") ~= nil
		local mvn_bin = (vim.fn.filereadable(root .. "/mvnw") == 1 or vim.fn.filereadable(root .. "/mvnw.cmd") == 1)
				and (is_windows and ".\\mvnw.cmd" or "./mvnw")
			or "mvn"

		if is_spring then
			run_cmd = string.format("cd %s && %s spring-boot:run", vim.fn.shellescape(root), mvn_bin)
		elseif has_exec_plugin then
			run_cmd = string.format("cd %s && %s compile exec:java", vim.fn.shellescape(root), mvn_bin)
		else
			vim.notify("No exec-maven-plugin found — resolving dependencies directly.", vim.log.levels.INFO)
			local mvn_cp = resolve_maven_classpath(root, mvn_bin)
			if not mvn_cp then
				vim.notify("Failed to resolve Maven dependencies.", vim.log.levels.ERROR)
				return
			end
			local src_root = vim.fn.isdirectory(root .. "/src/main/java") == 1 and (root .. "/src/main/java")
				or (root .. "/src")
			M._run_generic(root, { src_root }, { mvn_cp })
			return
		end
	elseif
		vim.fn.filereadable(root .. "/build.gradle") == 1 or vim.fn.filereadable(root .. "/build.gradle.kts") == 1
	then
		local f = io.open(root .. "/build.gradle", "r") or io.open(root .. "/build.gradle.kts", "r")
		local gradle_content = f and f:read("*a") or ""
		if f then
			f:close()
		end

		local gradlew = (
			vim.fn.filereadable(root .. "/gradlew") == 1 or vim.fn.filereadable(root .. "/gradlew.bat") == 1
		)
				and (is_windows and ".\\gradlew.bat" or "./gradlew")
			or "gradle"

		local is_spring = gradle_content:find("spring%-boot") ~= nil
			or gradle_content:find("org.springframework.boot") ~= nil
		local has_application_plugin = gradle_content:find("application") ~= nil

		if is_spring then
			run_cmd = string.format("cd %s && %s bootRun", vim.fn.shellescape(root), gradlew)
		elseif has_application_plugin then
			run_cmd = string.format("cd %s && %s run", vim.fn.shellescape(root), gradlew)
		else
			vim.notify("No `application` plugin found — resolving dependencies directly.", vim.log.levels.INFO)
			local gradle_cp = resolve_gradle_classpath(root, gradlew)
			if not gradle_cp then
				vim.notify("Failed to resolve Gradle dependencies.", vim.log.levels.ERROR)
				return
			end
			local src_root = vim.fn.isdirectory(root .. "/src/main/java") == 1 and (root .. "/src/main/java")
				or (root .. "/src")
			M._run_generic(root, { src_root }, { gradle_cp })
			return
		end
	elseif is_windows and vim.fn.filereadable(root .. "/run.bat") == 1 then
		-- Prefer the native batch file on Windows (cmd / PowerShell).
		run_cmd = string.format("cd /d %s && run.bat", vim.fn.shellescape(root))
	elseif vim.fn.filereadable(root .. "/run.sh") == 1 then
		-- Use an explicit bash invocation so it works even when the
		-- execute bit is missing or the shell is not already bash
		-- (common under Git Bash / WSL / macOS).
		local bash = (vim.fn.executable("bash") == 1) and "bash" or "sh"
		run_cmd = string.format("cd %s && %s ./run.sh", vim.fn.shellescape(root), bash)
	elseif
		vim.fn.filereadable(root .. "/build.xml") == 1 or vim.fn.filereadable(root .. "/nbproject/project.xml") == 1
	then
		if vim.fn.executable("ant") == 1 then
			run_cmd = string.format("cd %s && ant run", vim.fn.shellescape(root))
		else
			vim.notify("`ant` not found on PATH — falling back to generic run.", vim.log.levels.WARN)
			local src_root = vim.fn.isdirectory(root .. "/src") == 1 and (root .. "/src") or root
			M._run_generic(root, { src_root })
			return
		end
	end

	if run_cmd then
		M._execute_in_terminal(run_cmd)
		return
	end

	local src_roots, extra_cp = {}, {}
	if vim.fn.filereadable(root .. "/.classpath") == 1 then
		local cp_file = root .. "/.classpath"
		for _, rel in ipairs(parse_eclipse_source_dirs(cp_file)) do
			table.insert(src_roots, root .. "/" .. rel)
		end
		vim.list_extend(extra_cp, parse_eclipse_lib_jars(cp_file, root))
	end

	for _, iml in ipairs(vim.fn.glob(root .. "/*.iml", false, true)) do
		vim.list_extend(extra_cp, parse_iml_lib_jars(iml))
	end

	if #src_roots == 0 then
		for _, candidate in ipairs({ root .. "/src/main/java", root .. "/src", root }) do
			if vim.fn.isdirectory(candidate) == 1 then
				table.insert(src_roots, candidate)
				break
			end
		end
	end

	if #src_roots > 0 then
		M._run_generic(root, src_roots, extra_cp)
	else
		vim.notify("Could not determine execution strategy for Java project at: " .. root, vim.log.levels.ERROR)
	end
end

return M
