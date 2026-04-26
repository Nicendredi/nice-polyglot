# Référence de configuration — Nice Polyglot

> **Version anglaise** : [docs/configuration.md](configuration.md)

---

## Les 8 catégories de langue

Nice Polyglot vous permet de configurer indépendamment la langue pour chacune de ces
catégories de sortie :

| Catégorie | Ce qu'elle contrôle | Contrainte par `accepted_languages` ? |
|---|---|---|
| `interactions` | Langue des échanges entre l'agent et l'utilisateur | **Non** — tout code ISO 639-1 à deux lettres |
| `artifacts` | Fichiers d'artefacts SpecKit (spec.md, plan.md, tasks.md, …) | Oui |
| `documentation` | Documentation destinée aux utilisateurs, générée par les agents | Oui |
| `code` | Identifiants, chaînes et structure du code source généré | Oui |
| `code-comments` | Commentaires dans le code source généré | Oui |
| `log-messages` | Messages de journalisation générés par les agents | Oui |
| `internal-docs` | Documentation interne / à destination des développeurs | Oui |
| `commit-messages` | Messages de commit Git générés par les agents | Oui |

`interactions` est spéciale : elle contrôle la langue dans laquelle l'agent communique
*avec vous*. C'est la seule catégorie qui n'est pas contrainte par `accepted_languages` —
vous pouvez interagir en espagnol même si le projet n'accepte que l'anglais et le français
pour les fichiers partagés.

---

## Le modèle de précédence à 3 couches

Les paramètres sont résolus depuis trois couches optionnelles par ordre de priorité
croissante :

```
Couche extension (priorité la plus faible)
      ↓
Couche projet
      ↓
Couche utilisateur (priorité la plus haute)
```

Chaque couche est optionnelle. Lorsqu'une couche est absente ou illisible, le script se
replie silencieusement sur la couche inférieure. En l'absence de toute couche, les valeurs
par défaut codées en dur s'appliquent (toutes les catégories à `en`, `accepted_languages: [en]`).

### Chemins des fichiers de couche

| Couche | Chemin (relatif à la racine `.specify/`) | Qui le crée |
|---|---|---|
| Extension | `extensions/nice-polyglot/nice-polyglot-config.yml` | Administrateur SpecKit / équipe projet |
| Projet | `overrides/nice-polyglot-config.yml` | Mainteneur du projet (à commiter dans le dépôt) |
| Utilisateur | `.nice-polyglot/{user}-config.yml` | Contributeur individuel (ne pas commiter) |

`{user}` est dérivé à l'exécution :
1. `git config user.email` — assaini : `@` → `-at-`, `.` → `-`, minuscules
   (ex. : `alice@exemple.com` → `alice-at-exemple-com`)
2. `$env:USERNAME` (Windows) ou `$env:USER` (macOS / Linux)
3. Chaîne littérale `unknown` (avertissement écrit sur stderr)

---

## Créer une configuration de projet

1. Copiez `config-template.yml` vers `.specify/overrides/nice-polyglot-config.yml` :

   ```bash
   cp config-template.yml .specify/overrides/nice-polyglot-config.yml
   ```

2. Décommentez et définissez les champs nécessaires :

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

3. Commitez le fichier dans le dépôt du projet pour qu'il s'applique à tous les
   contributeurs.

---

## Créer une configuration utilisateur

1. Trouvez votre chemin de configuration attendu :

   ```powershell
   $email = git config user.email
   $user  = ($email -replace '@', '-at-' -replace '\.', '-').ToLower()
   Write-Host ".specify/.nice-polyglot/$user-config.yml"
   ```

2. Copiez `config-template.yml` vers ce chemin :

   ```bash
   cp config-template.yml .specify/.nice-polyglot/alice-at-exemple-com-config.yml
   ```

3. Décommentez et définissez vos préférences personnelles.

4. **Ne commitez pas** le fichier de configuration utilisateur — il est personnel et doit
   figurer dans `.gitignore`.

### Limites de la configuration utilisateur

