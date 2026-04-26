# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [1.0.0] — 2026-04-26

### Added

- **3-layer language policy resolution** — merges an optional extension layer, project layer,
  and user layer into a single effective policy using a deterministic precedence algorithm.
- **8 configurable language categories** — `interactions`, `artifacts`, `documentation`,
  `code`, `code-comments`, `log-messages`, `internal-docs`, `commit-messages`.
- **`accepted_languages` enforcement** — shared file-output categories are validated against
  the project-layer-approved language list; any invalid value discards the entire layer.
- **`interactions` is unconstrained** — contributors may interact in any language outside
  `accepted_languages` without affecting shared file outputs.
- **Hardcoded defaults** — all categories default to English (`en`) when no config files
  are present; no configuration required for first use.
- **`config-template.yml`** — fully commented YAML template users copy to create any config
  layer; the extension itself ships no pre-filled config file.
- **Native YAML parser** — line-by-line PowerShell parser; no `yq` or external dependency
  required.
- **`resolve-language-policy.ps1`** — PowerShell 7 resolution script; reads the three config
  layers, merges them, and emits a structured sentinel block to stdout.
- **`resolve-language-policy.sh`** — bash scaffold reserving the extension point for a future
  feature; exits with a "not yet implemented" message.
- **5 `before_*` workflow hooks** — `before_specify`, `before_plan`, `before_tasks`,
  `before_implement`, `before_clarify` all fire `apply-language-policy.md` automatically.
- **`commands/apply-language-policy.md`** — SpecKit hook command file; invokes the resolution
  script and instructs the agent to apply the resolved policy for the session.
- **`extension.yml`** manifest — registers extension identity, SpecKit version requirement
  (`>=0.5.1`), the single command, and all five hooks.
- **`catalog-entry.json`** — copy-paste-ready entry for the SpecKit community catalog.
- **`.extensionignore`** — excludes `specs/`, `.specify/`, `.github/`, `.vscode/` from the
  installable zip.
- **Bilingual documentation (EN + FR)** — `README.md`, `docs/installation.md`,
  `docs/installation.fr.md`, `docs/configuration.md`, `docs/configuration.fr.md`,
  `docs/troubleshooting.md`, `docs/troubleshooting.fr.md`.
