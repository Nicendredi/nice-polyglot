# Override Resolution Requirements Checklist

**Purpose**: Validate that requirements governing the 3-layer merge, fallback logic, and `accepted_languages` enforcement are complete, clear, and consistent — before tasks are generated  
**Created**: 2026-04-25  
**Feature**: [spec.md](../spec.md) | **Focus**: Override resolution correctness  
**Audience**: Author self-check  
**Scope**: FR-004, FR-006–FR-011; data-model merge algorithm; config-schema validation constraints

---

## Requirement Completeness

- [ ] **CHK001**: Is the behavior specified when the **extension base config layer** file is missing or unreadable at runtime? [Completeness, Gap]  
  > FR-011 explicitly covers project and user layers, but the data-model merge algorithm (step 1) silently assumes the base layer is always present. If the base file is absent, the starting state of the working policy is undefined.

- [ ] **CHK002**: Is the behavior defined when a user override file **exists but contains zero `language_settings` keys** (e.g., an empty `language_settings:` block or an empty file)? [Completeness, Edge Case]  
  > A syntactically valid but empty layer should be treated as "no overrides from this layer." Neither spec nor data-model explicitly states this. [Spec §FR-011]

- [ ] **CHK003**: Is there a requirement covering what happens when a user layer **sets `accepted_languages`** to a non-empty list — specifically whether this triggers a warning or is silently ignored? [Completeness, FR-010]  
  > FR-010 says the user MUST NOT expand the list; data-model says "ignore." But "silently ignored" vs. "warn the user" is unspecified, yet FR-011 establishes a warning pattern for other invalid inputs.

---

## Requirement Clarity

- [ ] **CHK004**: Is **partial field-level invalidity** in a config layer distinguished from whole-file malformation? [Clarity, Ambiguity]  
  > FR-011 says "ignore that layer's *invalid settings*, retain the previous valid settings" — implying field-level granularity. The data-model step 2c says "if project layer is malformed/unreadable: *skip it*" — implying whole-file. These are in conflict. [Spec §FR-011, data-model.md §Merge Algorithm]

- [ ] **CHK005**: Is the **warning output format and channel** defined for malformed or unreadable config layers? [Clarity, FR-011]  
  > FR-011 requires warning the user, but neither spec nor plan defines what that warning looks like — stdout message, structured YAML field in the script output, log file, or agent-displayed text. Without this, implementers will choose arbitrarily.

- [ ] **CHK006**: Is the **`{user}` identifier fallback chain** step order explicitly specified for cross-platform behavior? [Clarity, data-model]  
  > data-model.md lists `$env:USERNAME` / `$env:USER` / `unknown` as fallbacks but does not state the priority order between `USERNAME` (Windows) and `USER` (POSIX). Ambiguous on environments where both may be set. [data-model.md §ConfigLayer]

- [ ] **CHK007**: Is "**unrecognized language code**" defined with a precise, testable rule in the spec itself? [Clarity, FR-006]  
  > The spec says "unrecognized codes are treated as invalid." The contracts and data-model tighten this to `/^[a-z]{2}$/`. If the spec is the authoritative requirements document, this precision is missing there. [Spec §FR-006, Assumptions]

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
