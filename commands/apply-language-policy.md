---
description: "Resolve and apply the effective Nice Polyglot language policy for this workflow"
scripts:
  ps: ../../scripts/powershell/resolve-language-policy.ps1
---

Run the resolution script to determine the effective language policy for this workflow session:

```
{SCRIPT}
```

Parse the output block between `NICE_POLYGLOT_POLICY_START` and `NICE_POLYGLOT_POLICY_END` to
extract the resolved language assignments.

If there are any warnings on stderr (e.g. `[nice-polyglot] WARNING: Could not read ...`), surface
them to the user as a brief note before beginning the main task. For example:

> **Note (Nice Polyglot):** One or more config layers were skipped — see details below. Using
> settings from the last valid layer.

Using the effective language policy resolved above, apply the following rules
for ALL outputs produced during this workflow session:

- User interactions and conversational responses: use the `interactions` language
- SpecKit artifact files (spec.md, plan.md, tasks.md, research.md, etc.): use the `artifacts` language
- User-facing documentation: use the `documentation` language
- Generated source code identifiers, strings, and structure: use the `code` language
- Comments inside generated code: use the `code-comments` language
- Log output messages: use the `log-messages` language
- Internal/developer-facing documentation: use the `internal-docs` language
- Git commit messages: use the `commit-messages` language

These settings are authoritative for this session. Do not revert to any other
language without being explicitly instructed to do so by the user.
