# Not So Advance Wars (serveur)

Un jeu vidéo de tactique au tour par tour, développé dans le cadre de [la jam Gamecodeur #19](https://itch.io/jam/gamecodeur-gamejam-19).

Le serveur est développé en [Elixir](https://elixir-lang.org).

Le client du jeu est développé en Lua pour [le moteur LÖVE](https://love2d.org) et est également [disponible sur GitHub](https://github.com/Sephi-Chan/not_so_advance_wars-client).


## Installation du serveur

Il faut installer Elixir pour exécuter le serveur : [l'installation est expliquée dans la documentation d'Elixir](https://elixir-lang.org/install.html). Elle s'est révélée extrêmement simple sur mon serveur Debian.

Une fois Elixir installé, on clône le dépôt du serveur, on télécharge les dépendances de l'application Elixir, puis on compile l'application. Enfin, on lance l'application en tâche de fond.

```
git clone https://github.com/Sephi-Chan/not_so_advance_wars-server.git && cd not_so_advance_wars-server
mix deps.get && MIX_ENV=prod mix release --env=prod
_build/prod/rel/jam_19_tanks/bin/jam_19_tanks start
```

Il n'y a plus qu'à modifier la variable `server_ip` du [client Lua/LÖVE](https://github.com/Sephi-Chan/not_so_advance_wars-client/blob/master/main.lua#L10) pour qu'il pointe vers votre serveur. :)
