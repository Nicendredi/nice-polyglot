# Feature Specification: Nice Polyglot — Multilingual Configuration Extension for SpecKit

**Feature Branch**: `001-polyglot-config-extension`  
**Created**: 2026-04-08  
**Status**: Draft  
**Input**: User description: Nice Polyglot SpecKit Community Extension — configure agents to generate artifacts and interact with users in chosen languages, with a three-level override hierarchy and SpecKit prompt hook integration.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Project Language Settings (Priority: P1)

A project maintainer installs the nice-polyglot extension and sets the accepted languages and per-category language preferences for their project. This is the core value of the extension: ensuring every agent output respects the project's linguistic conventions.

**Why this priority**: Without this story there is no working extension. All other stories depend on settings being expressible at the project level.

**Independent Test**: Can be fully tested by creating a `.specify/overrides/nice-polyglot-config.yml` with a set of accepted languages and category overrides, then running any SpecKit command and verifying the agent prompt contains the correct language directive.

**Acceptance Scenarios**:

1. **Given** no override file exists, **When** a SpecKit command runs, **Then** the agent receives the extension-level defaults (English for all categories).
2. **Given** a project-level override file sets `accepted_languages: [en, fr]` and `artifacts: fr`, **When** a SpecKit command runs, **Then** the agent prompt instructs it to produce SpecKit artifacts in French.
3. **Given** a project-level override sets `code: es` but `accepted_languages` does not include `es`, **When** a SpecKit command runs, **Then** the agent prompt instructs it to produce code in English (fallback).
4. **Given** a project-level override sets a category to a language present in `accepted_languages`, **When** a SpecKit command runs, **Then** the agent prompt uses that language for the corresponding category.

---

### User Story 2 - Language-Aware Agent Interactions via Prompt Hooks (Priority: P2)

An agent processes a SpecKit command and, before executing it, is directed by a hook-invoked language directive command to produce output in the configured languages for each category.

**Why this priority**: The prompt hook integration is the mechanism that makes the configuration effective. Without it, settings exist but have no effect on agent behaviour.

**Independent Test**: Can be fully tested by verifying that the extension's language directive command fires at the registered hook events (`before_specify`, `before_plan`, `before_tasks`, `before_implement`) and that its content contains all eight language directives derived from the merged configuration.

**Acceptance Scenarios**:

1. **Given** merged configuration sets `conversations: fr` and `commits: en`, **When** the agent starts a SpecKit `specify` or `plan` workflow, **Then** the hook invokes the language directive command, whose Markdown content instructs the agent to interact with the user in French and write commit messages in English.
2. **Given** all categories are set to valid accepted languages, **When** a hooked SpecKit command fires, **Then** the language directive command content contains exactly eight language directives (one per category).
3. **Given** the configuration is malformed or missing a category, **When** a hook fires, **Then** the language directive command defaults the missing category to English without error; if a config file is malformed (invalid YAML), a warning is surfaced to the user and that file's values are skipped in favour of the previous override level.

---

### User Story 3 - Personal Language Override for a Developer (Priority: P3)

An individual developer wants to personalise the language settings for their own SpecKit experience. They create a user-level config file that can override any of the eight language categories. For the `conversations` category they may use any language they choose; for file-output categories they must pick a language from the project's `accepted_languages` list, ensuring generated files remain readable by all project maintainers. They cannot change the `accepted_languages` list itself.

**Why this priority**: User-level overrides allow contributors to work in their preferred language while the project enforces readable file output. They rely on P1 and P2 being in place.

**Independent Test**: Can be fully tested by creating `.specify/.nice-polyglot/{user}-config.yml` with a mix of category overrides, running a SpecKit command, and verifying the agent uses each specified language while silently falling back to English for any category whose specified language is not in `accepted_languages`.

**Acceptance Scenarios**:

1. **Given** project sets `conversations: en` and user override sets `conversations: fr`, **When** a SpecKit command runs, **Then** the agent interacts with the user in French while all file-output categories retain their project-level values.
2. **Given** the project's `accepted_languages` is `[en, fr]` and the user override sets `conversations: es`, **When** a SpecKit command runs, **Then** the agent converses with the user in Spanish — confirming that `conversations` is exempt from `accepted_languages` and has no effect on generated file output.
3. **Given** the project's `accepted_languages` is `[en, fr]` and the user override sets `code: fr` and `commits: de`, **When** a SpecKit command runs, **Then** generated code is in French (a valid accepted language) and commit messages fall back to English (German is not accepted), while all other categories retain project settings.
4. **Given** a user override sets `accepted_languages: [en, fr, de]`, **When** a SpecKit command runs, **Then** the `accepted_languages` change is silently ignored; the project-level list remains authoritative.

