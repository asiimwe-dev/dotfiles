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
	return vim.fs.root(0, is_root_marker)
end

local function extract_package(filepath)
	local f = io.open(filepath, "r")
	if not f then
		return ""
	end
	local pkg, in_block = "", false
	for line in f:lines() do
		local trimmed = line:match("^%s*(.-)%s*$")
		if in_block then
			-- inside a /* ... */ (licence header, javadoc): wait for the end
			if trimmed:find("*/", 1, true) then
				in_block = false
			end
		elseif trimmed:match("^/%*") then
			in_block = not trimmed:find("*/", 3, true)
		elseif trimmed == "" or trimmed:match("^//") then
			-- skip blank lines and line comments
		elseif trimmed:match("^package%s") then
			pkg = trimmed:match("^package%s+([%w_.]+)%s*;") or ""
			break
		else
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

local SKIP_DIRS = {
	[".git"] = true,
	[".gradle"] = true,
	[".idea"] = true,
	node_modules = true,
	target = true,
	build = true,
	out = true,
}

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
				if not SKIP_DIRS[name] then
					scan(full)
				end
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
			if content:find("static%s+void%s+main%s*%(") then
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
		-- job *in that buffer* via jobstart({ term = true }) (the old
		-- split is fragile and can leave an empty window).
		vim.cmd("botright new")
		vim.cmd("resize 12")
		vim.fn.jobstart(cmd, { term = true })
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

	-- Build output lives in the cache dir (not inside the project) and is wiped
	-- every run so classes from deleted/renamed sources can't linger.
	local bin_dir = vim.fn.stdpath("cache") .. "/java-bin/" .. vim.fn.sha256(root):sub(1, 12)
	vim.fn.delete(bin_dir, "rf")
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
			"cd %s && echo Compiling... && javac -d %s -cp %s %s && echo Running... && echo -------------------------- && java -cp %s %s && echo -------------------------- && echo '(process exited — close this terminal with :q or <leader>wd)'",
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

--- Resolve the Maven classpath without blocking the UI. `callback(cp|nil)`.
local function resolve_maven_classpath(root, mvn_bin, callback)
	local cp_file = vim.fn.tempname()
	local ok, err = pcall(
		vim.system,
		{ mvn_bin, "-q", "dependency:build-classpath", "-Dmdep.outputFile=" .. cp_file },
		{ cwd = root, text = true },
		vim.schedule_wrap(function(res)
			local cp
			if res.code == 0 then
				local f = io.open(cp_file, "r")
				if f then
					cp = (f:read("*a") or ""):gsub("%s+$", "")
					f:close()
				end
			end
			os.remove(cp_file)
			callback((cp and cp ~= "") and cp or nil)
		end)
	)
	if not ok then
		vim.notify("Could not start Maven: " .. tostring(err), vim.log.levels.ERROR)
		callback(nil)
	end
end

--- Resolve the Gradle runtime classpath without blocking the UI. Works for
--- multi-project builds: only projects that apply the `java` plugin register
--- the task, and every project's classpath is joined.
local function resolve_gradle_classpath(root, gradlew, callback)
	local init_file = vim.fn.tempname() .. ".gradle"
	local script = table.concat({
		"allprojects {",
		"  plugins.withId('java') {",
		"    tasks.register('nvimPrintRuntimeClasspath') {",
		"      doLast { println sourceSets.main.runtimeClasspath.asPath }",
		"    }",
		"  }",
		"}",
		"",
	}, "\n")
	if not safe_write(init_file, script) then
		callback(nil)
		return
	end

	local ok, err = pcall(
		vim.system,
		{ gradlew, "-q", "--init-script", init_file, "nvimPrintRuntimeClasspath" },
		{ cwd = root, text = true },
		vim.schedule_wrap(function(res)
			os.remove(init_file)
			if res.code ~= 0 then
				callback(nil)
				return
			end
			local parts = {}
			for line in (res.stdout or ""):gmatch("[^\r\n]+") do
				parts[#parts + 1] = line
			end
			callback(#parts > 0 and table.concat(parts, is_windows and ";" or ":") or nil)
		end)
	)
	if not ok then
		os.remove(init_file)
		vim.notify("Could not start Gradle: " .. tostring(err), vim.log.levels.ERROR)
		callback(nil)
	end
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

	local current = vim.fn.expand("%:p"):gsub("\\", "/")
	local test_root = root .. "/src/test/java"
	if current:find("/src/test/java/", 1, true) and vim.fn.isdirectory(test_root) == 1 then
		return test_root
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
			vim.cmd("normal! Gk$")
		end)
		vim.notify(string.format("Created %s %s", kind, class_name), vim.log.levels.INFO)

		refresh_jdtls()
	end)()
end

----------------------------------------------------------------------
-- Top-level “New …” menu
----------------------------------------------------------------------


function M.new()
	M.new_java_type()
end

function M.scaffold_project()
	vim.notify("Project scaffolding is now managed by the standalone `jgen` CLI. Run `jgen` in your terminal!", vim.log.levels.INFO)
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
			vim.notify("No exec-maven-plugin found — resolving dependencies in the background…", vim.log.levels.INFO)
			local src_root = vim.fn.isdirectory(root .. "/src/main/java") == 1 and (root .. "/src/main/java")
				or (root .. "/src")
			resolve_maven_classpath(root, mvn_bin, function(mvn_cp)
				if not mvn_cp then
					vim.notify("Failed to resolve Maven dependencies.", vim.log.levels.ERROR)
					return
				end
				M._run_generic(root, { src_root }, { mvn_cp })
			end)
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
		local has_application_plugin = gradle_content:find("id%s*%(?%s*[\"']application[\"']") ~= nil
			or gradle_content:find("plugin:%s*[\"']application[\"']") ~= nil
			or gradle_content:find("\n%s*application%s*\n") ~= nil

		if is_spring then
			run_cmd = string.format("cd %s && %s bootRun", vim.fn.shellescape(root), gradlew)
		elseif has_application_plugin then
			run_cmd = string.format("cd %s && %s run", vim.fn.shellescape(root), gradlew)
		else
			vim.notify("No `application` plugin found — resolving dependencies in the background…", vim.log.levels.INFO)
			local src_root = vim.fn.isdirectory(root .. "/src/main/java") == 1 and (root .. "/src/main/java")
				or (root .. "/src")
			resolve_gradle_classpath(root, gradlew, function(gradle_cp)
				if not gradle_cp then
					vim.notify("Failed to resolve Gradle dependencies.", vim.log.levels.ERROR)
					return
				end
				M._run_generic(root, { src_root }, { gradle_cp })
			end)
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
