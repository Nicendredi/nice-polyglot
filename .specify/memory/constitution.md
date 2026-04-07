<!--
Sync Impact Report
Version change: unversioned template -> 1.0.0
Modified principles:
- Template Principle 1 -> I. SpecKit Compatibility First
- Template Principle 2 -> II. Deterministic Configuration Precedence
- Template Principle 3 -> III. Canonical .specify Resolution
- Template Principle 4 -> IV. Bilingual Documentation Is a Deliverable
- Template Principle 5 -> V. Catalog-Ready Release Packaging
Added sections:
- Extension Constraints
- Delivery Workflow & Quality Gates
Removed sections:
- None
Templates requiring updates:
- ✅ .specify/templates/plan-template.md
- ✅ .specify/templates/spec-template.md
- ✅ .specify/templates/tasks-template.md
- ⚠ pending .specify/templates/commands/*.md (directory not present in this scaffold)
- ✅ README.md
Follow-up TODOs:
- None
-->
# nice-polyglot Constitution

## Core Principles

### I. SpecKit Compatibility First
nice-polyglot MUST remain compatible with the SpecKit Community Extension model for
SpecKit v0.5.0 and later. Repository structure, metadata, packaging, and command behavior
MUST stay compatible with the upstream extension template unless a documented deviation is
required by SpecKit itself. Rationale: the extension is only valuable if it installs and runs
inside the supported SpecKit ecosystem without custom operator work.

### II. Deterministic Configuration Precedence
Configuration MUST resolve in this exact order, with later layers overriding earlier layers:
`nice-polyglot-config.yml` in the installed extension, `.specify/overrides/nice-polyglot-config.yml`
at project level, and `.specify/.nice-polyglot/{user}-config.yml` at user level. User-level
overrides MUST be limited to explicitly documented safe options and MUST NOT silently widen
their scope. Rationale: predictable precedence is required for reproducible agent behavior and
supportable troubleshooting.

### III. Canonical .specify Resolution
Any feature that discovers, creates, or updates content under `.specify` MUST use
`.specify/scripts/powershell/common.ps1` where that helper can provide the path or resolution
logic. Reimplementing `.specify` discovery ad hoc is prohibited unless the plan documents why
the shared helper cannot be used. Rationale: one resolution path avoids drift across commands,
shells, and operating systems.

### IV. Bilingual Documentation Is a Deliverable
User-facing documentation MUST be published in English and French. Language-specific documents
MUST be paired as `{english-name}.md` and `{english-name}.fr.md`. The root README.md MUST remain
a single file ordered as title, an anchor link to the French section using the text
`Version française plus bas`, the English section, then the French section. Changes to
configuration, language selection, or `before_{command}` hooks are incomplete until both
languages are updated. Rationale: documentation is part of the product surface for this
extension, not post-release cleanup.

### V. Catalog-Ready Release Packaging
Every releasable state MUST be distributable as a zip archive of the repository contents
intended for extension installation. `.extensionignore` MUST define installation exclusions,
and `catalog-entry.json` MUST remain accurate and copy-paste ready for SpecKit catalog
consumers. Release validation MUST confirm that the packaged archive preserves required files
and excludes development-only material. Rationale: installation depends on remote zip delivery
and fails if packaging metadata drifts.

## Extension Constraints

- The extension MUST provide configuration pathways for agent generation and agent interaction
	in the language selected by configuration.
- Configuration design MUST document override scope at each level and identify which options
	are user-overridable.
- Documentation for language configuration and `before_{command}` hooks MUST include concrete
	setup and troubleshooting guidance in both supported documentation languages.
- New features MUST preserve the extension-template conventions required by the SpecKit
	Community Extension packaging model.

## Delivery Workflow & Quality Gates

- Plans MUST include a constitution check covering SpecKit compatibility, configuration
	precedence, `.specify` resolution, bilingual documentation impact, and release packaging
	impact.
- Specifications MUST state documentation, localization, and packaging effects whenever a
	feature changes configuration behavior, user prompts, or command hooks.
- Tasks MUST include validation work for precedence rules, documentation pair updates, and
	packaging artifacts when those surfaces change.
- Reviews MUST reject changes that modify `.specify` path logic without using `common.ps1`,
	ship untranslated user-facing documentation, or leave packaging metadata inconsistent with
	the installable archive.

## Governance

This constitution overrides local workflow preferences when they conflict. Amendments MUST be
made in the same change set as any dependent template or documentation updates, and the change
MUST include an updated Sync Impact Report at the top of this file.

Versioning follows semantic versioning for governance changes: MAJOR for incompatible principle
redefinitions or removals, MINOR for new principles or materially expanded requirements, and
PATCH for clarifications that do not change repository obligations.

Compliance review is mandatory for every planning and review cycle. The Constitution Check in
the implementation plan MUST pass before design work proceeds and MUST be re-checked before
implementation begins. Any justified exception MUST be recorded in the plan's Complexity
Tracking section with the rejected simpler alternative.

**Version**: 1.0.0 | **Ratified**: 2026-04-07 | **Last Amended**: 2026-04-07
