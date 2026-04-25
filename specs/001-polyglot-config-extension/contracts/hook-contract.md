# Contract: Hook Command Interface

**Branch**: `001-polyglot-config-extension` | **Date**: 2026-04-25

This contract defines the interface between the `apply-language-policy.md` hook command,
the `resolve-language-policy.ps1` resolution script, and the SpecKit agent workflow.

---

## Hook Registration

In `extension.yml`, hooks are declared for every supported SpecKit command:

```yaml
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

All hooks point to the same command. The same resolution and instruction logic applies
regardless of which SpecKit command triggered the hook.

---

## Hook Command File: `commands/apply-language-policy.md`

**Frontmatter contract**:

```yaml
---
description: "Resolve and apply the effective Nice Polyglot language policy for this workflow"
scripts:
  ps: ../../scripts/powershell/resolve-language-policy.ps1
---
```

The `{SCRIPT}` placeholder is replaced by the registered PS script path after extension
installation (SpecKit path rewriting).

**Body contract**: The command file body must:

1. Invoke the resolution script via `{SCRIPT}` (or the rewritten path after installation)
2. Parse the structured output block (see Script Output Contract below)
3. Instruct the agent to apply the resolved settings for the current workflow session

**Required agent instruction text** (included verbatim in the command body):

```
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
```

---

## Resolution Script: `resolve-language-policy.ps1`

**Inputs**: No parameters. Reads config files from paths derived via `common.ps1`'s `Get-RepoRoot`.

**Outputs**: Writes a structured text block to stdout, delimited by sentinel lines.

### Script Output Contract

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
- The block is always present, even when no config file exists (base defaults are output)
- Values are single language codes (validated, never empty, never unrecognized)
- `accepted_languages` is a comma-separated list of valid codes
- One key-value pair per line, `:` separator, single space after `:`
- No trailing whitespace; UTF-8 encoded

### Script Exit Codes

| Code | Meaning |
|---|---|
| `0` | Policy resolved successfully (may include warnings for skipped layers) |
| `1` | Fatal error (e.g., `common.ps1` not found, no `.specify` root found) |

Warnings for skipped malformed layers are written to stderr (not stdout), so the agent's
instruction context receives only the clean policy block.

---

## Agent Consumption Contract

The agent MUST:

1. Execute the resolution script before any other step in the workflow
2. Locate and read the block between `NICE_POLYGLOT_POLICY_START` and `NICE_POLYGLOT_POLICY_END`
3. Apply the resolved language assignments for the entire session

The agent MUST NOT:
- Override these language assignments unless the user explicitly requests a change
- Apply the languages of previous sessions or cached values
- Fail the workflow if the policy resolves entirely to English defaults

---

## Warning Surface Contract

When a config layer is skipped (malformed/unreadable), the script writes to stderr:

```
[nice-polyglot] WARNING: Could not read {absolute-path}. Using settings from lower-precedence layers.
```

The agent should surface this warning to the user at the start of the workflow (e.g., as a
brief note before beginning the main task).
