#!/usr/bin/env bash
# Headless smoke test: restore plugins to the lockfile, boot the config, and
# fail if anything logged an error. Run from anywhere:  ./scripts/smoke-test.sh
set -euo pipefail

echo "› restoring plugins from lazy-lock.json"
timeout 600 nvim --headless "+Lazy! restore" +qa

echo "› booting config and collecting :messages"
out=$(timeout 120 nvim --headless \
  "+lua vim.defer_fn(function() io.stdout:write(vim.api.nvim_exec2('messages', {output = true}).output .. '\n'); vim.cmd('qa!') end, 4000)" 2>&1 || true)
echo "$out"

if echo "$out" | grep -Eq "E[0-9]{3,4}:|Error executing|Failed to load|module '[^']*' not found|Error detected while processing"; then
  echo "✗ errors found during startup" >&2
  exit 1
fi

if command -v stylua >/dev/null 2>&1; then
  echo "› stylua --check"
  stylua --check .
fi
echo "✓ smoke test passed"