---

### User Story 4 - Package and Distribute the Extension (Priority: P4)

An extension maintainer produces a releasable zip archive of the extension that end users can add to their SpecKit extension catalog via URL.

**Why this priority**: Distribution via zip and catalog is the only supported install path for SpecKit community extensions; without this story the extension cannot be used by external projects.

**Independent Test**: Can be fully tested by generating the zip, adding its URL to a test SpecKit catalog, running `specify install`, and confirming the extension files are present and functional in the target project's `.specify` folder.

**Acceptance Scenarios**:

1. **Given** the extension repository is ready for release, **When** the zip is built, **Then** it contains only distributable files (dev artifacts excluded per `.extensionignore`).
2. **Given** a user adds the zip URL to their SpecKit catalog, **When** they run the install command, **Then** the extension is installed without errors and the base configuration file is present.
3. **Given** a `catalog-entry.json` file exists in the repo, **When** a catalog maintainer wants to list the extension, **Then** they can copy the JSON entry directly without reformatting.

---

### Edge Cases

- What happens when `accepted_languages` is empty or contains only unrecognized codes? → All file-output category settings default to English.
- What happens when `conversations` is set to a language not in `accepted_languages`? → The agent converses in that language anyway; `conversations` is a personal, conversational setting and is explicitly exempt from the `accepted_languages` constraint because it produces no file output.
- What happens when a user sets a file-output category to a language not in `accepted_languages`? → That category silently falls back to English; the rest of the user's overrides remain in effect.
- What happens when a user override file includes an `accepted_languages` key? → It is silently ignored; only extension-level and project-level files may define `accepted_languages`.
- What happens when a user-level config file exists but the user identifier in the filename does not match the current OS user? → The file is not applied; it has no effect.
- What happens when two override levels define the same category with different valid languages? → The most specific level (user > project > extension) wins.
- What happens when a new SpecKit command is introduced that has no corresponding hook entry in the extension? → That command runs without language injection; output defaults to the agent's own defaults. The SpecKit v0.5.0 hook events that nice-polyglot registers against are: `before_specify`, `after_specify`, `before_plan`, `after_plan`, `before_tasks`, `after_tasks`, `before_implement`, `after_implement`. The `before_commit`/`after_commit` events are defined in the API but not yet wired into core templates at v0.5.0. SpecKit commands with no hook event (`clarify`, `analyze`, `checklist`, `constitution`, `taskstoissues`) will not receive language directives.
- What happens when the `.extensionignore` excludes a required runtime file? → The extension fails gracefully and logs a meaningful error.
- What happens when a config file exists but cannot be parsed (invalid YAML, wrong value types)? → A warning is surfaced to the user identifying the file and the parse issue; that file is skipped entirely and the previous override level's values are used. The SpecKit command continues normally.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The extension MUST ship a base configuration file (`nice-polyglot-config.yml`) co-located with the extension files, defining default values for `accepted_languages` and all eight output categories.
- **FR-002**: The extension MUST support a project-level override file at `.specify/overrides/nice-polyglot-config.yml` that fully overrides matching settings from the base configuration.
- **FR-003**: The extension MUST support a user-level override file at `.specify/.nice-polyglot/{user}-config.yml` that may override any of the eight language categories, with the following rules:
  - The `{user}` identifier is derived by slugifying the git username of the current user. If git is not available or no git username is configured, the OS username is used as the fallback identifier.
  - The `conversations` category is conversational only and is NOT subject to the `accepted_languages` constraint; any language may be used.
  - All file-output categories set at user level MUST be validated against `accepted_languages`; any value not in the list MUST silently resolve to English.
  - The `accepted_languages` list MUST NOT be settable at user level; any `accepted_languages` key present in a user-level file MUST be silently ignored.
- **FR-004**: Configuration merging MUST follow the precedence order: extension base → project override → user override, with each level fully replacing any matching key from the previous level.
- **FR-005**: The configuration MUST include an `accepted_languages` list; any **file-output** category (all categories except `conversations`) whose value is absent or not present in `accepted_languages` MUST silently resolve to English. The `conversations` category is exempt from this constraint and MAY be set to any language the user chooses.
- **FR-006**: English MUST always be treated as an implicitly accepted language and MUST be the canonical fallback for all categories.
- **FR-007**: Configuration MUST support independently setting the language for each of the following eight categories. The first is a **conversational category**; the remaining seven are **file-output categories** and MUST be validated against `accepted_languages`:
  - **Conversational**: agent interactions with the user (`conversations`) — affects only the agent's spoken/written responses to the user; produces no file output and is not constrained by `accepted_languages`.
  - **File-output**: SpecKit artifacts (`artifacts`), user-facing documentation (`user_docs`), generated code (`code`), code comments (`code_comments`), log messages (`logs`), internal documentation (`docs`), commit messages (`commits`) — all values must be present in `accepted_languages` or fall back to English.
