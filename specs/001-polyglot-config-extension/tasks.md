# Implementation Tasks: Nice Polyglot — Multilingual Configuration Extension for SpecKit

**Branch**: `001-polyglot-config-extension` | **Date**: 2026-04-25  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Data Model**: [data-model.md](./data-model.md)

Tasks are listed in dependency order within each phase. Complete each phase before beginning the next.

---

## Phase 1 — Project Scaffolding

### T001 · Create repository directory structure

**Effort**: S  
**Dependencies**: none  
**Description**: Create all source directories required by the plan. The repository root doubles as the extension root; dev tooling directories (`.specify/`, `specs/`) already exist and need no action.

Directories to create:
- `commands/`
- `scripts/powershell/`
- `docs/`

**Acceptance Criteria**:
- All three directories exist at the repository root.
- No extra directories are created beyond what the plan defines.

---

### T002 · Create `extension.yml` manifest

**Effort**: S  
**Dependencies**: T001  
**Description**: Create `extension.yml` at the repository root. This is the SpecKit extension manifest that registers the extension identity, required SpecKit version, the single hook command, and the five `before_*` hook bindings.

Required content per [hook-contract.md](./contracts/hook-contract.md):

```yaml
id: nice-polyglot
name: Nice Polyglot
version: "1.0.0"
description: "Configure SpecKit agents to generate outputs and interact in chosen languages"
author: Nicendredi
license: MIT
requires:
  speckit_version: ">=0.5.1"

commands:
  - id: speckit.nice-polyglot.apply-language-policy
    file: commands/apply-language-policy.md
    description: "Resolve and apply the effective Nice Polyglot language policy for this workflow"

hooks:
  before_specify:
    command: "speckit.nice-polyglot.apply-language-policy"
    optional: false
    description: "Apply effective language policy before spec generation"
  before_plan:
    command: "speckit.nice-polyglot.apply-language-policy"
    optional: false
    description: "Apply effective language policy before implementation planning"
  before_tasks:
    command: "speckit.nice-polyglot.apply-language-policy"
    optional: false
    description: "Apply effective language policy before task generation"
  before_implement:
    command: "speckit.nice-polyglot.apply-language-policy"
    optional: false
    description: "Apply effective language policy before implementation"
  before_clarify:
    command: "speckit.nice-polyglot.apply-language-policy"
    optional: false
    description: "Apply effective language policy before spec clarification"
```

**Acceptance Criteria**:
- `extension.yml` exists at repository root.
- `specify extension validate` (or equivalent) reports no schema errors.
- All 5 hooks point to `speckit.nice-polyglot.apply-language-policy`.
- `requires.speckit_version` is `">=0.5.1"`.

---

### T003 · Create `.extensionignore`

**Effort**: S  
**Dependencies**: T001  
**Description**: Create `.extensionignore` at the repository root. This file is read by the SpecKit CLI during `specify extension add` installation. It controls which paths from the zip are not extracted to the user's `.specify/extensions/` directory. Dev tooling and spec artifacts must not be deployed to end users.

Paths to exclude:
- `specs/`
- `.specify/`
- `.github/`
- `.vscode/`
- `.extensionignore` itself (optional convention — check SpecKit docs)
- `*.zip`

**Acceptance Criteria**:
- `.extensionignore` exists at the repository root.
- After `specify extension add nice-polyglot --from ./nice-polyglot-1.0.0.zip`, the installed extension directory does not contain `specs/`, `.specify/`, `.github/`, or `.vscode/`.
- User-facing files (`extension.yml`, `commands/`, `scripts/`, `docs/`, `README.md`, `catalog-entry.json`, `config-template.yml`, `CHANGELOG.md`, `LICENSE`) are present in the installed extension directory.

---

### T004 · Create `catalog-entry.json`

**Effort**: S  
**Dependencies**: T002  
**Description**: Create `catalog-entry.json` at the repository root. This is the copy-paste-ready catalog entry for the SpecKit community catalog (FR-015). It must be valid JSON and follow the complete catalog schema v1.0 as defined in [research.md](./research.md) Decision 5.

Required fields:

