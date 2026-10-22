# Redéclenchement manuel (vibe, 22/10)

Fichier sans effet technique (ni compose ni bot ne le lit) : posé
sous envs/drasah/ pour déclencher le workflow « Deploy environment »
(paths: envs/**) car le run du pin drasah@5130699 (#1126) restait
pending. Le déploiement re-déploie l'image DÉJÀ épinglée dans
state/kingdoms-bot.yml (drasah@5130699).

Peut être supprimé sans effet sur le déploiement.
