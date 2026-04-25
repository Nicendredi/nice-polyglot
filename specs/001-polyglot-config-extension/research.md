# Research: Nice Polyglot — Multilingual Configuration Extension

**Branch**: `001-polyglot-config-extension` | **Date**: 2026-04-25

This document resolves all NEEDS CLARIFICATION items identified during Technical Context analysis.

---

## Decision 1: Hook Injection Mechanism

**Question**: How does a `before_*` hook command pass language settings to the main workflow
command's agent context?

**Decision**: The hook command is a standard SpecKit Markdown command file. When SpecKit fires a
`before_*` hook, the agent runs that command file in the current conversation session. Instructions
and script output from the hook persist through the agent's in-context memory for the duration of
the session. The hook command (`apply-language-policy.md`) will:

1. Call `resolve-language-policy.ps1` using the `{SCRIPT}` placeholder in its frontmatter
2. Include the script's structured output (effective language settings) in-context
3. Instruct the agent explicitly to apply those language settings for all outputs in the current
   workflow — interactions, artifacts, documentation, code, code comments, logs, internal docs,
   and commit messages

The agent's understanding of "use French for artifacts" naturally persists to the subsequent main
command because both run in the same conversation context.

**Rationale**: This approach is deterministic (PS script does the merge, not the agent), testable
(the script can be run independently), and compatible with every SpecKit-supported agent that
follows command file instructions.

**Alternatives considered**:
- *Pure agent config reading*: Ask the agent to read and merge all three YAML files itself.
  Rejected because agent-side merge logic is non-deterministic and cannot be unit-tested.
- *Static injection at install time*: Bake the config into the command file at install time.
  Rejected because config changes after installation would require reinstallation.

---

## Decision 2: Config Path Convention

**Question**: Should config paths follow the SpecKit standard extension config layout
(`.specify/extensions/{ext-id}/`) or the paths specified in the feature description?

**Decision**: Follow the spec's explicitly defined paths:

| Layer | Path |
|---|---|
| Extension base (post-install) | `.specify/extensions/nice-polyglot/nice-polyglot-config.yml` |
| Project override | `.specify/overrides/nice-polyglot-config.yml` |
| User override | `.specify/.nice-polyglot/{user}-config.yml` |

All three paths are resolved at runtime via `common.ps1`'s `Get-RepoRoot` to locate the `.specify`
root, then paths are constructed relative to it.

**Rationale**: The feature description explicitly separates the project "team policy" file
(`.specify/overrides/`) from the SpecKit extension config location. This separation makes the
project-level override easy to find for team maintainers and easy to gitignore/track appropriately.
The user file is hidden (`.nice-polyglot/`) to signal it is personal and not team policy.

**Alternatives considered**:
- *Standard extension config path for all levels*: Use `.specify/extensions/nice-polyglot/` for
  all layers. Rejected because it conflates extension installation state with user/project
  configuration, and the feature description explicitly chose distinct paths.

---

## Decision 3: YAML Parsing Strategy

**Question**: How does the PowerShell resolution script parse YAML without introducing external
tool dependencies (`yq`, `powershell-yaml` module)?

**Decision**: Implement native PowerShell YAML parsing scoped to the extension's own known config
schema. The schema is a flat two-level structure: an optional `accepted_languages` sequence and an
optional `language_settings` block of key-value pairs. A line-by-line parser covering these
patterns is reliable and portable without any dependencies.

Schema-safe assumptions the parser can rely on:
- Keys and values are unquoted or single-quoted strings
- No multi-level nesting beyond `language_settings:`
- `accepted_languages` items are prefixed with `- `
- No anchors, aliases, or complex YAML features

**Rationale**: Portability on Windows (no `yq` guarantee), macOS, and Linux without requiring
module installation. The schema is under the extension author's control and will not evolve to
require full YAML support.

**Alternatives considered**:
- *Require `yq`*: Declare as a required tool in `extension.yml`. Rejected because `yq` is not
  guaranteed in all SpecKit environments, especially on Windows without package managers.
- *Require `powershell-yaml` module*: Rejected for same portability reasons; module installation
  requires elevated privileges or explicit setup in many CI/CD environments.
- *Agent reads YAML directly*: Let the agent do the merging via its native file-reading. Rejected
  (see Decision 1 — non-deterministic, untestable).

---

## Decision 4: User Identity for User-Level Config Filename

**Question**: What stable, portable identifier should be used as `{user}` in
`.specify/.nice-polyglot/{user}-config.yml`?

**Decision**: Use `git config user.email`, sanitized for use in a filename:
- Replace `@` with `-at-`
- Replace `.` with `-`
- Lowercase the result

Example: `nicol@example.com` → `nicol-at-example-com-config.yml`

**Fallback chain** (when git email is unavailable):
1. `$env:USERNAME` (Windows)
2. `$env:USER` (macOS/Linux)
3. `unknown` (last resort; logs a warning)

**Rationale**: Git email is the most portable, stable user identifier in a development environment.
It is required for any contributor making commits and is available on all platforms where SpecKit
runs. Sanitization ensures the filename is valid on all operating systems.

**Alternatives considered**:
- *`$env:USERNAME` alone*: Windows-only. Rejected for cross-platform requirement.
- *Machine hostname*: Machine-level, not user-level. Multiple users on the same machine would
  share a config file. Rejected.
- *Git username (`user.name`)*: May contain spaces and special characters, more complex to
  sanitize reliably. Email is more unique and stable. Rejected.

---

## Decision 5: `catalog-entry.json` Format

**Question**: What is the exact schema and location for the catalog entry file?

**Decision**: Create `catalog-entry.json` at the extension root following the complete SpecKit
community catalog schema (v1.0, sourced from the Extension Publishing Guide). The file is
copy-paste ready — users add the object inside `extensions: {}` to their own `catalog.json`.

Key fields:

| Field | Value |
|---|---|
| `id` | `nice-polyglot` |
| `name` | `Nice Polyglot` |
| `description` | `Configure SpecKit agents to generate outputs and interact in chosen languages` |
| `author` | `Nicendredi` |
| `version` | `1.0.0` (updated each release) |
| `download_url` | GitHub archive URL of the release tag |
| `repository` | GitHub repository URL |
| `license` | `MIT` |
| `requires.speckit_version` | `">=0.5.1"` |
| `provides.commands` | `1` |
| `provides.hooks` | count of `before_*` hooks declared in `extension.yml` |
| `tags` | `["localization", "language", "configuration", "process"]` |

The file is included in the installable zip (not excluded by `.extensionignore`).

**Rationale**: FR-015 requires catalog-ready metadata for discovery and installation. A standalone
file rather than README-embedded JSON allows copy-paste without formatting errors and can be
validated programmatically.

**Alternatives considered**:
- *README-embedded JSON block*: Harder to copy without stripping markdown syntax. Rejected.
- *Inline in `extension.yml`*: SpecKit extension manifests do not generate catalog entries
  automatically. Rejected.