- **FR-008**: The extension MUST deliver the merged language configuration to the agent by registering hook commands at the SpecKit v0.5.0 lifecycle hook events: `before_specify`, `after_specify`, `before_plan`, `after_plan`, `before_tasks`, `after_tasks`, `before_implement`, `after_implement`. Each hook invokes a dedicated extension command (a `.md` file) whose content, read by the agent, contains the language directives. The `before_commit`/`after_commit` events SHOULD also be registered when they become available in a future SpecKit version. SpecKit commands that have no hook event (`clarify`, `analyze`, `checklist`, `constitution`, `taskstoissues`) are out of scope for language injection at v0.5.0.
- **FR-009**: The language directive command file invoked by each hook MUST contain a natural-language Markdown instruction block with one directive per category (eight total), even when a category falls back to English. The instruction block MUST be written in the format of a standard SpecKit command `.md` file so that the agent processes it as an instruction.
- **FR-010**: A dedicated PowerShell helper script MUST handle the full config lifecycle: discovering all three override files (extension base, project override, user override), merging them in precedence order, validating each language code and `accepted_languages` membership, and resolving all eight category values. The language directive command `.md` file MUST invoke this script via the `scripts: ps:` frontmatter field, then use the resolved values to render the eight language directives into the Markdown body.
- **FR-011**: If any config file cannot be parsed (invalid YAML or unexpected value types), the PowerShell helper script MUST surface a warning to the user identifying the problematic file and skip that file's values, falling back to the previous override level. The SpecKit command MUST continue normally.
- **FR-012**: `.specify` path resolution within extension scripts MUST use the shared `.specify\scripts\powershell\common.ps1` utility wherever that utility provides the required functionality.
- **FR-013**: The extension file and folder layout MUST conform to the SpecKit extensions template structure; a `scripts` folder for PowerShell scripts MAY be added as an extension-specific addition.
- **FR-014**: The release artifact MUST be a zip archive; a `.extensionignore` file MUST govern which files and folders are excluded from the archive (mirroring `.gitignore` semantics).
- **FR-015**: The repository MUST include a `catalog-entry.json` file containing the metadata required for listing the extension in a SpecKit extension catalog.

### Documentation & Delivery Impact *(mandatory when applicable)*

- **Docs Impact**: The extension requires a user-facing guide covering installation, configuration reference (all three override levels, all eight categories, `accepted_languages`), and examples. This guide MUST be provided as an English file and a French file (e.g., `docs/configuration.md` and `docs/configuration.fr.md`). A quick-start section in English and French is also required.
- **README Impact**: The root `README.md` MUST describe the extension's purpose, installation steps, and configuration overview. The bilingual layout (English section first, French section second) MUST be maintained as per project convention.
- **Packaging Impact**: `.extensionignore` and `catalog-entry.json` are core deliverables of this feature. The zip-based installation workflow depends on both files being present and correct. Any change to the distributable file set requires updating `.extensionignore`.
- **Hook Impact**: All SpecKit hook events registered by the extension MUST be documented in the configuration reference (event names, trigger points, and the command they invoke). The language directive command file and its backing PowerShell merge script MUST be documented, including the resolved output format (one language directive per category). Any category value read from a config file MUST be validated against `accepted_languages` inside the PowerShell script before it reaches the directive command.

### Key Entities *(include if feature involves data)*

- **Language Configuration**: The merged result of all three override levels for a given user and project. Key attributes: one value per category (resolved language code) and the effective `accepted_languages` list.
- **Language Category**: A named type whose language can be configured independently. There are eight categories split into two kinds:
  - **Conversational** (`conversations`): governs the language the agent uses when communicating with the user. Produces no file output and is not subject to the `accepted_languages` constraint. May be set to any language, allowing contributors to interact in their own language regardless of the project's accepted languages.
  - **File-output** (`artifacts`, `user_docs`, `code`, `code_comments`, `logs`, `docs`, `commits`): govern the language of every file the agent generates. All seven must resolve to a language in `accepted_languages` so that project maintainers can read the generated files. This constraint applies at every override level, including user-level overrides.
