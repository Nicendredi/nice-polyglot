# Feature Specification: Nice Polyglot — Multilingual Configuration Extension for SpecKit

**Feature Branch**: `001-polyglot-config-extension`  
**Created**: 2026-04-08  
**Status**: Draft  
**Input**: User description: Nice Polyglot SpecKit Community Extension — configure agents to generate artifacts and interact with users in chosen languages, with a three-level override hierarchy and SpecKit prompt hook integration.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Project Language Policy (Priority: P1)

A project maintainer defines which languages are acceptable for generated project files and chooses the default language for each output category so the extension consistently reflects the team's language policy.

**Why this priority**: This is the core value of the extension. Without project-level language policy, there is no reliable way to keep generated outputs aligned with team expectations.

**Independent Test**: Create a project configuration with accepted languages and category selections, run a supported SpecKit workflow, and confirm the resulting interaction and generated outputs follow the configured policy.

**Acceptance Scenarios**:

1. **Given** no project-specific settings exist, **When** a supported workflow runs, **Then** the extension uses its built-in default language policy.
2. **Given** the project allows English and French and sets artifact output to French, **When** a supported workflow runs, **Then** artifact output is directed to French.
3. **Given** the project selects a file-output language that is not accepted by the project policy, **When** a supported workflow runs, **Then** that file-output category falls back to English.
4. **Given** the project sets valid languages for multiple categories, **When** a supported workflow runs, **Then** each category follows its configured language independently.

---

### User Story 2 - Apply Language Policy During SpecKit Workflows (Priority: P2)

A user runs supported SpecKit workflows and receives interactions and generated outputs in the languages defined by the effective configuration without needing to restate language preferences each time.

**Why this priority**: Saved settings only matter if they are automatically applied during real workflows. This story turns configuration into visible behavior.

**Independent Test**: Run each supported authoring workflow and verify that user interaction language and generated output language match the effective configuration for all categories.

**Acceptance Scenarios**:

1. **Given** the effective configuration sets user interactions to French and commit messages to English, **When** a supported workflow runs, **Then** the user is addressed in French and commit messages remain in English.
2. **Given** all categories are assigned valid effective languages, **When** a supported workflow runs, **Then** every category follows its assigned language with no unintended fallback.
3. **Given** one configuration layer is unreadable or invalid, **When** a supported workflow runs, **Then** the workflow continues using the last valid settings from lower-precedence layers and the user is warned that one layer was ignored.

---

### User Story 3 - Personalize Individual Experience Safely (Priority: P3)

An individual contributor customizes their personal interaction language while still respecting the project's language policy for generated files so they can work comfortably without making shared outputs harder for the team to review.

**Why this priority**: Personal overrides improve contributor experience, but they are secondary to preserving project-readable outputs.

**Independent Test**: Create a personal override, run a supported workflow, and verify that personal interaction settings apply while shared file outputs remain limited to project-accepted languages.

**Acceptance Scenarios**:

1. **Given** the project defaults user interactions to English and a contributor sets their personal interaction language to French, **When** a supported workflow runs, **Then** the contributor is addressed in French while shared output categories keep the project defaults unless explicitly overridden with valid values.
2. **Given** the project accepts only English and French for shared files and a contributor sets their personal interaction language to Spanish, **When** a supported workflow runs, **Then** the contributor may still be addressed in Spanish because conversational language does not change shared file outputs.
3. **Given** the project accepts only English and French for shared files and a contributor selects German for a file-output category, **When** a supported workflow runs, **Then** that file-output category falls back to English.
4. **Given** a contributor attempts to broaden the project's accepted language list from their personal override, **When** a supported workflow runs, **Then** the project-level accepted language list remains authoritative.

---

### User Story 4 - Distribute the Extension Reliably (Priority: P4)

An extension maintainer packages the extension for installation through the standard SpecKit extension distribution flow so other projects can adopt it with minimal setup effort.

**Why this priority**: The feature is only useful outside this repository if it can be installed and cataloged in the expected extension format.

**Independent Test**: Build the installable package, add it to a test catalog entry, install it into a test project, and confirm the extension's configuration capability is available after installation.

**Acceptance Scenarios**:

1. **Given** the extension is ready for release, **When** the installable archive is produced, **Then** it contains the files needed for end users and excludes development-only material.
2. **Given** a user adds the extension's catalog entry to their extension catalog, **When** they install the extension, **Then** installation succeeds and the base language policy is available.
3. **Given** release metadata is published with the extension, **When** a catalog maintainer references it, **Then** they can list the extension without reformatting the provided metadata.

---

### Edge Cases

