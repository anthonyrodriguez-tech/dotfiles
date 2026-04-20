---
description: Run a thorough review of the current PR or branch (diff, lint, security, tests). Invoke from a repo with a checked-out PR branch.
argument-hint: "[PR number or branch name, optional]"
model: sonnet
---

Tu vas faire une revue complète de la PR **$ARGUMENTS** (ou de la branche courante si
aucun argument n'est fourni). Reste factuel et bref — le but est de produire un rapport
actionnable, pas un mur de texte.

## Étape 1 — Contexte

1. Identifier la PR :
   - Si `$ARGUMENTS` est un numéro : `gh pr view $ARGUMENTS --json title,body,headRefName,baseRefName,files,commits`.
   - Si `$ARGUMENTS` est un nom de branche : `gh pr view $ARGUMENTS ...` idem.
   - Sinon : `gh pr view --json ...` sur la branche courante. Si pas de PR, travailler à
     partir de `git log $(git merge-base HEAD origin/main)..HEAD` et `git diff $(git
     merge-base HEAD origin/main)...HEAD`.
2. Lire la description. Noter l'intention déclarée — tu vérifieras plus bas qu'elle
   correspond au diff.

## Étape 2 — Analyse du diff

1. `git diff <base>...HEAD --stat` pour voir l'ampleur.
2. Pour chaque fichier modifié, lire les hunks pertinents (pas le fichier complet sauf
   si nécessaire).
3. Classer les findings par catégorie :
   - **Correctness** — bugs, null refs, race conditions, logique inversée.
   - **Security** — injection, secrets, authz manquante, XSS, path traversal.
   - **Tests** — couverture, cas limites, tests qui ne testent rien.
   - **Style / conventions** — seulement si ça dépasse ce qu'un linter couvre.
   - **Doc** — README/commentaires désynchronisés du code.

## Étape 3 — Délégation

Si la PR touche de la **Terraform** (fichiers `.tf`, `.tfvars`, `terragrunt.hcl`),
**délègue la partie Terraform au sous-agent `terraform-reviewer`** plutôt que de faire la
revue toi-même. Tu intègreras son rapport dans le tien.

## Étape 4 — Lint / format / tests

Lancer les checks appropriés **seulement si les outils sont installés et déjà configurés
dans le repo** (présence de config file) :
- **JS/TS** : `npm run lint`, `npm run typecheck`, `npm test -- --run`.
- **.NET** : `dotnet format --verify-no-changes`, `dotnet build`, `dotnet test`.
- **Go** : `gofmt -l .`, `go vet ./...`, `go test ./...`.
- **Python** : `ruff check`, `pytest -q`.
- **Shell** : `shellcheck` sur les `.sh` modifiés, `shfmt -d -i 4`.
- **Lua** : `luacheck` si `.luacheckrc` existe.

Ne **pas** installer d'outils si absents. Signaler simplement « linter non disponible ».

## Étape 5 — Rapport

Format exact :

```
## Revue : <title>

**Intention déclarée** : <1 phrase reprenant la PR body>
**Fichiers touchés** : N fichiers, +X / -Y lignes

### 🔴 Bloquants
- `path/to/file.ext:L42` — description + suggestion concrète
- …

### 🟡 À clarifier
- …

### 🟢 Suggestions
- …

### ✅ Lint / tests
- typecheck : PASS | FAIL | non lancé (raison)
- tests unitaires : …
- formateur : …

### Verdict
APPROVE | REQUEST_CHANGES | COMMENT — <une phrase>
```

## À ne pas faire

- Ne **jamais** faire `gh pr merge` ni `git push`.
- Ne pas poster de commentaire sur la PR sans demande explicite (`gh pr comment` est
  interdit dans ce flow — on rend juste le rapport à l'utilisateur).
- Ne pas réécrire la PR. Si un changement est gros, décrire ce qu'il faudrait faire plutôt
  que de le coder.
- Ne pas spéculer : si un outil manque ou si un fichier est illisible, le dire plutôt que
  d'inventer.