- **Accepted Languages List**: An allow-list of language codes definable only at extension or project level. Controls which values are valid for all file-output categories at every override level; defaults to English when a requested language is absent. Users cannot modify this list.
- **Override File**: A YAML configuration file at extension, project, or user level. Each file can define any subset of settings; only defined keys participate in the merge.
- **Prompt Hook**: A SpecKit extension mechanism that triggers at lifecycle events (`before_specify`, `after_specify`, `before_plan`, `after_plan`, `before_tasks`, `after_tasks`, `before_implement`, `after_implement`) and invokes a dedicated extension command. The language directive command `.md` file calls a PowerShell merge script (via `scripts: ps:` frontmatter) which discovers, merges, validates, and resolves the three override levels into eight language directives, then renders them as a natural-language Markdown instruction block for the agent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A project maintainer can configure all eight language categories by editing a single YAML file, completing the task in under 5 minutes with no tooling beyond a text editor.
- **SC-002**: Every SpecKit command that has a registered hook produces agent output entirely in the configured language for each respective category, with no English bleed-through when a valid non-English language is configured.
- **SC-003**: Any invalid or missing language setting is silently resolved to English; no error or warning is presented to the user and the SpecKit workflow completes normally.
- **SC-004**: When settings are defined at multiple override levels, the most specific level consistently wins; the resolution is deterministic and reproducible across runs.
- **SC-005**: The extension zip package installs successfully into a SpecKit project via a catalog URL in under 60 seconds on a standard developer machine with internet access.
- **SC-006**: All user-facing extension documentation is available in both English and French, covering at minimum installation and the complete configuration reference.

## Assumptions

- Language codes MUST be two-letter ISO 639-1 tags (e.g., `en`, `fr`, `es`, `de`). Codes are treated case-insensitively. Extended tags (e.g., `fr-CA`, `zh-Hant`) and codes longer than two letters are treated as unrecognised and resolved to English.
- The user identifier used in the user-level config filename (`.specify/.nice-polyglot/{user}-config.yml`) is derived by slugifying the git username of the current user (e.g., `Jane Doe` → `jane-doe`). If git is not available or no git username is configured, the OS username is used as the fallback.
- User-level overrides may cover any of the eight language categories, but users cannot change `accepted_languages`. This boundary ensures that individual contributors can personalise their experience (including choosing any language for `conversations`) while the project retains full control over which languages are acceptable in generated files. Any file-output category set by a user to a language outside `accepted_languages` silently falls back to English.
- English (`en`) is always an implicitly accepted language regardless of the `accepted_languages` list content, as it is the universal fallback.
- The primary agent platform targeted is GitHub Copilot; the extension does not need to handle agent-specific command syntax for other platforms in v1.
- SpecKit v0.5.0 or later is already installed in any project that installs this extension.
- The SpecKit extensions template structure is taken as the authoritative scaffold; additional folders (e.g., `scripts`) are additive and do not conflict with template-defined paths.
- Release cadence and versioning strategy are out of scope for this specification; only the packaging mechanism (zip + `.extensionignore` + `catalog-entry.json`) is in scope.

## Clarifications

### Session 2026-04-08

- Q: Which SpecKit commands does the extension register prompt hooks for? → A: Corrected per API reference — hooks are tied to lifecycle events, not commands. The extension registers against `before_specify`, `after_specify`, `before_plan`, `after_plan`, `before_tasks`, `after_tasks`, `before_implement`, `after_implement`. Commands with no hook event (`clarify`, `analyze`, `checklist`, `constitution`, `taskstoissues`) do not receive language injection at v0.5.0.
- Q: How should a malformed or unreadable config file be handled? → A: Log a warning to the user identifying the file, skip that file's values, fall back to the previous override level, and continue the SpecKit command normally.
- Q: What is the expected format for language codes? → A: Two-letter ISO 639-1 only (e.g., `en`, `fr`), case-insensitive; extended tags and codes longer than two letters are treated as unrecognised and fall back to English.
- Q: How should config files be read and merged to surface language directives to the agent? → A: A dedicated PowerShell helper script handles discovery, merging, validation, and resolution of all three config levels; the hook command `.md` file invokes this script via the `scripts: ps:` frontmatter field and uses its output to render the eight language directives into the Markdown body.
- Q: What form does the language directive take inside the hook command file? → A: A natural-language Markdown instruction block (one sentence per category) inside a standard SpecKit command `.md` file — consistent with how all SpecKit command files are authored and consumed by the agent.