| Field | Value |
|---|---|
| `id` | `nice-polyglot` |
| `name` | `Nice Polyglot` |
| `description` | `Configure SpecKit agents to generate outputs and interact in chosen languages` |
| `author` | `Nicendredi` |
| `version` | `1.0.0` |
| `license` | `MIT` |
| `requires.speckit_version` | `">=0.5.1"` |
| `provides.commands` | `1` |
| `provides.hooks` | `5` |
| `tags` | `["localization", "language", "configuration", "process"]` |
| `repository` | GitHub repository URL |
| `download_url` | GitHub release archive URL for v1.0.0 |

**Acceptance Criteria**:
- `catalog-entry.json` is valid JSON (`pwsh -c "Get-Content catalog-entry.json | ConvertFrom-Json"` succeeds).
- All required fields are present and match the values above.
- File is included in the installable zip (not excluded by `.extensionignore`).

---

## Phase 2 — Configuration Artifacts

### T005 · Create `config-template.yml`

**Effort**: S  
**Dependencies**: T001  
**Description**: Create `config-template.yml` at the repository root. Per the SpecKit extension template convention, the extension ships **only** `config-template.yml` — no pre-filled config file. The extension's built-in defaults are hardcoded in the resolution script (T007). Users copy this template to create whichever layer(s) they need:

- **Extension layer**: `.specify/extensions/nice-polyglot/nice-polyglot-config.yml` — shared across all projects in a shared SpecKit setup (`.specify/` root)
- **Project layer**: `.specify/overrides/nice-polyglot-config.yml` — per-project settings
- **User layer**: `.specify/.nice-polyglot/{user}-config.yml` — personal preferences

This approach ensures that updating the extension never overwrites a user's configuration.

All fields should be present but commented out to show the full schema while being a no-op by default.

Include comments that explain:
- The `accepted_languages` field is authoritative only at the project layer (user layer ignores it).
- `interactions` is the only category not constrained by `accepted_languages`.
- Valid codes are ISO 639-1 two-letter lowercase codes.
- Where to place the file for the extension, project, and user layers respectively.

**Acceptance Criteria**:
- File is valid YAML when uncommented.
- All 8 `language_settings` keys appear (commented out).
- `accepted_languages` appears (commented out) with a note about layer authority.
- Comments describe all three target paths (extension, project, user layers) and reference the configuration guide for full details.

---

## Phase 3 — Resolution Script

### T006 · Scaffold `resolve-language-policy.ps1` with path resolution and user identity

**Effort**: M  
**Dependencies**: T005  
**Description**: Create `scripts/powershell/resolve-language-policy.ps1` with the overall script structure, `common.ps1` integration for `.specify` root discovery, construction of all three config layer paths, and the `Get-UserIdentifier` function for deriving the `{user}` component of the user-override filename.

**`common.ps1` integration**:
- Dot-source `common.ps1` from `.specify/scripts/powershell/common.ps1` (resolved relative to `Get-RepoRoot`).
- Call `Get-RepoRoot` to get the `.specify` root.
- Exit with code `1` and write to stderr if `common.ps1` is not found or `Get-RepoRoot` fails.

**Config paths to construct** (all relative to the resolved `.specify` root per [contracts/config-schema.md § File Locations](./contracts/config-schema.md)):
```
$specifyRoot/extensions/nice-polyglot/nice-polyglot-config.yml   # extension layer (optional, user-created from config-template.yml)
$specifyRoot/overrides/nice-polyglot-config.yml                   # project layer (optional, user-created from config-template.yml)
$specifyRoot/.nice-polyglot/{user}-config.yml                     # user layer (optional, user-created from config-template.yml)
```

All three paths are optional. When no files are present, the script uses hardcoded defaults (all categories `en`, `accepted_languages: [en]`).

**`Get-UserIdentifier` function** per [data-model.md § ConfigLayer](./data-model.md):
1. Try `git config user.email` — sanitize: `@` → `-at-`, `.` → `-`, lowercase.
2. Fall back to `$env:USERNAME` (Windows), then `$env:USER` (macOS/Linux), then literal `unknown`.
3. When fallback to `unknown` is used, write a warning to stderr.

**Acceptance Criteria**:
- Script exits with code `1` and a meaningful stderr message if `.specify` root is not found.
- Running `Get-UserIdentifier` with `git config user.email = "test@example.com"` returns `test-at-example-com`.
- All three config path variables are correctly constructed using the `.specify` root.
- Script runs successfully (exit code `0`) when none of the three config files exist.

---

### T007 · Implement native PS YAML parser (`Parse-NicePolyglotConfig`)