- What happens when the accepted language list is empty, missing, or contains only unrecognized values? → Shared file-output categories fall back to English.
- What happens when conversational language is set to a language outside the accepted list? → The user may still be addressed in that language because conversational output does not govern shared project files.
- What happens when a personal override file is present but unreadable? → That override is ignored, the previous valid layer remains in effect, and the workflow continues with a warning.
- What happens when multiple layers define different valid values for the same category? → The most specific valid layer wins.
- What happens when a supported workflow has no category-specific override for one output type? → That category uses the next available valid value in precedence order, or English if none is valid.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The extension MUST provide a built-in base language policy that defines the accepted languages for shared file outputs and the default language for each supported category. This built-in policy consists of hardcoded defaults in the resolution script (all categories `en`, `accepted_languages: [en]`), which are distinct from the optional extension-layer configuration file (`.specify/extensions/nice-polyglot/nice-polyglot-config.yml`) that users may create to establish shared defaults across multiple projects in a shared `.specify/` root.
- **FR-002**: The extension MUST allow a project-level configuration source to override the built-in base language policy.
- **FR-003**: The extension MUST allow a user-level configuration source to override allowed personal settings without changing project authority over accepted shared-file languages.
- **FR-004**: Effective settings MUST resolve in this precedence order: built-in base policy (hardcoded script defaults — not a file-based layer), then extension-layer overrides, then project-level overrides, then user-level overrides.
- **FR-005**: The extension MUST support independent language settings for these categories: user interactions, SpecKit artifacts, user-facing documentation, generated code, code comments, log messages, internal documentation, and commit messages.
- **FR-006**: The project configuration MUST define an accepted language list for shared file outputs. Any shared file-output category whose configured language is missing or not accepted MUST resolve to English.
- **FR-007**: English MUST always remain available as the fallback language for every category.
- **FR-008**: Conversational language used for agent interaction with the user MUST be configurable independently from shared file-output languages and MAY use a language outside the accepted language list.
- **FR-009**: User-level overrides for shared file-output categories MUST still honor the project's accepted language list.
- **FR-010**: User-level configuration MUST NOT be able to expand or replace the project's accepted language list. If a user layer includes an `accepted_languages` field, the extension MUST ignore it and MUST log a warning to stderr of the resolution script.
- **FR-011**: If a configuration layer is malformed or unreadable as a whole, the extension MUST ignore that entire layer, retain the previous valid settings from lower-precedence layers, log a warning to stderr of the resolution script, and allow the workflow to continue. If the base layer specifically is missing or unreadable, all categories MUST default to `en` and `accepted_languages` MUST default to `[en]`; project and user layers are then applied on top as normal. A layer is considered invalid if any present field contains an invalid value (an unrecognized language code, or a shared file-output category value not in the resolved `accepted_languages`). If any field is invalid, the entire layer is discarded — no fields from that layer are applied — and the workflow continues using settings from lower-precedence layers. A field that is absent from a layer is not considered invalid; absent fields simply contribute no override for their keys and do not affect the validity of the layer.
- **FR-012**: Supported SpecKit authoring workflows MUST automatically apply the effective language settings before user interaction or content generation begins. The five supported workflows are: `before_specify`, `before_plan`, `before_tasks`, `before_implement`, and `before_clarify`.
- **FR-013**: The extension MUST provide user-facing documentation that explains installation, configuration precedence, accepted-language behavior, personal override limits, and troubleshooting.
- **FR-014**: User-facing documentation for this feature MUST be maintained in both English and French.
- **FR-015**: The extension MUST be distributable through the standard installable archive flow and MUST include catalog-ready metadata for discovery and installation.
- **FR-016**: The installable package MUST exclude development-only material that is not required by extension users.

### Documentation & Delivery Impact *(mandatory when applicable)*

- **Docs Impact**: The feature requires installation guidance, a configuration reference, override-precedence guidance, accepted-language examples, and troubleshooting guidance. Each user-facing topic must be maintained as an English/French document pair.
- **README Impact**: The root `README.md` must describe the extension purpose, installation flow, and configuration model while preserving the existing English-first, French-second bilingual layout defined by the constitution.
- **Packaging Impact**: Packaging rules and catalog metadata are part of the feature scope because users install the extension from a packaged archive rather than from the repository source tree.
- **Hook Impact**: Any supported workflow stage that applies language guidance must be documented clearly enough that users understand when the extension influences interactions and generated outputs.

### Key Entities *(include if feature involves data)*

- **Language Policy**: The effective set of language choices in force for a given project and user. Attributes include the accepted shared-file languages and the resolved language for each category.
- **Language Category**: A configurable output or interaction type whose language can be set independently. Categories include one conversational category and seven shared file-output categories.
- **Override Source**: A configuration layer that contributes settings to the effective language policy. Types are base, extension, project, and user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A project maintainer can define or update the project language policy for all categories in under 5 minutes using only the documented configuration guidance.
- **SC-002**: In validation scenarios covering every supported workflow and category, 100% of generated outputs follow the resolved effective language policy.
- **SC-003**: In validation scenarios with invalid or unreadable higher-precedence configuration, supported workflows still complete successfully while preserving the last valid effective settings.
- **SC-004**: In validation scenarios with personal overrides, contributors can use a preferred conversational language without causing shared file outputs to appear in languages outside the project's accepted list.
- **SC-005**: A new user can install the packaged extension from catalog metadata into a test project in under 60 seconds on a standard developer machine with network access.
- **SC-006**: 100% of user-facing guidance introduced by this feature is available in both English and French before the feature is considered ready for release.

## Assumptions

- Language selections use ISO 639-1 two-letter codes (e.g., `en`, `fr`, `es`, `pt`, `de`, `fi`, `hi`). Any value that is not a valid ISO 639-1 two-letter lowercase code is treated as an invalid selection and falls back to `en`.
- Supported workflows are the SpecKit authoring workflows that currently allow this extension to apply language guidance. Workflows without that integration point are out of scope for this feature version.
- Personal overrides may tailor conversational behavior and category selections, but project maintainers remain authoritative for the list of languages allowed in shared generated files.
- The environment can determine a stable local user identity for locating a person's override settings.
- Release versioning strategy is out of scope; only installable packaging and catalog readiness are in scope for this specification.
