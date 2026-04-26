# Guide de dépannage — Nice Polyglot

> **Version anglaise** : [docs/troubleshooting.md](troubleshooting.md)

---

## Le hook ne se déclenche pas

**Symptôme** : L'exécution d'une commande SpecKit prise en charge (ex. `/speckit.specify`)
ne produit pas de bloc de politique de langue avant le début du workflow principal.

**Vérifications** :

1. Vérifiez que l'extension est installée :

   ```bash
   specify extension list
   # Doit afficher : ✓ Nice Polyglot (v1.0.0)
   ```

2. Vérifiez que votre version de SpecKit est ≥ 0.5.1 :

   ```bash
   specify --version
   ```

3. Vérifiez que le fichier de commande de hook existe au chemin attendu :

   ```bash
   ls .claude/commands/speckit.nice-polyglot.apply-language-policy.md
   ```

4. Ouvrez `extension.yml` (dans le répertoire de l'extension installée) et confirmez que
   les cinq hooks `before_*` pointent tous vers `speckit.nice-polyglot.apply-language-policy`.

---

## Toutes les sorties sont en anglais malgré la configuration

**Symptôme** : Vous avez un fichier de configuration mais les artefacts SpecKit, la
documentation ou d'autres sorties sont toujours générés en anglais.

**Causes courantes et solutions** :

| Cause | Solution |
|---|---|
| Le fichier de configuration est au mauvais chemin | Exécutez le script directement (voir [ci-dessous](#exécuter-le-script-directement)) et vérifiez la sortie — si tout est `en`, le fichier n'est pas pris en compte. Vérifiez que le chemin correspond au tableau dans [configuration.fr.md](configuration.fr.md). |
| Erreur d'analyse YAML dans le fichier de configuration | Recherchez un message `WARNING: Could not read …` dans la réponse de l'agent. Ouvrez le fichier et vérifiez les erreurs de syntaxe (chaînes non terminées, mauvaise indentation, caractères inattendus). |
| Code de langue absent de `accepted_languages` | Une valeur de catégorie hors de `accepted_languages` invalide toute la couche. Exemple : `artifacts: es` alors que `accepted_languages: [en, fr]` — toute la couche est ignorée et un avertissement est écrit sur stderr. |
| Code de langue en majuscules | Les codes doivent être deux lettres minuscules (ex. : `fr` et non `FR`). Un code en majuscules échoue à la validation et la couche est ignorée. |

---

## WARNING: Could not read {chemin}

**Message complet** : `[nice-polyglot] WARNING: Could not read /chemin/vers/config.yml. Using settings from lower-precedence layers.`

Cet avertissement signifie qu'un fichier de configuration **existe** au chemin indiqué mais
n'a pas pu être analysé.

**Comment diagnostiquer** :

1. Ouvrez le fichier au `{chemin}` indiqué dans un éditeur de texte.
2. Recherchez les problèmes YAML courants :
   - Lignes avec des caractères inattendus (ex. : tabulations au lieu d'espaces, deux-points
     parasites)
   - Valeurs qui ne sont pas des codes ISO 639-1 valides à deux lettres minuscules
   - Codes `accepted_languages` qui ne sont pas deux lettres minuscules
3. Exécutez le script directement en redirigeant stderr pour voir tous les avertissements :

   ```powershell
   pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1 2>&1
   ```

4. Corrigez la ligne problématique ou réinitialisez avec une copie propre de
   `config-template.yml`.

---

## WARNING: accepted_languages ignoré dans la configuration utilisateur

**Message complet** : `[nice-polyglot] WARNING: accepted_languages in user override is ignored (V-005). Set accepted_languages at the project layer instead.`

Il s'agit du comportement attendu (FR-010). Le champ `accepted_languages` dans la couche
utilisateur (`.specify/.nice-polyglot/{user}-config.yml`) est **toujours ignoré** — seule
la couche projet (`.specify/overrides/nice-polyglot-config.yml`) peut définir les langues
acceptées pour les catégories de sortie de fichiers partagés.

**Solution** : Si vous devez modifier `accepted_languages`, éditez plutôt le fichier de
configuration de projet. Notez que le reste de votre couche utilisateur (hors
`accepted_languages`) est toujours appliqué si tous les autres champs sont valides.

---

## Le fichier de configuration utilisateur n'est pas pris en compte

**Symptôme** : Vous avez créé un fichier de configuration utilisateur mais l'agent utilise
toujours les valeurs par défaut du projet.

**Comment trouver le nom de fichier attendu** :

```powershell
$email = git config user.email
$user  = ($email -replace '@', '-at-' -replace '\.', '-').ToLower()
Write-Host "Chemin attendu : .specify/.nice-polyglot/$user-config.yml"
```

Assurez-vous que le fichier existe **exactement** à ce chemin. Erreurs courantes :
- Le fichier utilise un format d'assainissement différent (ex. : `_` au lieu de `-` pour `.`)
- `git config user.email` retourne une adresse différente dans ce dépôt par rapport à celle
  utilisée lors de la création du fichier
- Le répertoire `.specify/.nice-polyglot/` n'existe pas

---

## Exécuter le script directement

Vous pouvez exécuter le script de résolution à tout moment pour voir la politique effective
actuelle et les avertissements stderr :

```powershell
# Depuis la racine du projet (avec l'extension installée)
pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1
```

Pour voir stdout et stderr ensemble :

```powershell
pwsh .specify/extensions/nice-polyglot/scripts/powershell/resolve-language-policy.ps1 2>&1
```

**Interprétation de la sortie** :
- Les lignes entre `NICE_POLYGLOT_POLICY_START` et `NICE_POLYGLOT_POLICY_END` montrent
  la politique résolue appliquée au workflow.
- Les lignes commençant par `[nice-polyglot] WARNING:` (sur stderr) indiquent les couches
  ignorées et les champs non pris en compte.
- Code de sortie `0` = politique résolue avec succès.
- Code de sortie `1` = erreur fatale (racine `.specify` introuvable, `common.ps1` introuvable).
