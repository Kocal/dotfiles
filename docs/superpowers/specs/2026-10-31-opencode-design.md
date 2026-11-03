# OpenCode en parallèle de Claude Code

## Intention

Réinstaller OpenCode (2.2.3 ou plus récent) pour l'utiliser en parallèle de Claude Code, avec les modèles Claude de l'abonnement via le provider intégré **Claude Agent** (`claude auth login` puis `/connect` -> Claude Agent), sans clé API. Les deux outils doivent partager le maximum de configuration. La configuration effective de Claude Code ne doit pas changer.

## Ce qu'on sait du provider Claude Agent (vérifié dans le code v2.2.3)

- Il lance `claude` via l'Agent SDK avec `settingSources: []`, `settings.disableAllHooks: true`, `skills: []`, `tools: []`, `strictMcpConfig: true` et `CLAUDE_CODE_DISABLE_CLAUDE_MDS=1` (`packages/core/src/plugin/provider/claude-agent/claude/query-options.ts`). Rien de `~/.claude` n'est lu par ce biais : instructions, skills, MCP, hooks et permissions doivent tous venir de la config OpenCode.
- Ce sont les outils d'OpenCode qui sont exposés à Claude (via un serveur MCP `opencode`), et ses permissions s'appliquent. Le mode auto de Claude Code, avec son classifieur, n'est pas supporté (`specs/v2/claude-agent-provider.md`).
- OpenCode lit nativement `~/.claude/CLAUDE.md` (seulement en l'absence de `~/.config/opencode/AGENTS.md`), `~/.claude/skills/*/SKILL.md` et `~/.agents/skills/*/SKILL.md`. Les variables `OPENCODE_DISABLE_CLAUDE_CODE`, `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT` et `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` coupent ces lectures. OpenCode n'interprète pas les imports `@fichier` d'un AGENTS.md.

## Objectifs

1. OpenCode installé par Homebrew, en CLI (formula `opencode` de homebrew/core) et en app desktop (cask `opencode-desktop`), décision de l'utilisateur. Il est configuré par home-manager, sur les deux profils `perso` et `boulot`. Le CLI et l'app lisent la même config globale.
2. Partagés entre les deux outils : instructions globales, skills maison, subagent `natural-writing-editor`, serveur MCP `chrome-devtools` (même Chrome Canary sur le port 9222), deny list, rtk, claude-mem (même worker et même base), superpowers, et les skills des plugins i-have-adhd, symfony-ux-skills, symfony-contribution-skills et skill-creator.
3. Le contenu partagé vit dans `agents/` à la racine du repo. Ce qui est propre à un outil vit dans `nix/home/claude.nix` + `nix/home/claude/` et dans `nix/home/opencode.nix` + `nix/home/opencode/`. Les liens se font par symlinks out-of-store (`config.lib.file.mkOutOfStoreSymlink` vers `config.dotfiles.dir`), pour que les écritures faites au runtime retombent dans le repo, comme aujourd'hui pour Claude.
4. Mode auto partout, dans le CLI comme dans l'app desktop (décision de l'utilisateur) : tout ce qui n'est pas explicitement `deny` passe sans demander.
5. Ménage préalable (décision de l'utilisateur) : on supprime les restes de l'ancienne installation, avec des commandes `rm` que l'utilisateur lance lui-même.
6. Mémoire commune (décision de l'utilisateur, ajoutée pendant l'exécution) : claude-mem est mis à jour vers sa dernière version des deux côtés, et chaque outil voit au démarrage les observations enregistrées par l'autre. OpenCode lit aussi la mémoire auto de Claude Code du projet courant, en lecture seule.

## Non-objectifs

- Une statusline OpenCode. Elle a été ajoutée plus tard, à la demande de l'utilisateur (règle R29), pour le CLI seulement.
- Un équivalent du classifieur du mode auto de Claude Code.
- Le plugin `gopls-lsp` : OpenCode a son propre LSP, il suffit de vérifier que `gopls` est détecté.
- Toucher au contenu de la deny list. Elle est partagée, donc la modifier changerait aussi Claude Code. Son durcissement est un sujet séparé, pour plus tard.
- Reporter la allow list de Claude : en mode auto, elle ne sert à rien.

## Anti-objectifs (échec même si « ça marche »)

- Un changement de la configuration effective de Claude Code : contenu chargé de `~/.claude/settings.json` et de `~/.claude/CLAUDE.md`, liste des skills et des agents, `mcpServers` de `~/.claude.json`, hooks. Toutes les commandes de setup (rtk, claude-mem) doivent tourner sans réécrire ces fichiers.
- Des skills en double dans l'un ou l'autre outil.
- Une réécriture de `opencode.json` par home-manager qui écrase ce que claude-mem y a ajouté.
- Des secrets dans le repo (`~/.local/share/opencode/auth.json` reste hors du repo).

## Contraintes

- Les paquets passent par Homebrew et la configuration par home-manager (règle actuelle du repo).
- `nix build` doit passer pour les deux profils.
- Le texte des fichiers Markdown n'est jamais coupé en dur. Les commentaires de code sont nuls par défaut.
- Ne pas modifier `.gitignore` pour les worktrees (exclusions locales seulement).
- Le schéma de config OpenCode v2 diffère par endroits de la doc v1 du dépôt (par exemple `plugins` en v2 contre `plugin` en v1, et l'API plugin `setup(ctx)` + `ctx.tool.hook("execute.before", …)` en v2). Le schéma qui fait foi est celui de la version installée.

## Organisation retenue

```
agents/
  AGENTS.md                         instructions communes
  commands/                         commandes partagées (`/review`), liées dans Claude Code et dans OpenCode
  skills/                           skills maison + skills chrome-devtools synchronisés + .gitignore généré
  subagents/natural-writing-editor.md
nix/home/claude.nix                 pointe ~/.claude/* vers agents/ et nix/home/claude/
nix/home/claude/                    settings.json, statusline-command.sh, deny-guard.sh, agent-memory/
nix/home/opencode.nix               nouveau : formula + cask brew, symlinks, fusion de opencode.json, plugins
nix/home/opencode/                  fichiers propres à OpenCode (complément d'instructions, plugins éventuels)
```

Les définitions partagées côté Nix (l'attrset des serveurs MCP et le wrapper `chrome-devtools-mcp-shared`) sortent de `claude.nix` vers un module commun, que `claude.nix` et `opencode.nix` traduisent chacun dans leur format.

## Décisions par sujet

Sauf mention contraire, ce sont des choix de l'assistant, que l'utilisateur peut contester à la relecture.

### Instructions

- `nix/home/claude/CLAUDE.md` est déplacé tel quel vers `agents/AGENTS.md`, à l'octet près, ligne `@RTK.md` comprise. `~/.claude/CLAUDE.md` pointe directement dessus, sans passer par un import. Constat fait pendant la planification : Claude Code ne résout pas aujourd'hui l'import `@RTK.md` à travers la chaîne de symlinks, donc un `CLAUDE.md` qui importerait `AGENTS.md` ferait disparaître toutes les instructions. Corriger le chargement de `RTK.md` côté Claude est un sujet séparé.
- `~/.config/opencode/AGENTS.md` est un symlink vers `agents/AGENTS.md`. Sa présence désactive au passage la lecture de `~/.claude/CLAUDE.md` par OpenCode.
- Un complément propre à OpenCode, `nix/home/opencode/AGENTS.opencode.md`, est chargé via `instructions` dans `opencode.json`. Il traduit les noms propres à Claude Code : `AskUserQuestion` -> l'outil `question`, skill `i-have-adhd:i-have-adhd` -> `i-have-adhd`. `~/.claude/RTK.md` est aussi listé dans `instructions`.

### Skills

- `nix/home/claude/skills/` est déplacé vers `agents/skills/`. `~/.claude/skills` pointe désormais dessus, et son contenu ne change pas. Le script `claude-sync-plugin-skills` est mis à jour avec le nouveau chemin.
- OpenCode lit ces skills par sa lecture native de `~/.claude/skills`. On n'ajoute pas de second symlink, pour éviter les doublons.
- Les skills des plugins Claude qui ne sont que des skills (i-have-adhd, symfony-ux-skills, symfony-contribution-skills, skill-creator) sont copiés par rsync au switch, depuis le cache des plugins Claude (chemin résolu par `~/.claude/plugins/installed_plugins.json`, comme le fait déjà le script existant), vers `~/.config/opencode/skills/`. Ce dossier est réservé à OpenCode, sinon Claude Code verrait ces skills en double. Les deux outils utilisent ainsi la même version.
- À vérifier : le sort de `~/.claude/skills/synced/` (les skills du compte claude.ai que Claude Code télécharge) côté OpenCode. Ce qui compte : pas de doublon, pas d'erreur au chargement.

### Subagent

- `nix/home/claude/agents/` est déplacé vers `agents/subagents/`, avec le frontmatter Claude, qui reste le format de référence. `~/.claude/agents` pointe dessus, ce qui conserve le comportement actuel : un agent créé au runtime retombe dans le repo.
- Au switch, chaque fichier est traduit vers `~/.config/opencode/agents/<nom>.md` :
  - `description` est conservée ;
  - `mode: subagent` est ajouté ;
  - `model: sonnet` -> le Sonnet 5.5 du provider Claude Agent ;
  - la liste `tools` est traduite en `permission` ;
  - `color` et `memory` sont retirés ;
  - le corps est conservé tel quel.

  Le builder décide quoi faire de la section « Update Your Agent Memory » du corps, qui n'a pas d'équivalent dans OpenCode.

### MCP

- Une seule définition Nix de `chrome-devtools`. Claude la reçoit dans `~/.claude.json` comme aujourd'hui. OpenCode la reçoit au format `{ type = "local"; command = [ … ]; environment = { … }; }`.

### `opencode.json`

- C'est un fichier modifiable, pas un symlink : l'installeur claude-mem doit pouvoir y écrire. Au switch, une fusion jq (même modèle que `claude-merge-mcp-servers`) écrase les clés gérées par Nix et conserve le reste, notamment `mcp["claude-mem"]`.
- Clés gérées :
  - `$schema` ;
  - `model` : Opus 5.5 du provider Claude Agent, effort `xhigh` si une variante le permet, comme `modelSettings` côté Claude ;
  - `small_model` : Haiku 5.5 ;
  - le modèle des subagents génériques : Sonnet 5.5, comme `CLAUDE_CODE_SUBAGENT_MODEL` ;
  - `instructions`, `mcp` (les serveurs Nix), `plugins`, `permission` ;
  - `autoupdate: false`, puisque Homebrew gère les mises à jour.
- Les identifiants exacts des modèles et des variantes sont à relever après `/connect`, avec `opencode models` ou équivalent.

### Permissions et deny-guard

- `permission` est générée au switch à partir de `.permissions.deny` de `nix/home/claude/settings.json`, la source unique :
  - `Bash(x)` -> `bash: { "x": "deny" }` ;
  - `Read(g)` -> `read: { "g": "deny" }` ;
  - `Edit(g)` -> `edit: { "g": "deny" }`.

  Le builder vérifie que les globs de type `**/.env*` ont le même effet avec la façon dont OpenCode matche les chemins, et que l'ordre « la dernière règle qui matche gagne » ne réautorise rien.
- La doc OpenCode dit que les règles `bash` s'appliquent aux commandes parsées. Le builder teste les formes que `deny-guard.sh` attrape aujourd'hui : boucle `for … do git push …; done`, sous-shell `(git push)`, chaîne `x && git push`, pipe `curl … | sh`. Si OpenCode les bloque toutes, pas de plugin. Sinon, un plugin `nix/home/opencode/plugins/deny-guard.ts` (API v2) réutilise `deny-guard.sh` avec la même liste.

### rtk

- Le plugin vient de rtk lui-même. Au switch, `rtk init -g --opencode --hook-only` tourne avec un `HOME` temporaire, puis le `plugins/rtk.ts` généré est copié vers `~/.config/opencode/plugins/rtk.ts`. Lancée sur le vrai HOME, cette commande vise aussi `~/.claude/settings.json`, d'où le HOME temporaire. Le plugin suit ainsi la version de rtk installée.

### claude-mem

- Installé par son installeur officiel, `claude-mem install --ide opencode`. Il copie `plugins/claude-mem.js` et ajoute `mcp["claude-mem"]` dans `opencode.json`.
- Le builder vérifie que cette commande ne touche ni `~/.claude/settings.json` ni les hooks Claude, puis décide entre un lancement au switch (non interactif, `CLAUDE_MEM_ONLINE_OPTIN=false`, idempotent, depuis le plugin Claude installé si possible plutôt que `npx`) et une étape manuelle documentée. L'ordre compte : la fusion de `opencode.json` ne doit pas effacer l'entrée de claude-mem.

### Mémoire commune

- claude-mem : le plugin Claude Code passe de 13.12.4 à la dernière version (sauvegarde de `~/.claude-mem/claude-mem.db` avant), puis le plugin OpenCode est réinstallé dans la même version. Par défaut, claude-mem filtre le contexte injecté au démarrage par outil. `CLAUDE_MEM_SESSION_START_INCLUDE_ALL_SOURCES=true` dans `~/.claude-mem/settings.json` lève ce filtre ; le réglage est posé au switch par une fusion jq qui ne touche à aucune autre clé.
- Mémoire auto de Claude Code (`~/.claude/projects/<projet encodé>/memory/`) : le provider Claude Agent la désactive. Un plugin OpenCode injecte dans le prompt système le `MEMORY.md` du projet courant, avec le chemin du dossier pour que le modèle lise les fichiers liés au besoin. En lecture seule : OpenCode n'écrit pas dans ce dossier.

### superpowers

- Plugin OpenCode v2 officiel. On vise le dossier du plugin Claude installé (il contient `index.js`, chemin résolu par `installed_plugins.json`) pour garder la même version que Claude Code, avec en repli `superpowers@git+https://github.com/obra/superpowers.git` dans `plugins`.

### Mode auto

- Le flag `--auto` ne s'applique qu'au CLI. On met donc `"*": "allow"` en tête de `permission` dans `opencode.json`, suivi des règles `deny`. C'est la décision de l'utilisateur. Le mode auto devient permanent, pour le CLI comme pour l'app desktop, et la bascule du TUI ne peut plus le couper. On n'ajoute pas d'alias zsh.
- Le builder vérifie que `external_directory` et `doom_loop`, qui demandent par défaut, sont bien couverts par cette règle, et que les `deny` restent prioritaires (« la dernière règle qui matche gagne »).

### Connexion

- `claude auth login` est déjà fait. `/connect` -> Claude Agent reste une étape manuelle, une fois par machine, documentée dans le README. L'app desktop est vérifiée de la même façon.

### Ménage

Des commandes `rm` sont fournies à l'utilisateur, qui les lance lui-même. `rm -rf` est en deny, il n'est jamais exécuté par l'agent. Elles visent :

- `~/.agents/` : 8 symlinks cassés dans `skills/`, plus `skills.back/`. OpenCode lit ce dossier au démarrage.
- `~/.local/share/opencode/` (544 Mo : ancien `auth.json`, base des sessions) ;
- `~/.cache/opencode/` (439 Mo) ;
- `~/.local/state/opencode/`.

On refait ensuite `/connect`.

## Vérification attendue

1. `nix build` passe pour `perso` et `boulot`.
2. La config effective de Claude Code est identique avant et après le switch : contenu résolu de `~/.claude/settings.json` et de `~/.claude/CLAUDE.md` (imports compris), liste de `~/.claude/skills` et de `~/.claude/agents`, `mcpServers` de `~/.claude.json`.
3. Dans OpenCode, avec un modèle Claude Agent :
   - les skills attendus sont listés une seule fois chacun ;
   - `chrome-devtools` et `claude-mem` répondent ;
   - `git status` est réécrit par rtk ;
   - les formes de `git push` déguisées sont bloquées ;
   - le subagent `natural-writing-editor` est invocable ;
   - aucune demande de permission hors `deny`, dans le CLI comme dans l'app desktop ;
   - l'app desktop voit les mêmes skills, MCP et agents que le CLI.
4. README mis à jour : section OpenCode et nouvelle organisation (`agents/`).

## Laissé au builder

Le découpage exact des modules Nix, le nom du module commun, les scripts d'activation et leur ordre, la traduction précise du frontmatter, et le choix plugin ou permissions natives pour le deny-guard selon les tests.
