# Copilot Instructions for dIIIhl Repository

This repository contains **1Password Agent Hooks**, shell-based hooks that integrate 1Password security validations into AI code editors and agents (Cursor, GitHub Copilot, Claude Code, Windsurf).

## Repository Structure

The repository is organized as a collection of tools and projects:

- **`agent-hooks/`** — 1Password agent hooks project (the main component)
  - `hooks/` — Individual hook implementations (e.g., `1password-validate-mounted-env-files/`)
  - `lib/` — Shared shell utilities (`logging.sh`, `os.sh`, `paths.sh`, `json.sh`)
  - `adapters/` — Agent-specific adapter layers (cursor, github-copilot, claude-code, windsurf)
  - `bin/` — Entry point (`run-hook.sh`) that dispatches to specific hooks
  - `tests/` — Bats test suite
  - `install.sh` — Installation script that bundles hooks for a target agent
  - `CONTRIBUTING.md` — Development guidelines
  - `README.md` — User-facing documentation

- **`dokploy/`**, **`VictoriaMetrics/`**, **`komodo/`**, **`apps/`** — Other independent projects (out of scope for this repository's main purpose)

## Build, Test, and Lint Commands

### Testing
The project uses **Bats** (Bash Automated Testing System) for unit and integration tests.

```bash
# Run all tests from repo root
bats -r tests/

# Run specific test file
bats tests/adapters/cursor.bats

# Run tests for a specific hook
bats tests/hooks/1password-validate-mounted-env-files.bats
```

### Installation/Bundling
No traditional "build" step exists. The `install.sh` script creates portable bundles:

```bash
# Create a bundle in current directory (no config file)
./install.sh --agent cursor

# Install bundle to a target directory and create config if missing
./install.sh --agent github-copilot --target-dir /path/to/repo
```

Supported agents: `cursor`, `github-copilot`, `claude-code`, `windsurf`

### Code Quality
No linters or formatters are configured. Contributions follow POSIX shell conventions (see CONTRIBUTING.md).

## High-Level Architecture

### Hook Execution Flow

1. **Agent Config** (`hooks.json` or `settings.json`) specifies which hook to run on which event
2. **`bin/run-hook.sh`** receives the hook name and agent's JSON payload via stdin
3. **Client detection** (`adapters/_lib.sh::detect_client()`) identifies the agent by checking environment variables and payload fields in priority order:
   - **Cursor**: `CURSOR_VERSION` env var or `cursor_version` field
   - **Claude Code**: `CLAUDE_PROJECT_DIR` env var or `permission_mode` field
   - **Windsurf**: `agent_action_name` field
   - **GitHub Copilot**: `hook_event_name` field (after others ruled out)
   - **Unknown**: Falls back to generic adapter
4. **Adapter normalization** (`adapters/<client>.sh`) converts agent-specific JSON to canonical format
5. **Hook dispatcher** loads and executes `hooks/<hook-name>/hook.sh`, timing execution
6. **Hook output translation** converts canonical JSON back to agent-specific format
7. **Fail-open fallback** on any error (logs warning, emits allow, exits 0)

### Key Components

- **Hooks** are independent, self-contained shell scripts in `hooks/<hook-name>/hook.sh`
- **Adapters** translate between agent-specific JSON formats and the canonical hook payload format
- **Shared libraries** (`lib/`) provide utilities:
  - `logging.sh` — Log to file or stderr (with DEBUG=1)
  - `os.sh` — OS detection (macOS, Linux, Windows)
  - `json.sh` — Simple JSON parsing (key extraction, value decoding)
  - `paths.sh` — Path normalization and resolution

### Validation Patterns

Hooks follow a "fail open" approach:
- If dependencies (e.g., `sqlite3`, 1Password CLI) are unavailable, hooks allow execution
- This prevents blocking development when external tools are missing

## Key Conventions

### Shell Script Conventions

- **Shebang**: `#!/usr/bin/env bash` or `#!/bin/bash` (top of all executables)
- **Error handling**: `set -euo pipefail` (at the start of scripts) — exit on error, undefined vars, pipe failures
- **Sourcing guards**: Libraries use `[[ -n "${_LIB_NAME_LOADED:-}" ]] && return 0` to prevent duplicate loading
- **Logging**: Use `log()` function from `lib/logging.sh`
- **Function naming**: Use `_lib_internal_func` prefix for internal utilities, `public_func` for exported functions
- **Output format**: Hooks output canonical JSON with `decision` and `message` keys
- **JSON parsing**: Use functions from `lib/json.sh` (no `jq` dependency)
  - `extract_json_string "$json" "key"` — Safe extraction with backslash unescaping
  - `escape_json_string "$string"` — Proper JSON escaping
  - `parse_json_workspace_roots "$json"` — Extract array values
  - `json_has_key "$json" "key"` — Check key existence

### Security and Path Validation

All paths used in `cd`, file operations, or shell commands must be validated:
- Use `validate_path()` from `lib/paths.sh` to detect command injection patterns
- Use `normalize_path()` to resolve symlinks and `.` / `..` components
- Reject paths containing `$(...)`, `${...}`, backticks, semicolons, pipes, or other shell metacharacters
- Hook names and adapter names must be single segments (no slashes or path traversal)

### Hook Implementation Pattern

Each hook directory contains:
- `hook.sh` — Main hook implementation
- `README.md` — Documentation covering behavior, events, configuration, and debugging

Hooks must:
1. Read canonical JSON payload from stdin
2. Extract required fields (workspace_roots, cwd, command/tool_name)
3. Execute validation logic
4. Output exactly one line of JSON to stdout: `{"decision":"allow|deny","message":"..."}`
5. Exit with 0 for "allow", non-zero for "deny"

**Adapter interface** — Each adapter implements:
- `normalize_input "$raw_payload"` → prints canonical JSON
- `emit_output "$canonical_output"` → prints IDE-native response and sets exit code

The canonical format is always:
```json
{
  "client": "cursor|github-copilot|claude-code|windsurf|unknown",
  "event": "before_shell_execution|pre_tool_use|...",
  "type": "command|tool|...",
  "workspace_roots": ["path1", "path2"],
  "cwd": "current_working_directory",
  "command": "shell_command_string",
  "tool_name": "tool_name_or_empty_string",
  "raw_payload": {...original_agent_payload...}
}
```

### Test Structure

Tests use **Bats** (`tests/` directory mirrors `agent-hooks/` structure):
- `tests/lib/` — Unit tests for library utilities (os.sh, paths.sh, json.sh, logging.sh)
- `tests/adapters/` — Adapter parsing tests (cursor.bats, github-copilot.bats, etc.)
- `tests/hooks/` — Hook behavior tests (one .bats file per hook)
- `test_helper.bash` — Common setup that:
  - Sets `PROJECT_ROOT` for test discovery
  - Disables logging to files (`LOG_FILE=/dev/null`)
  - Provides helper functions

Test conventions:
- Each test is an isolated `@test` block with a descriptive name
- Use `setup()` and `teardown()` for test initialization/cleanup (e.g., temporary directories)
- Use `run` command to capture exit code and output: `run command "$arg"`
- Assert on both `$status` (exit code) and `$output` (stdout)
- Unset library globals at start of setup to ensure fresh state: `unset _LIB_NAME_LOADED`
- Example: `[[ $status -eq 0 ]]` and `[[ "$output" == '...' ]]`

### 1Password Database Queries

The `1password-validate-mounted-env-files` hook queries 1Password's SQLite database to check local .env file mounts:
- **macOS**: `~/Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/Data/1Password.sqlite`
- **Linux**: 
  - `~/.config/1Password/1Password.sqlite` (standard install)
  - `~/snap/1password/current/.config/1Password/1Password.sqlite` (snap)
  - `~/.var/app/com.onepassword.OnePassword/config/1Password/1Password.sqlite` (Flatpak)

Query approach:
- Use `sqlite3` command-line tool (dependency; gracefully fails open if missing)
- Parse TOML configuration at `.1password/environments.toml` for `mount_paths` array
- Validate FIFO files exist and are enabled in 1Password
- Return parsed environment variable references as `op://vault/item/field`

### Agent Configuration Files

When hooks are installed, agent-specific config files are created/updated:
- **Cursor**: `.cursor/hooks.json` — JSON with `hooks` object mapping events to command arrays
- **GitHub Copilot**: `.github/hooks/hooks.json` — Same format as Cursor
- **Claude Code**: `.claude/settings.json` — Different format with nested `hooks` > `PreToolUse` > `matcher`
- **Windsurf**: `.windsurf/hooks.json` — Similar to Cursor but with `pre_run_command` event

## For New Hooks

1. Create `hooks/<hook-name>/` directory
2. Implement `hook.sh` following the pattern above
3. Write `README.md` documenting behavior, configuration, and debugging
4. Add tests in `tests/hooks/<hook-name>.bats`
5. Update `install-client-config.json` to register the hook:
   - Add to each agent's `hook_events` object with event name and hook name
   - Specify which adapters are needed (usually `_lib.sh`, agent-specific adapter, `generic.sh`)
6. Update `install.sh` if your hook has new dependencies
7. Run `bats -r tests/` to verify all tests pass

## Repository-Level Patterns

### install-client-config.json

This JSON file defines:
- Per-agent configuration (install directories, config file paths)
- Which hook events are supported (e.g., `beforeShellExecution`, `PreToolUse`)
- Which hooks run on which events
- Which adapters each agent loads

**Event name mapping across agents:**
- Cursor: `beforeShellExecution`
- GitHub Copilot: `PreToolUse`
- Claude Code: `PreToolUse`
- Windsurf: `pre_run_command`

### install.sh Behavior

- **Bundle mode** (no `--target-dir`): Creates portable bundle in current directory
- **Bundle and Move mode** (`--target-dir`): Installs bundle to target and creates agent config from template (if missing)
- **Safety checks**: 
  - Validates agent name is known
  - Rejects unsafe paths (checks for `/../`, command injection patterns)
  - Asks before overwriting existing bundles
  - Never overwrites existing config files (preserves manual edits)

## Debugging and Development

### Logging

- Default log file: `/tmp/1password-hooks.log`
- Override log file: `LOG_FILE=/path/to/log`
- Override log tag: `LOG_TAG=custom-tag`
- Debug mode: Set `DEBUG=1` to echo logs to stderr instead of file

Example:
```bash
DEBUG=1 bash -c 'echo '\''{...}'\'' | ./bin/run-hook.sh 1password-validate-mounted-env-files'
```

### Test Execution

Suppress logging during tests by setting `LOG_FILE=/dev/null` in `test_helper.bash`.

### Manual Hook Testing

Run a hook manually to debug behavior:
```bash
echo '{"client":"cursor","workspace_roots":["/path"],...}' | bash ./bin/run-hook.sh hook-name
```

Hooks read canonical JSON on stdin and write canonical JSON (one line) to stdout.

## Common Pitfalls

- **Output format**: Hooks must output exactly one line to stdout (no extra lines or stderr)
- **Exit codes**: Exit 0 for both "allow" and "deny" decisions (the decision is in JSON, not exit code)
- **JSON parsing**: Use functions from `lib/json.sh`, not `jq` — keep it POSIX/portable
- **Adapter correctness**: Adapters must handle both raw agent payloads AND the canonical format transformation
- **Path safety**: Always validate paths before using with `cd`, `cat`, or in commands
- **Windows support**: Local .env file validation is not implemented for Windows (skip validation on Windows)
- **Command injection**: Never pass unchecked user input to `eval`, `bash -c`, or similar
- **JSON escaping**: Use `escape_json_string()` when building JSON, `extract_json_string()` when reading (handles `\"` and `\\` automatically)
- **Library loading**: Always check sourcing guards to prevent duplicate loading (e.g., `[[ -n "${_LIB_JSON_LOADED:-}" ]] && return 0`)
- **Fail-open philosophy**: If external tools (sqlite3, 1Password) fail, log and allow execution — don't block the developer