- `accepted_languages` dans la couche utilisateur est **toujours ignoré** (un avertissement
  est écrit sur stderr). La couche projet est la seule autorité pour `accepted_languages`.
- Toutes les catégories de sortie de fichiers partagés (`artifacts`, `documentation`,
  `code`, `code-comments`, `log-messages`, `internal-docs`, `commit-messages`) sont validées
  par rapport à `accepted_languages` du projet. Si vous définissez l'une de ces catégories
  dans une langue hors de la liste du projet, **toute la couche utilisateur est ignorée**
  et un avertissement est écrit sur stderr.
- `interactions` n'a pas cette restriction — vous pouvez la définir avec n'importe quel code
  ISO 639-1 valide à deux lettres, indépendamment de `accepted_languages`.

---

## Comportement de `accepted_languages`

`accepted_languages` déclare l'ensemble des langues valides pour les catégories de sortie
de fichiers partagés. Règles :

- Chaque valeur doit être un code ISO 639-1 en minuscules à deux lettres (ex. : `en`, `fr`,
  `es`).
- `en` est toujours implicitement présent. S'il est omis, il est ajouté automatiquement.
- Si un code de la liste est invalide (ne correspond pas à `/^[a-z]{2}$/`), **toute la
  couche est ignorée** (V-002).
- Un `accepted_languages` vide ou absent est traité comme `[en]` (V-001).
- Seule la **couche projet** fait autorité pour `accepted_languages`. La couche extension
  peut le définir comme valeur par défaut partagée ; la valeur de la couche utilisateur est
  ignorée.

---

## Exemple annoté

Cet exemple est identique au scénario du guide de démarrage rapide pour les développeurs.

### État de base (aucun fichier de configuration)

L'exécution du script sans fichier de configuration produit les valeurs par défaut
tout en anglais :

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

### Après ajout d'une configuration de projet

**Fichier** : `.specify/overrides/nice-polyglot-config.yml`

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

L'exécution du script produit désormais :

```
NICE_POLYGLOT_POLICY_START
accepted_languages: en,fr
interactions: fr
artifacts: fr
documentation: fr
code: en
code-comments: en
log-messages: en
internal-docs: en
commit-messages: en
NICE_POLYGLOT_POLICY_END
```

*`code`, `code-comments`, `log-messages`, `internal-docs`, `commit-messages` restent `en`
car la configuration de projet ne les a pas définis.*

### Après ajout d'une configuration utilisateur

**Fichier** : `.specify/.nice-polyglot/alice-at-exemple-com-config.yml`

```yaml
schema_version: "1.0"
language_settings:
  interactions: es
```

L'exécution du script produit désormais :

```
NICE_POLYGLOT_POLICY_START
accepted_languages: en,fr
interactions: es
artifacts: fr
documentation: fr
code: en
code-comments: en
log-messages: en
internal-docs: en
commit-messages: en
NICE_POLYGLOT_POLICY_END
```

*`interactions` est `es` (espagnol) car elle n'est pas contrainte par `accepted_languages`.*
*`accepted_languages` reste `en,fr` depuis la couche projet — l'utilisateur ne peut pas le
modifier.*
*Toutes les catégories de sortie partagées restent validées par rapport à `[en, fr]`.*

---

## Validation en bref

| Scénario | Résultat |
|---|---|
| Fichier de couche absent | Couche ignorée silencieusement |
| Fichier de couche illisible / malformé | Couche ignorée ; avertissement sur stderr |
| `accepted_languages` contient un code invalide | Couche entière ignorée ; avertissement sur stderr |
| Catégorie partagée définie avec un code hors `accepted_languages` | Couche entière ignorée ; avertissement sur stderr |
| `interactions` défini avec un code invalide | Couche entière ignorée ; avertissement sur stderr |
| Couche utilisateur définit `accepted_languages` | Champ ignoré ; avertissement sur stderr ; reste de la couche appliqué si valide |
| `accepted_languages` vide après fusion | Traité comme `[en]` |
