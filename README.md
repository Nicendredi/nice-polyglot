# nice-polyglot

[Version française plus bas](#version-francaise)

## English

nice-polyglot is a SpecKit Community Extension for SpecKit v0.5.0+.

Its purpose is to configure agent generation and agent interaction so commands can work in the
language selected by configuration.

Configuration follows a strict override order:

1. `nice-polyglot-config.yml` in the installed extension
2. `.specify/overrides/nice-polyglot-config.yml` in the consuming project
3. `.specify/.nice-polyglot/{user}-config.yml` for user-level overrides

When a feature needs to resolve `.specify` paths, it is expected to use
`.specify/scripts/powershell/common.ps1` where possible.

The extension is intended to ship as a zip archive so it can be referenced from a SpecKit
extension catalog entry.

## Version francaise

nice-polyglot est une extension communautaire SpecKit pour SpecKit v0.5.0 et versions
ulterieures.

Son objectif est de configurer la generation produite par les agents et l'interaction avec les agents afin que
les commandes puissent fonctionner dans la langue choisie par la configuration.

La configuration suit un ordre strict de surcharge :

1. `nice-polyglot-config.yml` dans l'extension installee
2. `.specify/overrides/nice-polyglot-config.yml` dans le projet consommateur
3. `.specify/.nice-polyglot/{user}-config.yml` pour les surcharges au niveau utilisateur

Lorsqu'une fonctionnalite doit resoudre des chemins `.specify`, elle doit utiliser
`.specify/scripts/powershell/common.ps1` lorsque c'est possible.

L'extension doit etre publiee sous forme d'archive zip afin de pouvoir etre referencee depuis
une entree de catalogue d'extensions SpecKit.
