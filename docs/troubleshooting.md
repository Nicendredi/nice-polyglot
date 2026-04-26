# Troubleshooting Guide — Nice Polyglot

> **French version**: [docs/troubleshooting.fr.md](troubleshooting.fr.md)

---

## Hook did not fire

**Symptom**: Running a supported SpecKit command (e.g. `/speckit.specify`) does not produce
a language policy block before the main workflow begins.

**Checks**:

1. Verify the extension is installed:

   ```bash
   specify extension list
   # Must show: ✓ Nice Polyglot (v1.0.0)
   ```

2. Verify your SpecKit version is ≥ 0.5.1:

   ```bash
   specify --version
   ```

3. Verify the hook command file exists at the expected path:

   ```bash
   ls .claude/commands/speckit.nice-polyglot.apply-language-policy.md
   ```

4. Open `extension.yml` (in the installed extension directory) and confirm the five
   `before_*` hooks are all pointing to `speckit.nice-polyglot.apply-language-policy`.

---

## All outputs are in English despite config

**Symptom**: You have a config file but SpecKit artifacts, documentation, or other outputs
are still being generated in English.

**Common causes and fixes**:

| Cause | Fix |
|---|---|
| Config file is at the wrong path | Run the script directly (see [below](#run-the-script-directly)) and check the output — if it shows all `en`, the file is not being picked up. Verify the path matches the table in [configuration.md](configuration.md). |
| YAML parse error in the config file | Look for a `WARNING: Could not read …` message in the agent response. Open the file and check for syntax errors (unterminated strings, wrong indentation, unexpected characters). |
| Language code not in `accepted_languages` | A category value outside `accepted_languages` invalidates the whole layer. Example: `artifacts: es` when `accepted_languages: [en, fr]` — the entire layer is discarded and a warning is written to stderr. |
| Uppercase language code | Codes must be two lowercase letters (e.g., `fr` not `FR`). An uppercase code fails validation and the layer is discarded. |

---

## WARNING: Could not read {path}

**Full warning**: `[nice-polyglot] WARNING: Could not read /path/to/config.yml. Using settings from lower-precedence layers.`

This warning means a config file **exists** at the given path but could not be parsed.

**How to diagnose**:

1. Open the file at `{path}` in a text editor.
2. Look for common YAML issues:
   - Lines with unexpected characters (e.g., tabs instead of spaces, stray colons)
   - Values that are not valid ISO 639-1 two-letter lowercase codes
   - `accepted_languages` codes that are not two lowercase letters
3. Run the script directly and redirect stderr to see all warnings:

   ```powershell
   pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1 2>&1
   ```

4. Fix the offending line or reset to a clean copy from `config-template.yml`.

---

## WARNING: accepted_languages ignored in user override

**Full warning**: `[nice-polyglot] WARNING: accepted_languages in user override is ignored (V-005). Set accepted_languages at the project layer instead.`

This is expected behaviour (FR-010). The `accepted_languages` field in the user layer
(`.specify/.nice-polyglot/{user}-config.yml`) is **always ignored** — only the project layer
(`.specify/overrides/nice-polyglot-config.yml`) can set the accepted languages for shared
file-output categories.

**Fix**: If you need to change `accepted_languages`, edit the project override file instead.
Note that the rest of your user layer (excluding `accepted_languages`) is still applied if
all other fields are valid.

---

## User config file is not being picked up

**Symptom**: You created a user config file but the agent still uses the project defaults.

**How to find the expected filename**:

```powershell
$email = git config user.email
$user  = ($email -replace '@', '-at-' -replace '\.', '-').ToLower()
Write-Host "Expected path: .specify/.nice-polyglot/$user-config.yml"
```

Ensure the file exists at **exactly** that path. Common mistakes:
- The file uses a different sanitisation format (e.g., using `_` instead of `-` for `.`)
- `git config user.email` returns a different address in this repository vs. the one used
  when the file was named
- The `.specify/.nice-polyglot/` directory does not exist

---

## Run the script directly

You can run the resolution script at any time to see the current effective policy and any
stderr warnings:

```powershell
# From the project root (with the extension installed)
pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1
```

To see stdout and stderr together:

```powershell
pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1 2>&1
```

**Interpreting the output**:
- Lines between `NICE_POLYGLOT_POLICY_START` and `NICE_POLYGLOT_POLICY_END` show the
  resolved policy applied to the workflow.
- Lines starting with `[nice-polyglot] WARNING:` (on stderr) show skipped layers and
  ignored fields.
- Exit code `0` = policy resolved successfully.
- Exit code `1` = fatal error (no `.specify` root found, `common.ps1` not found).