**Effort**: M  
**Dependencies**: T006  
**Description**: Implement the `Parse-NicePolyglotConfig` function inside `resolve-language-policy.ps1`. This function parses a single YAML config file matching the extension's schema without any external dependencies (`yq`, `powershell-yaml`) per [research.md Decision 3](./research.md).

**Schema assumptions the parser can rely on** (from research.md Decision 3):
- Keys and values are unquoted or single-quoted strings.
- No nesting beyond the `language_settings:` block.
- `accepted_languages` items are prefixed with `- `.
- No YAML anchors, aliases, or complex features.

**Function signature**: `Parse-NicePolyglotConfig([string]$filePath)`  
**Returns**: A hashtable with keys `accepted_languages` (string array) and `language_settings` (hashtable of category → code), plus `schema_version` (string). Missing fields return `$null` for that key.

**Parsing rules**:
- Detect `schema_version:` line — capture the value.
- Detect `accepted_languages:` section start — collect subsequent `- value` lines until the next top-level key.
- Detect `language_settings:` section start — collect `key: value` lines as hashtable entries until EOF or next top-level key.
- Return `$null` from the function if the file cannot be read; do not throw.

**Acceptance Criteria**:
- Parses a valid all-defaults config (all 8 `language_settings` keys = `en`, `accepted_languages: [en]`) and returns the correct structure.
- Returns `$null` (no exception) when the file path does not exist.
- Returns `$null` when the file content is malformed (e.g., binary content, incomplete YAML).
- Correctly handles a `language_settings:` block with only a subset of the 8 keys present.
- `accepted_languages` list is correctly parsed when multiple codes are present.

---

### T008 · Implement config layer loader with error handling

**Effort**: M  
**Dependencies**: T006, T007  
**Description**: Implement the `Load-ConfigLayer` function inside `resolve-language-policy.ps1`. This function wraps `Parse-NicePolyglotConfig` with the error handling specified in [data-model.md § Merge Algorithm](./data-model.md) (steps 1–3c) and [contracts/config-schema.md § Error Handling](./contracts/config-schema.md).

**Function signature**: `Load-ConfigLayer([string]$path, [string]$layerName)`  
**Returns**: Parsed config hashtable, or `$null` if the file does not exist or is unreadable/malformed.

**Error handling behavior**:
- File not found → return `$null` silently (non-error — optional layer is absent).
- File exists but unreadable or `Parse-NicePolyglotConfig` returns `$null` → write warning to stderr:  
  `[nice-polyglot] WARNING: Could not read {absolute-path}. Using settings from lower-precedence layers.`  
  Then return `$null`.
- `schema_version` present but not `"1.0"` → write warning to stderr, continue with the layer content.

**Acceptance Criteria**:
- Returns `$null` without stderr output when any of the three config files is absent.
- Writes the correct stderr warning when a file exists but is unreadable/malformed.
- Does not throw; always returns either a hashtable or `$null`.

---

### T009 · Implement 3-layer merge algorithm with validation rules

**Effort**: L  
**Dependencies**: T008  
**Description**: Implement the `Merge-ConfigLayers` function inside `resolve-language-policy.ps1`. This is the core of the feature. It executes all 7 steps from [data-model.md § Merge Algorithm](./data-model.md) and enforces all 8 validation rules (V-001 through V-008).

**Function signature**: `Merge-ConfigLayers($extension, $project, $user)` where each argument is the output of `Load-ConfigLayer` (hashtable or `$null`).  
**Returns**: A hashtable representing the `EffectiveLanguagePolicy` — keys `accepted_languages` (string array), `interactions` (string), and one key per remaining category.

**Algorithm steps** (implement verbatim from data-model.md):

1. Start with hardcoded defaults (all categories `en`, `accepted_languages: @("en")`) as the initial working policy. If `$extension` is non-null, apply its values on top (replacing defaults). If the extension layer file exists but was unreadable/malformed, V-007 applies — log warning to stderr.
2. Apply project layer: replace `accepted_languages` if present and non-empty (always include `en`); merge `language_settings` keys.
3. Apply user layer: ignore `accepted_languages` if present (V-005 — log warning to stderr); merge `language_settings` keys.
4. Validate shared file-output categories against `accepted_languages` (V-003 — fallback to `en`, log each fallback).
5. Validate `interactions`: must match `/^[a-z]{2}$/` (V-004 — fallback to `en`).
6. If `accepted_languages` is empty or contains no valid codes (V-001, V-002): set to `["en"]`.
7. Return the resolved `EffectiveLanguagePolicy`.

