# Developer Quickstart: Nice Polyglot Extension

**Branch**: `001-polyglot-config-extension` | **Date**: 2026-04-25

This guide is for contributors working on the extension itself.
For end-user installation instructions, see `docs/installation.md`.

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| PowerShell | 7+ (`pwsh`) | Run resolution scripts and SpecKit setup scripts |
| SpecKit CLI (`specify`) | ≥ 0.5.1 | Install/test the extension locally |
| Git | Any recent | User identity for config filenames; branch management |

No `yq` or external YAML tools required — the resolution script uses native PS parsing.

---

## Repository Layout

```text
nice-polyglot/               ← repo root = extension root
├── extension.yml            ← extension manifest
├── config-template.yml      ← template users copy to create any config layer
├── catalog-entry.json       ← copy-paste catalog entry for community catalog
├── .extensionignore         ← exclude dev-only files from installable zip
├── CHANGELOG.md
├── LICENSE
├── README.md                ← bilingual EN+FR overview
│
├── commands/
│   └── apply-language-policy.md   ← the before_* hook command
│
├── scripts/
│   └── powershell/
│       └── resolve-language-policy.ps1  ← config merge script
│
├── docs/
│   ├── installation.md / installation.fr.md
│   ├── configuration.md / configuration.fr.md
│   └── troubleshooting.md / troubleshooting.fr.md
│
├── specs/                   ← SpecKit planning artifacts (excluded from installation)
└── .specify/                ← SpecKit dev config (excluded from installation)
```

---

## Local Development Install

To test the extension in a SpecKit project:

```bash
# From a target project that has SpecKit initialized
specify extension add --dev /path/to/nice-polyglot
```

Verify registration:

```bash
specify extension list
# Should show: ✓ Nice Polyglot (v1.0.0)
```

Check that the hook command was registered:

```bash
# For Claude agent:
ls .claude/commands/speckit.nice-polyglot.*
```

---

## Testing the Resolution Script Directly

Run the script from within any SpecKit project directory:

```powershell
pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1
```

Expected output (with no config files present — script hardcoded defaults):

```
NICE_POLYGLOT_POLICY_START
accepted_languages: en
interactions: en
artifacts: en
documentation: en
code: en
code-comments: en
log-messages: en
internal-docs: en
commit-messages: en
NICE_POLYGLOT_POLICY_END
```

---

## Setting Up a Test Configuration

**Project override** (`.specify/overrides/nice-polyglot-config.yml`):

```yaml
schema_version: "1.0"
accepted_languages:
  - en
  - fr
language_settings:
  interactions: fr
  artifacts: fr
  documentation: fr
```

**User override** (`.specify/.nice-polyglot/{user}-config.yml`):

```yaml
schema_version: "1.0"
language_settings:
  interactions: es
```

Expected effective policy after merge:
- `accepted_languages`: `en, fr`
- `interactions`: `es` (unconstrained — user override wins)
- `artifacts`: `fr` (project override, valid against accepted_languages)
- `documentation`: `fr` (project override, valid)
- `code`, `code-comments`, `log-messages`, `internal-docs`, `commit-messages`: `en` (script hardcoded defaults, no extension layer config present)

---

## Triggering a Hook Manually

With the extension installed locally, trigger any supported SpecKit workflow command:

```
# In your AI agent:
/speckit.specify "my feature description"
```

The `before_specify` hook will fire automatically before the main command, running
`apply-language-policy.md` and outputting the resolved language policy.

---

## Building the Installable Zip

```bash
# From the repo root — zip the full repository
zip -r nice-polyglot-1.0.0.zip .
```

Install from the zip (the SpecKit CLI reads `.extensionignore` to skip dev-only files during installation):

```bash
specify extension add nice-polyglot --from ./nice-polyglot-1.0.0.zip
```

Verify the installed extension directory does NOT include `specs/`, `.specify/`, `.github/`, `.vscode/`.

---

## Finding Your User Config Path

```powershell
# Run from within any SpecKit project
$email = git config user.email
$user = ($email -replace '@', '-at-' -replace '\.', '-').ToLower()
Write-Host ".specify/.nice-polyglot/$user-config.yml"
```
