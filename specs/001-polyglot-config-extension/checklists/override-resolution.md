# Override Resolution Requirements Checklist

**Purpose**: Validate that requirements governing the 3-layer merge, fallback logic, and `accepted_languages` enforcement are complete, clear, and consistent — before tasks are generated  
**Created**: 2026-04-25  
**Feature**: [spec.md](../spec.md) | **Focus**: Override resolution correctness  
**Audience**: Author self-check  
**Scope**: FR-004, FR-006–FR-011; data-model merge algorithm; config-schema validation constraints

---

## Requirement Completeness

- [x] **CHK001**: Is the behavior specified when the **extension base config layer** file is missing or unreadable at runtime? [Completeness, Gap]  
  > **RESOLVED 2026-04-25**: Base layer missing/unreadable → hardcoded defaults (all categories `en`, `accepted_languages: [en]`); log warning to stderr; project and user layers applied normally on top. FR-011 updated; data-model.md step 1 and V-007 updated.

- [x] **CHK002**: Is the behavior defined when a user override file **exists but contains zero `language_settings` keys** (e.g., an empty `language_settings:` block or an empty file)? [Completeness, Edge Case]  
  > **RESOLVED 2026-04-25**: An absent or empty `language_settings` block contributes no overrides; working policy is unchanged for those keys. data-model.md steps 2b/3b and V-008 updated.

- [x] **CHK003**: Is there a requirement covering what happens when a user layer **sets `accepted_languages`** to a non-empty list — specifically whether this triggers a warning or is silently ignored? [Completeness, FR-010]  
  > **RESOLVED 2026-04-25**: Non-silent — ignored and logged to stderr. FR-010 updated; data-model.md step 3a and V-005 updated.

---

## Requirement Clarity

- [x] **CHK004**: Is **partial field-level invalidity** in a config layer distinguished from whole-file malformation? [Clarity, Ambiguity]  
  > **RESOLVED 2026-04-25**: Whole-file granularity adopted. FR-011 updated to: a malformed or unreadable layer is skipped entirely; field-level partial invalidity deferred to a future feature. data-model.md merge steps 2c/3c are authoritative. [Spec §FR-011]

- [x] **CHK005**: Is the **warning output format and channel** defined for malformed or unreadable config layers? [Clarity, FR-011]  
  > **RESOLVED 2026-04-25**: All warnings written to stderr of the resolution script. FR-010, FR-011 updated; data-model.md step 1, step 3a, V-005, V-006, V-007 all specify stderr explicitly.

- [x] **CHK006**: Is the **`{user}` identifier fallback chain** step order explicitly specified for cross-platform behavior? [Clarity, data-model]  
  > **RESOLVED 2026-04-25**: Listed order is the priority order. data-model.md updated to state explicitly: `$env:USERNAME` (1st) → `$env:USER` (2nd) → literal `unknown` (3rd). [data-model.md §ConfigLayer]

- [x] **CHK007**: Is "**unrecognized language code**" defined with a precise, testable rule in the spec itself? [Clarity, FR-006]  
  > **RESOLVED 2026-04-25**: Standard is ISO 639-1. Spec Assumptions updated to name ISO 639-1 explicitly and list the canonical known codes (`en`, `fr`, `es`, `pt`, `de`, `fi`, `hi`). Invalid = not a valid ISO 639-1 two-letter lowercase code → falls back to `en`. Aligns with `/^[a-z]{2}$/` in data-model and config-schema.

---

## Requirement Consistency

- [ ] **CHK008**: Are the **`accepted_languages` empty-list fallback rules** stated consistently across spec, data-model, and config-schema? [Consistency, FR-006]  
  > Spec edge cases: "empty → fall back to English." data-model step 2a: "ensure 'en' is in the list." config-schema.md: "An empty list is treated as `['en']`." Confirm the three descriptions produce identical runtime behavior and that no artifact adds a constraint the others omit.

- [ ] **CHK009**: Is the **`interactions` category's unconstrained behavior** stated consistently in spec (FR-008), data-model (LanguageCategory table), and config-schema? [Consistency, FR-008]  
  > All three artifacts address this; confirm none imposes an `accepted_languages` check on `interactions` while the others explicitly exempt it.

- [ ] **CHK010**: Does the **merge algorithm validation step (step 4)** align with FR-009 by using the *project-layer-resolved* `accepted_languages` — not a stale base-layer copy — when validating user overrides? [Consistency, FR-009]  
  > If the merge algorithm validates user shared-file settings against the base layer's `accepted_languages` instead of the already-merged project value, a project that restricts the list would not enforce its restriction on user overrides. [data-model.md §Merge Algorithm step 4]

---

## Coverage / Edge Cases

- [ ] **CHK011**: Is the behavior specified when `accepted_languages` contains **`en` plus only unrecognized codes** (e.g., `["en", "zz"]`)? [Coverage, Edge Case]  
  > Spec edge case covers "only unrecognized values → fall back to English." But `en` is recognized — after dropping `zz`, the list becomes `["en"]`. Is this narrowing behavior specified and distinct from the all-unrecognized case?

---

## Traceability

- [ ] **CHK012**: Is **`schema_version` handling** present as a requirement in the spec, or only as an undocumented design decision in config-schema.md? [Traceability, Gap]  
  > config-schema.md defines: "If present, must be '1.0'. Unknown versions: log warning, continue." This behavior is not traceable to any FR in the spec (FR-001–FR-016). Either a requirement should be added or this should be marked as an intentional design constraint.

- [ ] **CHK013**: Are success criteria **SC-002 and SC-003** directly traceable to specific merge algorithm steps in data-model.md? [Traceability, Spec §SC-002, SC-003]  
  > SC-002 ("100% of outputs follow effective language policy") and SC-003 ("workflows complete with invalid higher-precedence config") each depend on specific merge/validation steps. If data-model.md does not reference these criteria, a task implementer cannot confirm their implementation satisfies them.