**Shared file-output categories** (7, per [data-model.md § LanguageCategory](./data-model.md)): `artifacts`, `documentation`, `code`, `code-comments`, `log-messages`, `internal-docs`, `commit-messages`.

**ISO 639-1 validation regex**: `/^[a-z]{2}$/` per [contracts/config-schema.md § Validation Constraints](./contracts/config-schema.md).

**Acceptance Criteria**:
- No config files: hardcoded defaults apply — all categories `en`, `accepted_languages` is `["en"]`.
- Extension layer only (all `en`): same as hardcoded defaults output.
- Project sets `accepted_languages: [en, fr]` and `artifacts: fr` → `artifacts` resolves to `fr`.
- Project sets `artifacts: es` with `accepted_languages: [en, fr]` → `artifacts` falls back to `en`; fallback is logged to stderr.
- User sets `interactions: es` with project `accepted_languages: [en, fr]` → `interactions` resolves to `es` (unconstrained).
- User sets `documentation: es` with project `accepted_languages: [en, fr]` → `documentation` falls back to `en`.
- User sets `accepted_languages: [en, fr, es]` → field is ignored; stderr warning written; project's `accepted_languages` unchanged.
- Extension layer file `$null` (absent) → hardcoded defaults used; project and user layers still applied on top.
- Project layer `$null` → extension/hardcoded values retained; user layer still applied.
- `accepted_languages` containing only invalid codes → resolved to `["en"]`.

---

### T010 · Implement script output formatting

**Effort**: S  
**Dependencies**: T009  
**Description**: Implement the final output step in `resolve-language-policy.ps1`. After `Merge-ConfigLayers` returns the `EffectiveLanguagePolicy`, emit the structured sentinel block to stdout per [contracts/hook-contract.md § Script Output Contract](./contracts/hook-contract.md).

**Stdout output format**:
```
NICE_POLYGLOT_POLICY_START
accepted_languages: en,fr
interactions: fr
artifacts: fr
documentation: fr
code: en
code-comments: en
log-messages: en
internal-docs: fr
commit-messages: en
NICE_POLYGLOT_POLICY_END
```

Rules:
- `accepted_languages` is a comma-separated list of valid codes (no spaces after comma).
- One `key: value` pair per line; single space after `:`.
- No trailing whitespace; UTF-8 output.
- Emit the block on exit code `0`. Exit code `1` only on fatal errors (no `.specify` root found).

**Acceptance Criteria**:
- Running the script with no config files present produces the all-`en` hardcoded-defaults block shown in [quickstart.md § Testing the Resolution Script Directly](./quickstart.md).
- Running the script with a project override (`accepted_languages: [en, fr]`, `artifacts: fr`) produces correct `artifacts: fr` and `accepted_languages: en,fr` in the output block.
- Exit code is `0` when resolution succeeds (even with missing optional layers).
- Exit code is `1` when `common.ps1` is not found or no `.specify` root is located.
- Warnings (skipped layers, ignored fields) appear only on stderr, never in the stdout block.

---

## Phase 4 — Hook Command

### T011 · Create `commands/apply-language-policy.md`

**Effort**: M  
**Dependencies**: T002, T010  
**Description**: Create `commands/apply-language-policy.md` — the SpecKit Markdown command file that fires as the `before_*` hook for all 5 supported workflow commands. Its frontmatter declares the resolution script; its body instructs the agent to apply the resolved settings for the session. Full contract is in [contracts/hook-contract.md](./contracts/hook-contract.md).

**Frontmatter**:
```yaml
---
description: "Resolve and apply the effective Nice Polyglot language policy for this workflow"
scripts:
  ps: ../../scripts/powershell/resolve-language-policy.ps1
---
```

**Body must**:
1. Invoke the resolution script via the `{SCRIPT}` placeholder (SpecKit rewrites to the installed path).
2. Include the agent instruction block verbatim from [contracts/hook-contract.md § Required agent instruction text](./contracts/hook-contract.md).
3. Instruct the agent to surface any stderr warnings to the user as a brief note before beginning the main task.
4. Instruct the agent not to override language assignments unless the user explicitly requests a change.

