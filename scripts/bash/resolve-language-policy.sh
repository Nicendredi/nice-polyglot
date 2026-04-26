#!/usr/bin/env bash
#
# resolve-language-policy.sh
#
# Nice Polyglot — Multilingual Configuration Extension for SpecKit
# Bash counterpart to resolve-language-policy.ps1
#
# STATUS: SCAFFOLD ONLY — not yet implemented.
#
# The PowerShell version (resolve-language-policy.ps1) is the authoritative
# implementation for v1.0.0. This file reserves the extension point for a
# future feature that will implement full bash support.
#
# Full implementation and Principle III compliance (common.sh integration)
# are deferred to the feature that fully implements resolve-language-policy.sh.
# common.sh does not exist yet; it is expected to be provided by SpecKit
# alongside common.ps1.
#
# ---------------------------------------------------------------------------
# EXPECTED ALGORITHM (mirrors resolve-language-policy.ps1 logic)
# ---------------------------------------------------------------------------
#
# 1. Bootstrap: locate .specify root by searching upward from the script
#    directory, then from the working directory.
#    Source common.sh from <specifyRoot>/.specify/scripts/bash/common.sh.
#    Call get_repo_root to obtain the canonical .specify root.
#    Exit with code 1 and stderr message if common.sh is not found or
#    get_repo_root fails.
#
# 2. Derive user identity:
#    a. Try: git config user.email, sanitise (@ -> -at-, . -> -, lowercase)
#    b. Fallback: $USER
#    c. Final fallback: literal "unknown" (write warning to stderr)
#
# 3. Construct config layer paths (all relative to .specify root):
#    Extension : <specifyRoot>/extensions/nice-polyglot/nice-polyglot-config.yml
#    Project   : <specifyRoot>/overrides/nice-polyglot-config.yml
#    User      : <specifyRoot>/.nice-polyglot/<user>-config.yml
#
# 4. Parse each layer using a line-by-line YAML parser (no yq dependency).
#
# 5. Merge layers following the 3-layer algorithm from data-model.md:
#    - Start with hardcoded defaults (all categories "en").
#    - Apply extension, then project, then user layer in order.
#    - Validate accepted_languages codes against /^[a-z]{2}$/ (V-002).
#    - Validate shared file-output category values against accepted_languages
#      (V-003).
#    - Validate interactions against /^[a-z]{2}$/ (V-004).
#    - Discard any invalid layer; log warning to stderr.
#    - User layer: ignore accepted_languages if present; log warning (V-005).
#
# 6. Emit structured sentinel block to stdout:
#
#    NICE_POLYGLOT_POLICY_START
#    accepted_languages: en,fr
#    interactions: fr
#    artifacts: fr
#    documentation: fr
#    code: en
#    code-comments: en
#    log-messages: en
#    internal-docs: fr
#    commit-messages: en
#    NICE_POLYGLOT_POLICY_END
#
# Exit codes: 0 = success, 1 = fatal error (common.sh not found / no .specify root)
# Warnings for skipped layers are written to stderr only, never to stdout.
#
# ---------------------------------------------------------------------------

echo "[nice-polyglot] ERROR: resolve-language-policy.sh is not yet implemented." >&2
echo "[nice-polyglot] Use the PowerShell version: scripts/powershell/resolve-language-policy.ps1" >&2
exit 1
