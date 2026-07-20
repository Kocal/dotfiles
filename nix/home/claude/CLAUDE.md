Commentaires code: défaut = zéro. En écrire SEULEMENT si le "pourquoi" est non-évident et absent du code. Interdit: reformuler le code, n° de ticket, contexte évident. Une ligne courte max.
Descriptions PR: anglais, ton naturel, pas de hard-wrap (pas de coupure à 72/80 cols, lignes longues OK). Rédiger via l'agent natural-writing-editor. Sortir markdown brut copiable/collable du terminal vers GitHub.
Parse données: jq/yq/awk préférés. Pas script Python ad-hoc.
Flèches: utiliser "->" (ASCII), jamais "→" (Unicode). S'applique au texte généré, pas au code source existant.
Git/PR (repos avec fork: origin=fork, upstream=canonical): TOUJOURS push branches feature vers le fork `origin` + ouvrir PR depuis le fork (`gh pr create --head <fork-owner>:<branch>`). JAMAIS push de branche feature ni ouvrir de PR sur `upstream`. `upstream` = fetch/sync canonical seulement. Toujours vérifier `git remote -v` + `gh repo view` avant de push/créer une PR.

@RTK.md