**Acceptance Criteria**:
- File parses as valid Markdown with valid YAML frontmatter.
- `{SCRIPT}` placeholder appears exactly once in the body (or frontmatter reference).
- All 8 category names from the instruction text match exactly those in [data-model.md § LanguageCategory](./data-model.md).
- The agent instruction states that settings are authoritative for the session (per hook-contract.md).

---

## Phase 5 — Documentation

### T012 · Write `README.md`

**Effort**: M  
**Dependencies**: T002, T005, T011  
**Description**: Write the bilingual root `README.md`. English section first, French section second, with an anchor link between them. Per spec FR-014 and the repo constitution.

**Required English sections**:
- Extension purpose and what it does (8 categories, 3-layer config)
- Quick installation steps (zip install via `specify extension add`)
- Configuration overview (extension layer → project → user precedence, config file paths)
- Link to full docs: `docs/installation.md`, `docs/configuration.md`, `docs/troubleshooting.md`

**Required French sections** (mirrors English, translated):
- Same four sections in French
- Anchor: `#fr` (or equivalent bilingual convention)

**Acceptance Criteria**:
- English section appears before French section.
- Anchor link from English to French section is present and functional.
- Config file paths match those in [contracts/config-schema.md § File Locations](./contracts/config-schema.md) exactly.
- No implementation details that contradict the spec or data model.

---

### T013 · Write `docs/installation.md` + `docs/installation.fr.md`

**Effort**: M  
**Dependencies**: T002, T003, T004  
**Description**: Write the end-user installation guide in English and its French counterpart. Both files must be consistent in content and cover the same topics.

**Required topics (both languages)**:
- Prerequisites: SpecKit ≥ 0.5.1, PowerShell 7, Git.
- Installing from zip: `specify extension add nice-polyglot --from ./nice-polyglot-1.0.0.zip`.
- Installing from catalog: add `catalog-entry.json` content to project's `catalog.json`, then `specify extension add nice-polyglot`.
- Verifying installation: `specify extension list` shows the extension; hook command is registered.
- First-run defaults: no config needed — all categories default to English.
- Pointer to `docs/configuration.md` / `docs/configuration.fr.md` for next steps.

**Acceptance Criteria**:
- Both `.md` and `.fr.md` files exist.
- All installation commands are syntactically correct and match the quickstart guide.
- Prerequisites section lists the minimum SpecKit version (`>=0.5.1`).
- Both files cover identical topics (a bilingual reader can follow either without missing information).

---

### T014 · Write `docs/configuration.md` + `docs/configuration.fr.md`

**Effort**: M  
**Dependencies**: T005, T009  
**Description**: Write the full configuration reference in English and its French counterpart. This is the primary reference for project maintainers and individual contributors (SC-001: maintainer can configure in < 5 min using this guide).

**Required topics (both languages)**:
- The 8 language categories and what each controls.
- The 3-layer precedence model (extension layer → project → user) with file paths and who creates each layer.
- How to create a project override: copy `config-template.yml` to `.specify/overrides/nice-polyglot-config.yml`.
- How to create a user override: find your user config path (git email sanitization); place at `.specify/.nice-polyglot/{user}-config.yml`.
- `accepted_languages` behavior: who can set it, what happens with invalid codes, fallback to `en`.
- `interactions` category: unconstrained (can use any language outside `accepted_languages`).
- User override limits: cannot expand `accepted_languages`; shared file-output categories still validated against project list.
- Complete annotated example showing base, project override, and user override producing a merged effective policy.

**Acceptance Criteria**:
- Both `.md` and `.fr.md` files exist.
- The annotated example matches the scenario in [quickstart.md § Setting Up a Test Configuration](./quickstart.md) exactly.
- `accepted_languages` user-override restriction is documented (with the stderr warning behavior).
- All 8 category names match [data-model.md § LanguageCategory](./data-model.md) exactly.

---

### T015 · Write `docs/troubleshooting.md` + `docs/troubleshooting.fr.md`

**Effort**: M  
**Dependencies**: T013, T014  
**Description**: Write the troubleshooting guide in English and its French counterpart.

**Required topics (both languages)**:
- "Hook did not fire" — verify `extension.yml` hook registration; confirm SpecKit version ≥ 0.5.1.
- "All outputs are in English despite config" — common causes: config file in wrong path; YAML parse error; language code not in `accepted_languages`.
- "WARNING: Could not read {path}" — how to diagnose and fix a malformed config file.
- "WARNING: accepted_languages ignored in user override" — explanation of FR-010, how to set it at project level instead.
- "User config file is not being picked up" — how to find the expected filename (`git config user.email` derivation).
- Verification command: how to run `resolve-language-policy.ps1` directly and interpret its output.

