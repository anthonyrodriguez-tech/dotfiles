<!--
WHAT  : Global Claude Code memory — loaded for every session on this machine.
WHERE : home/dot_claude/CLAUDE.md  →  ~/.claude/CLAUDE.md
WHY   : Personal preferences that apply across all projects. Project-specific
        rules go in each repo's own CLAUDE.md (not here).
-->

# Préférences globales

## Langue et ton
- **Réponds en français** sauf si la question est posée en anglais ou si le contexte est
  clairement anglophone (codebase internationale, PR review pour l'open source, etc.).
- Concision avant tout : une phrase claire vaut mieux qu'un paragraphe explicatif.
- Pas d'émojis dans le code, les commits ou les réponses, sauf demande explicite.
- Pas de formules creuses (« Bien sûr ! », « Voici… », « J'espère que cela vous aide »).

## Style de code
- Noms explicites > commentaires. N'ajoute un commentaire que pour expliquer **pourquoi**,
  jamais **quoi**.
- Pas de sur-abstraction préventive. Trois lignes similaires valent mieux qu'une
  abstraction mal calibrée.
- Pas de « defensive coding » pour des cas impossibles (trust internal APIs).
- Pas de `try/catch` sans raison — laisse remonter les erreurs que tu ne sais pas traiter.

## Commits
- **Conventional Commits** : `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `perf:`, `style:`.
- Sujet à l'impératif présent, ≤ 72 caractères, **sans point final**.
- Corps explicatif (pourquoi, pas quoi) si le diff ne se suffit pas à lui-même.
- Signature `Co-Authored-By: Claude …` seulement si l'utilisateur le demande ou si
  `includeCoAuthoredBy` est vrai dans les settings.

## Outillage préféré
- Shell : **zsh**. Formater les scripts avec `shfmt -i 4`, valider avec `shellcheck`.
- Editor : **Neovim** (config LazyVim). Pour modifier des fichiers, préférer les outils
  dédiés (Edit/Write) plutôt que `sed`/`awk`.
- Terminal : **WezTerm**. Git UI : **lazygit** (alias `lg`). Pager git : **delta**.
- Langages du quotidien : **C# / .NET**, **Go**, **Terraform**, **Bash**, **Lua** (config nvim).
- Ne génère jamais de Dockerfile avec `apt-get install` sans `--no-install-recommends` et nettoyage `/var/lib/apt/lists`.

## Workflow
- Pour toute tâche non-triviale : proposer un plan court avant d'écrire du code, et attendre
  validation. Éviter de modifier des fichiers sans confirmation quand le diff dépasse ~30 lignes.
- Ne crée pas de fichiers de planification (`NOTES.md`, `TODO.md`) sauf demande explicite.
- Après modification : si le projet a un linter / formateur / test runner, l'exécuter.
  Sinon le dire et ne pas prétendre que le code a été testé.

## Sécurité
- Jamais de secrets en dur dans le code. Si un secret est détecté par erreur, **alerter
  immédiatement** et proposer la rotation.
- Sur le profil `safran` : pas de WebFetch / WebSearch / curl (verrouillé dans settings.json).
  Ne pas tenter de contourner.

## Délégation aux sous-agents
- Utiliser les sous-agents spécialisés quand ils matchent la tâche — notamment
  `terraform-reviewer` pour tout fichier `.tf` / `.tfvars` / plan Terraform.
- Ne pas sur-utiliser les sous-agents pour des tâches simples : chaque spawn est coûteux.
