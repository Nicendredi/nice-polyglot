# Implementation Plan: Nice Polyglot — Multilingual Configuration Extension for SpecKit

**Branch**: `001-polyglot-config-extension` | **Date**: 2026-04-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-polyglot-config-extension/spec.md`

## Summary

Nice Polyglot is a SpecKit Community Extension (v0.5.1+) that adds three-level YAML language
configuration to SpecKit workflows. A PowerShell resolution script merges an optional extension
layer config (`.specify/extensions/nice-polyglot/nice-polyglot-config.yml`, user-created),
`.specify/overrides/nice-polyglot-config.yml` (project), and
`.specify/.nice-polyglot/{user}-config.yml` (user) to produce effective per-category language
settings. All three layers are optional; the script hardcodes defaults (all `en`) when no files are
present. Per the SpecKit extension template, only `config-template.yml` is distributed with the
extension — no pre-filled config file is shipped, so extension updates never overwrite user config.
The effective settings are injected into supported SpecKit workflows via `before_*` prompt
hooks — Markdown command files that read the resolved config and instruct the agent on which language
to use for each of 8 output categories before each workflow begins.

## Technical Context

**Language/Version**: PowerShell 7 (pwsh) for config resolution scripts; YAML for config files;
Markdown + YAML frontmatter for agent hook command files  
**Primary Dependencies**: SpecKit v0.5.1+; `common.ps1` for `.specify` root discovery  
**Storage**: YAML files at three levels (no database or external storage)  
**Testing**: Manual validation of each user story per the spec's independent test descriptions  
**Target Platform**: Any SpecKit-supported platform (Windows, macOS, Linux); PowerShell 7 required  
**Project Type**: SpecKit Community Extension (agent commands + hooks + YAML config)  
**Performance Goals**: N/A — config resolution is synchronous with no throughput constraints  
**Constraints**: `.specify` path resolution must use `common.ps1`; distribution zip is the full repo root (`Compress-Archive`); `.extensionignore` is applied by the SpecKit CLI at install time (`specify extension add`);
bilingual EN+FR user-facing documentation required; no `yq` dependency assumed (native PS parsing)  
**Scale/Scope**: 1 extension, 8 language categories, 3 config levels, `before_*` hooks for all
supported SpecKit workflow commands

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- ✅ **SpecKit compatibility**: Standard `extension.yml` + `commands/` + `hooks` manifest pattern
  used; `requires: speckit_version: ">=0.5.1"`. No deviations from the Community Extension model.
- ✅ **Configuration precedence**: Three levels defined in explicit order — extension layer
  (`.specify/extensions/nice-polyglot/nice-polyglot-config.yml`, user-created from `config-template.yml`) → project override
  (`.specify/overrides/nice-polyglot-config.yml`) → user override
  (`.specify/.nice-polyglot/{user}-config.yml`). All layers are optional; script hardcodes defaults
  (all English) when none are present. User-level scope restrictions documented in
  data model (cannot expand `accepted_languages`; shared file-output categories validated against it).
- ✅ **Canonical `.specify` resolution**: The config resolution script (`resolve-language-policy.ps1`)
  calls `common.ps1`'s `Get-RepoRoot` to locate all three config paths. No ad-hoc `.specify`
  discovery elsewhere.
- ✅ **Bilingual documentation**: FR-013 and FR-014 in spec require EN+FR doc pairs. All user-facing
  topics (`installation`, `configuration`, `troubleshooting`) will have `.md` + `.fr.md` pairs.
  `README.md` follows constitution's bilingual layout (EN first, FR second, anchor link).
- ✅ **Catalog-ready packaging**: FR-015 and FR-016 mandate `.extensionignore` (applied by `specify extension add` at install time to exclude `specs/`, `.specify/`, `.github/`, `.vscode/`) and `catalog-entry.json` (copy-paste ready, full schema). The distribution zip is the full repo root. Zip-install validation included in User Story 4 acceptance scenarios.

**GATE RESULT**: All five constitution checks pass. No violations to justify in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-polyglot-config-extension/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── config-schema.md # Phase 1 output (/speckit.plan command)
│   └── hook-contract.md # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command — NOT created by /speckit.plan)

README.md                # Bilingual root overview: title, FR anchor, English section, French section
docs/
├── installation.md      # EN installation guide
├── installation.fr.md   # FR counterpart
├── configuration.md     # EN configuration reference
├── configuration.fr.md  # FR counterpart
├── troubleshooting.md   # EN troubleshooting guide
└── troubleshooting.fr.md # FR counterpart
```

### Source Code (repository root)

```text
extension.yml                   # Extension manifest (id, hooks, commands, config)
config-template.yml             # Template for all three config layers (extension, project, user)
catalog-entry.json              # Copy-paste ready catalog entry for SpecKit community catalog
.extensionignore                # Dev-only exclusion list, applied by SpecKit CLI at install time
CHANGELOG.md
LICENSE
README.md                       # Bilingual overview

commands/
└── apply-language-policy.md   # Hook command: resolves config + instructs agent

scripts/
└── powershell/
    └── resolve-language-policy.ps1  # Merges 3 config layers → effective language policy

docs/
├── installation.md
├── installation.fr.md
├── configuration.md
├── configuration.fr.md
├── troubleshooting.md
└── troubleshooting.fr.md

.specify/                       # SpecKit dev tooling (excluded at install time via .extensionignore)
specs/                          # SpecKit spec artifacts (excluded from zip)
.github/                        # CI and GitHub Copilot config (excluded from zip)
```

**Structure Decision**: Extension root doubles as the repository root. User-facing extension files
(commands, scripts, docs, manifests) live at the root level. Dev tooling (`.specify/`, `specs/`,
`.github/`) lives alongside them and is excluded from the installable zip via `.extensionignore`.

## Complexity Tracking

> No constitution violations — section intentionally empty.