**Acceptance Criteria**:
- Both `.md` and `.fr.md` files exist.
- Every warning message referenced in troubleshooting matches the exact format from [contracts/hook-contract.md § Warning Surface Contract](./contracts/hook-contract.md).
- "Run the script directly" section references the exact command from [quickstart.md § Testing the Resolution Script Directly](./quickstart.md).

---

### T016 · Write `CHANGELOG.md`

**Effort**: S  
**Dependencies**: T002, T005, T011, T012, T013, T014, T015  
**Description**: Write the initial `CHANGELOG.md` at the repository root for the v1.0.0 release. Use Keep a Changelog format.

**Required content**:
- `## [1.0.0] — YYYY-MM-DD` section with the release date.
- **Added** subsection listing: 3-layer language policy, 8 configurable categories, 5 workflow hooks, bilingual documentation (EN + FR), `catalog-entry.json`.
- No "Unreleased" section for the initial release.

**Acceptance Criteria**:
- File follows Keep a Changelog format.
- Version number matches `extension.yml` and `catalog-entry.json`.
- All major deliverables of this feature are mentioned.

---

## Phase 6 — Validation & Packaging

### T017 · Validate User Story 1 — Project language policy configuration

**Effort**: M  
**Dependencies**: T010, T011, T002  
**Description**: Manual validation of User Story 1 per the spec's independent test description. Create a project configuration with accepted languages and category selections, run a supported SpecKit workflow, and confirm generated outputs follow the configured policy.

**Test scenarios** (from spec User Story 1 Acceptance Scenarios):

1. No project-specific settings → run a supported workflow → outputs use English defaults.
2. Project allows EN + FR, sets `artifacts: fr` → run workflow → SpecKit artifacts produced in French.
3. Project sets a file-output category language not in `accepted_languages` → run workflow → that category falls back to English.
4. Project sets valid languages for multiple categories → run workflow → each category is independent.

**Setup**: Use a SpecKit test project with the extension installed from a local dev path (`specify extension add --dev /path/to/nice-polyglot`).

**Acceptance Criteria**:
- All 4 acceptance scenarios pass.
- Effective policy shown by `resolve-language-policy.ps1` stdout matches actual agent output language.
- No unexpected errors during workflow execution.

---

### T018 · Validate User Story 2 — Apply policy during SpecKit workflows

**Effort**: M  
**Dependencies**: T017  
**Description**: Manual validation of User Story 2. Run each supported SpecKit workflow command and verify that the `before_*` hook fires automatically and the agent's interaction language and generated artifact language match the effective configuration.

**Test scenarios** (from spec User Story 2 Acceptance Scenarios):

1. Config: `interactions: fr`, `commit-messages: en` → run workflow → user addressed in French, commit messages remain English.
2. All categories assigned valid effective languages → run each of the 5 supported workflows → every category follows its assigned language.
3. Make one config layer unreadable → run workflow → workflow completes with last valid settings; user is warned about the skipped layer.

**Acceptance Criteria**:
- Hook fires for all 5 workflows (`before_specify`, `before_plan`, `before_tasks`, `before_implement`, `before_clarify`).
- Skipped-layer warning appears in the agent's response when a layer is unreadable (SC-003).
- 100% of outputs follow the resolved effective language policy across all categories (SC-002).

---

### T019 · Validate User Story 3 — Personal override safety

**Effort**: M  
**Dependencies**: T018  
**Description**: Manual validation of User Story 3. Create a personal user override, run a supported workflow, and verify that personal interaction settings apply while shared file outputs remain within the project's accepted language list.

**Test scenarios** (from spec User Story 3 Acceptance Scenarios):

1. Project defaults interactions to EN; contributor sets personal `interactions: fr` → contributor addressed in French; shared file-output categories keep project defaults.
2. Project accepts only EN + FR; contributor sets personal `interactions: es` → contributor may be addressed in Spanish; shared file outputs unaffected.
3. Project accepts only EN + FR; contributor selects `documentation: de` in personal override → `documentation` falls back to English.
4. Contributor attempts to add `accepted_languages: [en, fr, es]` in personal override → project's `accepted_languages` unchanged; stderr warning emitted.

