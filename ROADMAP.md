# Roadmap

This roadmap documents the current limitations, known issues, and planned enhancements for future `nice-polyglot` specs and features.

## Current focus

- Preserve project authority over shared file-output languages while allowing personal conversational overrides.
- Resolve effective language settings across built-in defaults, extension-level config, project-level config, and user-level overrides.
- Keep the extension distributable through SpecKit's standard extension archive and catalog metadata flow.

## Known limitations

- Artifact templates are currently English-only. Template structure, schema names, and section headings remain English even when generated artifact content is produced in another language.
- There is no dedicated translation command yet for generating localized template files such as `spec-template.fr.md` or `plan-template.fr.md`.
- The current config resolution design treats an invalid field in a layer as a failure for the entire layer, which can discard otherwise valid settings from the same layer.
- Personal overrides cannot expand or replace the project's `accepted_languages` list; user-level `accepted_languages` entries are ignored with a warning.
- User-level config path resolution depends on local identity detection (`git config user.email`, `$env:USERNAME`, `$USER`), which can be confusing and is a source of support friction.
- Some agents may still misinterpret the `interactions` category in prompts, causing mixed-language conversational output when language guidance is not explicitly clear.

## Known issues

- Malformed or unreadable config files currently result in warnings but may not always surface enough detail for users to troubleshoot quickly.
- The extension currently lacks a first-class feature for generating bilingual template variants for other than English agent workflows.
- The extension's current policy resolution script logs warnings to stderr, but existing docs can be improved to make those warnings easier to locate.

## Planned enhancements

- Add a translation/template generation command to create localized versions of artifact templates, for example:
  - `spec-template.fr.md`
  - `plan-template.fr.md`
  - `tasks-template.fr.md`

  This command should allow agents and workflows targeting French to use templates that are already structured with French headings and guidance.

- Improve effective setting resolution so that a layer with one invalid field does not invalidate the whole layer. Instead:
  - validate each field independently
  - apply valid fields from the same layer
  - ignore only invalid fields
  - preserve the existing fallback behavior for absent fields and lower-precedence layers

- Expand troubleshooting documentation to make the following easier to diagnose:
  - when a config file is skipped due to YAML or validation errors
  - when `accepted_languages` is ignored in a user override
  - when a local user identity cannot be resolved for user-level config

- Consider a clearer separation between conversational language control and artifact language control so agent guidance is less ambiguous.

## Notes for contributors

- Changes to config resolution should preserve the existing precedence order: built-in defaults, extension layer, project layer, user layer.
- Any future translation command should work from the repository root and create templates that align with existing SpecKit artifact conventions.
- Documentation updates should be maintained in both English and French.
