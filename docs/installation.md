# Installation Guide — Nice Polyglot

> **French version**: [docs/installation.fr.md](installation.fr.md)

---

## Prerequisites

| Tool | Minimum version | Purpose |
|---|---|---|
| [SpecKit CLI](https://github.com/nicendredi/speckit) (`specify`) | **≥ 0.5.1** | Install and manage SpecKit extensions |
| [PowerShell](https://github.com/PowerShell/PowerShell) (`pwsh`) | **7** | Run the language resolution script |
| [Git](https://git-scm.com) | Any recent | Derive the user config filename from `git config user.email` |

> **Note**: PowerShell 7 is required for the resolution script. The built-in Windows PowerShell
> 5.1 (`powershell.exe`) is **not** sufficient.

---

## Installing from a Zip Archive

1. Download or build the extension zip (the full repository root, see [quickstart.md](../specs/001-polyglot-config-extension/quickstart.md)):

   ```bash
   # Build from the repo root
   Compress-Archive -Path . -DestinationPath nice-polyglot-1.0.0.zip
   ```

2. Run the install command from within any SpecKit project:

   ```bash
   specify extension add nice-polyglot --from ./nice-polyglot-1.0.0.zip
   ```

   The SpecKit CLI reads `.extensionignore` during installation and automatically excludes
   dev-only files (`specs/`, `.specify/`, `.github/`, `.vscode/`) from the installed copy.

---

## Installing from the Community Catalog

1. Add the contents of `catalog-entry.json` to your project's `catalog.json`.

2. Run:

   ```bash
   specify extension add nice-polyglot
   ```

---

## Verifying Installation

After installation, confirm the extension is registered:

```bash
specify extension list
# Expected: ✓ Nice Polyglot (v1.0.0)
```

Confirm the hook command is registered (example for a Claude-based agent):

```bash
ls .claude/commands/speckit.nice-polyglot.*
# Expected: speckit.nice-polyglot.apply-language-policy.md (or equivalent path)
```

---

## First-Run Defaults

No configuration is required for the extension to work. When no config files are present,
all 8 categories default to English (`en`). You can verify this by running the resolution
script directly from within any SpecKit project that has the extension installed:

```powershell
pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1
```

Expected output:

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

## Next Steps

See [docs/configuration.md](configuration.md) to configure language settings for your
project or personal preferences.