**Acceptance Criteria**:
- All 4 acceptance scenarios pass.
- No shared file-output category appears in a language outside the project's `accepted_languages` due to a user override (SC-004).
- `interactions` is correctly unconstrained across all test cases.

---

### T020 · Validate User Story 4 — Distribution and packaging

**Effort**: M  
**Dependencies**: T003, T004, T016  
**Description**: Manual validation of User Story 4. Build the installable zip from the repo root, install it with the SpecKit CLI (which applies `.extensionignore`), verify the installed files, simulate a catalog entry, and confirm the extension works in a clean test project.

**Test scenarios** (from spec User Story 4 Acceptance Scenarios):

1. Build zip: `zip -r nice-polyglot-1.0.0.zip .` → install with `specify extension add nice-polyglot --from ./nice-polyglot-1.0.0.zip` → inspect installed extension directory → dev-only files absent (filtered by `.extensionignore`), all user-facing files present.
2. Add `catalog-entry.json` content to a test catalog → run `specify extension add nice-polyglot` → installation succeeds; script hardcoded defaults (all English) are in effect with no config files needed.
3. Reference `catalog-entry.json` → all required catalog fields present without reformatting.

**Timing target**: Installation from zip to verified working extension in < 60 seconds on a standard developer machine with network access (SC-005).

**Acceptance Criteria**:
- Zip does not contain `specs/`, `.specify/`, `.github/`, `.vscode/`.
- Zip contains: `extension.yml`, `commands/apply-language-policy.md`, `scripts/powershell/resolve-language-policy.ps1`, `config-template.yml`, `catalog-entry.json`, `docs/` (all 6 files), `README.md`, `CHANGELOG.md`, `LICENSE`.
- `specify extension add` from the zip succeeds without errors.
- After zip install, running a supported SpecKit workflow triggers the `before_*` hook.
- SC-005: full install + verify cycle completes in < 60 seconds.

---

### T021 · Validate bilingual documentation coverage

**Effort**: S  
**Dependencies**: T012, T013, T014, T015  
**Description**: Verify that 100% of user-facing documentation introduced by this feature is available in both English and French before the feature is considered release-ready (FR-013, FR-014, SC-006).

**Checklist**:
- `README.md`: English section + French section present ✓
- `docs/installation.md` + `docs/installation.fr.md` ✓
- `docs/configuration.md` + `docs/configuration.fr.md` ✓
- `docs/troubleshooting.md` + `docs/troubleshooting.fr.md` ✓
- All 6 doc files exist and are non-empty ✓
- EN and FR counterparts cover the same topics (spot-check each pair) ✓

**Acceptance Criteria**:
- All 6 documentation files exist.
- Each EN/FR pair covers identical topics with no content gaps.
- SC-006: 100% of user-facing guidance available in both languages.

---

## Summary

| Phase | Tasks | Total Effort |
|---|---|---|
| 1 — Project Scaffolding | T001–T004 | 4 × S |
| 2 — Configuration Artifacts | T005 | 1 × S |
| 3 — Resolution Script | T006–T010 | 3 × M + 1 × L + 1 × S |
| 4 — Hook Command | T011 | 1 × M |
| 5 — Documentation | T012–T016 | 4 × M + 1 × S |
| 6 — Validation & Packaging | T017–T021 | 4 × M + 1 × S |
| **Total** | **21 tasks** | |

### Dependency Graph (critical path)

```
T001 → T002 → T004
     → T003
     → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012
                                                              ↓
T001 → T002 → T012 → T013 → T015 → T021
            → T014 ↑
                    → T016
T010 → T017 → T018 → T019
T003 → T020
T004 → T020
T016 → T020
```

### Key Interfaces

| Artifact | Defined by | Consumed by |
|---|---|---|
| Config schema (YAML) | [contracts/config-schema.md](./contracts/config-schema.md) | T005, T006, T008 |
| Merge algorithm (steps 1–7, V-001–V-008) | [data-model.md](./data-model.md) | T010 |
| Script output contract (sentinel block) | [contracts/hook-contract.md](./contracts/hook-contract.md) | T011, T012 |
| Hook registration | [contracts/hook-contract.md](./contracts/hook-contract.md) | T002, T012 |
| User identity derivation | [data-model.md](./data-model.md) | T007 |
| Config file paths | [contracts/config-schema.md](./contracts/config-schema.md) | T007, T015 |
