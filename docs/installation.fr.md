# Guide d'installation — Nice Polyglot

> **Version anglaise** : [docs/installation.md](installation.md)

---

## Prérequis

| Outil | Version minimale | Rôle |
|---|---|---|
| [SpecKit CLI](https://github.com/nicendredi/speckit) (`specify`) | **≥ 0.5.1** | Installer et gérer les extensions SpecKit |
| [PowerShell](https://github.com/PowerShell/PowerShell) (`pwsh`) | **7** | Exécuter le script de résolution de langue |
| [Git](https://git-scm.com) | Toute version récente | Dériver le nom du fichier de configuration utilisateur depuis `git config user.email` |

> **Note** : PowerShell 7 est obligatoire pour le script de résolution. Le Windows PowerShell
> intégré 5.1 (`powershell.exe`) **n'est pas** suffisant.

---

## Installation depuis une archive zip

1. Téléchargez ou construisez l'archive zip de l'extension (racine complète du dépôt) :

   ```bash
   # Depuis la racine du dépôt
   Compress-Archive -Path . -DestinationPath nice-polyglot-1.0.0.zip
   ```

2. Exécutez la commande d'installation depuis n'importe quel projet SpecKit :

   ```bash
   specify extension add nice-polyglot --from ./nice-polyglot-1.0.0.zip
   ```

   Le CLI SpecKit lit `.extensionignore` lors de l'installation et exclut automatiquement
   les fichiers réservés au développement (`specs/`, `.specify/`, `.github/`, `.vscode/`)
   de la copie installée.

---

## Installation depuis le catalogue communautaire

1. Ajoutez le contenu de `catalog-entry.json` au fichier `catalog.json` de votre projet.

2. Exécutez :

   ```bash
   specify extension add nice-polyglot
   ```

---

## Vérification de l'installation

Après l'installation, confirmez que l'extension est enregistrée :

```bash
specify extension list
# Résultat attendu : ✓ Nice Polyglot (v1.0.0)
```

Confirmez que la commande de hook est enregistrée (exemple pour un agent basé sur Claude) :

```bash
ls .claude/commands/speckit.nice-polyglot.*
# Résultat attendu : speckit.nice-polyglot.apply-language-policy.md (ou chemin équivalent)
```

---

## Valeurs par défaut au premier démarrage

Aucune configuration n'est requise pour que l'extension fonctionne. En l'absence de tout
fichier de configuration, les 8 catégories sont par défaut en anglais (`en`). Vous pouvez
le vérifier en exécutant directement le script de résolution depuis n'importe quel projet
SpecKit ayant l'extension installée :

```powershell
pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1
```

Résultat attendu :

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

## Étapes suivantes

Consultez [docs/configuration.fr.md](configuration.fr.md) pour configurer les paramètres
de langue pour votre projet ou vos préférences personnelles.
