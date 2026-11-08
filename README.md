# debian-minimal-kids

Un système GNU/Linux minimaliste basé sur Debian, pensé pour les enfants :
simplicité, autonomie et informatique intentionnelle. Moins de superflu, plus
d'exploration.

![Default desktop](screenshots/default_desktop.png)

Construit avec [`live-build`](https://wiki.debian.org/DebianLive) à partir de
**Debian 13 « trixie »** (stable).

> État actuel : **base Debian fonctionnelle avec bureau XFCE**, en **français**,
> avec un ensemble d'applications et de jeux (essentiellement GTK) en cours de
> constitution. Les logiciels sont ajoutés un par un, au fur et à mesure des
> choix du projet.

## Prérequis

La construction de l'ISO nécessite `live-build` sur la machine hôte (Debian ou
dérivé : Debian, Ubuntu, LMDE...) :

```bash
sudo apt update
sudo apt install live-build debootstrap
```

## Construire l'ISO

```bash
./build.sh          # équivaut à : sudo lb build
```

La première construction télécharge la base Debian et peut prendre un moment.
Le résultat est un fichier `debian-minimal-kids-amd64.hybrid.iso` à la racine du
projet, que l'on peut tester dans une machine virtuelle, graver, ou écrire sur
une clé USB.

Au démarrage, le système ouvre directement le **bureau XFCE** en session
automatique, en **français** (clavier AZERTY, fuseau Europe/Paris), avec
l'utilisateur **`lisa`** (hôte `kids-pc`). C'est le cadre propre à enrichir
ensuite.

Pour repartir de zéro :

```bash
./clean.sh          # supprime les artefacts (garde le cache des paquets)
```

## Tester le live en machine virtuelle (QEMU)

```bash
sudo apt install qemu-system-x86
qemu-system-x86_64 -enable-kvm -m 2048 -smp 2 \
  -cdrom debian-minimal-kids-amd64.hybrid.iso -boot d
```

Si `/dev/kvm` est absent, retirez `-enable-kvm` (VM plus lente, mais fonctionnelle).

Pour tester aussi **l'installation sur disque**, créez un disque virtuel et
démarrez l'ISO dessus :

```bash
qemu-img create -f qcow2 kids-test.qcow2 20G
qemu-system-x86_64 -enable-kvm -m 2048 -smp 2 \
  -drive file=kids-test.qcow2,format=qcow2 \
  -cdrom debian-minimal-kids-amd64.hybrid.iso -boot d
```

Choisissez l'entrée **Install** du menu de démarrage. Une fois l'installation
terminée, relancez **sans `-cdrom`** pour démarrer le système installé.

## Scratch (via Flatpak)

Scratch n'est pas packagé dans Debian. Il est installé depuis Flathub pendant le
build par le hook `config/hooks/normal/0500-flatpak-scratch.hook.chroot` (le
paquet `flatpak` est déclaré dans `apps.list.chroot`).

> Contrepartie : Scratch tire un runtime GNOME volumineux (plusieurs centaines de
> Mo), ce qui **augmente la taille de l'ISO**. Les performances à l'usage restent
> correctes.

## Bureau XFCE par défaut

Le bureau livré par défaut est défini dans
`config/includes.chroot_after_packages/etc/skel/.config/xfce4/` :

- un **panneau horizontal en bas** (36 px), **semi-transparent** (teinte nuit
  à 55 % d'opacité via `background-rgba`) avec **texte blanc forcé par
  `~/.config/gtk-3.0/gtk.css`** — le fond d'écran reste visible tout en
  garantissant la lisibilité : bouton Menu, bureaux, liste des fenêtres,
  zone de notification, et une horloge affichant la date complète au format
  « 7 novembre 2026, 22h 29 » (`digital-time-format` = `%-d %B %Y, %Hh %M`,
  interprété par GLib) ;
- un **dock vertical à gauche** (48 px), centré, **transparent** et **ajusté à
  la taille de ses icônes**, avec six lanceurs, dans l'ordre : Firefox, Gedit,
  Scratch, Dessin, VLC, Thunar ;
- un **bouton Menu à globe violet** : le menu des applications du panneau
  affiche l'icône `kids-menu-globe` (SVG fourni dans
  `usr/share/icons/hicolor/scalable/apps/`, résolu via le thème de repli
  hicolor) accompagnée du libellé « Menu » (propriétés `button-icon` et
  `button-title` du plugin dans `xfce4-panel.xml`) ;
- un **bureau sans icônes** (fond d'écran seul) ;
- un **thème clair et chaleureux** : GTK **Yaru-magenta** (accent magenta,
  paquet `yaru-theme-gtk`), bordures de fenêtres **Yaru** (chrome neutre : les
  variantes colorées n'embarquent pas de bordures xfwm4), icônes
  **Yaru-magenta** (paquet `yaru-theme-icon`, dossiers magenta héritant du jeu
  Yaru complet) ;
- un **pointeur de souris** style bande dessinée, orange : **ComixCursors-Orange**
  (paquet `comixcursors-righthanded`, réglé dans `xsettings.xml` via
  `Gtk/CursorThemeName`) ;
- un **fond d'écran** doux (un chat endormi à la bougie), installé dans
  `/usr/share/backgrounds/debian-minimal-kids/wallpaper.jpg`.

La disposition des panneaux est décrite dans `xfce4-panel.xml`. Chaque lanceur
du dock a son fichier `.desktop` dans un sous-dossier dédié `panel/launcher-<id>/`
(le numéro `<id>` correspond au plugin dans `xfce4-panel.xml`, c'est l'endroit où
le panneau XFCE va chercher ses lanceurs). Le masquage des icônes du bureau est
réglé dans `xfce4-desktop.xml`, le thème GTK et les icônes dans `xsettings.xml`,
le thème des fenêtres dans `xfwm4.xml` (qui active aussi le compositeur
nécessaire à la transparence du dock).

Le **fond d'écran** mérite une explication. xfdesktop 4.20 range le fond choisi
sous une clé xfconf qui dépend du nom du connecteur réel du moniteur (`Virtual-1`
en QEMU, `eDP-1`/`HDMI-1` sur du matériel), impossible à figer dans un XML. Et
quand aucune image n'est définie, xfdesktop affiche son **image par défaut**
compilée, `DEFAULT_BACKDROP` = `/usr/share/backgrounds/xfce/xfce-x.svg` (fournie
par le paquet `xfdesktop4-data`), avec les styles par défaut *zoomé* +
*transparent*.

On s'appuie sur ce comportement, de deux façons complémentaires :

1. **Image par défaut remplacée** (mécanisme principal, infaillible) :
   `/usr/share/backgrounds/xfce/xfce-x.svg` est un **lien symbolique** vers notre
   image (`usr/share/backgrounds/xfce/xfce-x.svg` → `../debian-minimal-kids/wallpaper.jpg`).
   Dès lors, sans aucune clé xfconf ni course au démarrage, le bureau affiche
   notre chat — sur tous les moniteurs et toutes les résolutions (xfdesktop le
   charge par son contenu, l'extension `.svg` est sans importance). Le fond
   remplit l'écran en gardant les proportions (style *zoomé* par défaut).
2. **Script d'ouverture de session** (complément) :
   `/usr/local/bin/kids-set-wallpaper`, lancé via
   `~/.config/autostart/kids-set-wallpaper.desktop`, détecte les moniteurs
   connectés et pose explicitement la clé `last-image`. Intérêt : le choix est
   reflété dans l'outil « Bureau » de XFCE et **survit à une mise à jour** du
   paquet `xfdesktop4-data` (qui restaurerait sinon `xfce-x.svg`). Le script ne
   touche à rien si un fond a déjà été choisi, pour conserver les changements
   manuels sur un système installé (le mode « même fond sur tous les bureaux »
   est réglé dans `xfce4-desktop.xml`).

Le thème GTK et les icônes sont réglés dans `xsettings.xml`, le thème des
fenêtres dans `xfwm4.xml` (qui active aussi le compositeur nécessaire à la
transparence du dock), le masquage des icônes du bureau dans `xfce4-desktop.xml`.

Ces fichiers sont déposés dans `/etc/skel` : chaque nouvelle session — le live
comme un système fraîchement installé — hérite du même bureau. Pour ajuster le
rendu, le plus simple est de modifier le bureau graphiquement dans la session
live, puis de recopier `~/.config/xfce4/` modifié dans `etc/skel/` du dépôt.

## Optimisations système

Pour gagner en réactivité et économiser mémoire et CPU, sans ajouter de
complexité :

- **zram** (paquet `zram-tools`) : swap compressé **dans la RAM**. C'est
  l'optimisation la plus efficace sur les machines modestes : sous pression
  mémoire, le système compresse les pages inactives au lieu de ramer sur le
  disque. Configuré en **zstd** et **50 % de la RAM** (`etc/default/zramswap`),
  accompagné de `vm.swappiness = 100` et `vm.page-cluster = 0`
  (`etc/sysctl.d/99-kids-zram.conf`).
- **earlyoom** : si la mémoire est réellement saturée, il termine proprement
  le processus le plus gourmand (en pratique le navigateur) au lieu de laisser
  la machine se figer — un navigateur fermé se rouvre, une machine gelée
  réclame un redémarrage forcé.
- **ModemManager masqué** (hook `0510-kids-performance.hook.chroot`) : ce
  service — installé via les « Recommends » de NetworkManager — sonde
  périodiquement des modems 3G/4G absents de la machine cible. Le masquer
  économise ~10 Mo de RAM et des réveils CPU, sans impact sur le wifi ni
  l'Ethernet. Le même hook garantit que `zramswap` et `earlyoom` sont actifs.

Délibérément **non** installés : `preload` (bénéfice non prouvé, consomme
lui-même de la RAM), `irqbalance` (marginal sur 2-4 cœurs), TLP (batterie,
pas CPU/RAM). Le système étant déjà minimal, les vrais gros consommateurs
restent les applications elles-mêmes (Firefox, LibreOffice).

## Structure du projet

| Chemin | Rôle |
|--------|------|
| `auto/config` | Options de `lb config` figées => **build reproductible** (langue, clavier, utilisateur...) |
| `config/package-lists/live.list.chroot` | Composants minimaux du système live (généré) |
| `config/package-lists/locale.list.chroot` | Prise en charge du français (locale + clavier) |
| `config/package-lists/desktop.list.chroot` | Bureau XFCE + infrastructure (réseau, son) + thème (Yaru-magenta : GTK et icônes, curseurs Comix) + optimisations (zram, earlyoom) |
| `config/package-lists/apps.list.chroot` | Applications (ajoutées au fur et à mesure) |
| `config/package-lists/games.list.chroot` | Jeux |
| `config/includes.installer/preseed.cfg` | Préconfiguration de l'installateur (français par défaut) |
| `config/hooks/normal/0500-flatpak-scratch.hook.chroot` | Installe Scratch via Flatpak pendant le build |
| `config/hooks/normal/0510-kids-performance.hook.chroot` | Active zramswap + earlyoom, masque ModemManager |
| `config/includes.chroot_after_packages/etc/skel/` | Configuration XFCE par défaut (panneaux, lanceurs, thème, autostart) |
| `config/includes.chroot_after_packages/usr/share/backgrounds/debian-minimal-kids/` | Fond d'écran par défaut |
| `config/includes.chroot_after_packages/usr/share/icons/hicolor/scalable/apps/kids-menu-globe.svg` | Icône « globe violet » du bouton Menu |
| `config/includes.chroot_after_packages/etc/skel/.config/gtk-3.0/gtk.css` | Texte blanc + ombre sur le panneau XFCE (lisibilité sur fond transparent) |
| `config/includes.chroot_after_packages/etc/default/zramswap` | zram : compression zstd, taille = 50 % de la RAM |
| `config/includes.chroot_after_packages/etc/sysctl.d/99-kids-zram.conf` | `vm.swappiness` et `vm.page-cluster` accordés à zram |
| `config/includes.chroot_after_packages/usr/share/backgrounds/xfce/xfce-x.svg` | Lien vers notre fond : remplace l'image par défaut de xfdesktop |
| `config/includes.chroot_after_packages/usr/local/bin/kids-set-wallpaper` | Pose `last-image` sur chaque moniteur à l'ouverture de session (complément) |
| `build.sh` / `clean.sh` | Scripts pratiques |

## Réglages par défaut

| Paramètre | Valeur |
|-----------|--------|
| Langue (locale) | `fr_FR.UTF-8` |
| Clavier | `fr` (AZERTY) |
| Fuseau horaire | `Europe/Paris` |
| Utilisateur | `lisa` |
| Nom de machine | `kids-pc` |

Ces valeurs sont définies dans `auto/config` (paramètres `live-config.*`).

Le **français est également le défaut de l'installateur** (installation sur
disque) : langue, clavier AZERTY et fuseau Europe/Paris sont préconfigurés via
`config/includes.installer/preseed.cfg` et les paramètres de démarrage
`--bootappend-install` d'`auto/config`.

## Pour la suite

Quand le moment sera venu d'étoffer la distribution :

- **Applications** : les ajouter dans `config/package-lists/apps.list.chroot`,
  ou créer des listes thématiques (p. ex. `education.list.chroot`).
- **Réglages, thème, fond d'écran** : déposer ou modifier les fichiers dans
  `config/includes.chroot_after_packages/` (le thème clair et le fond d'écran y
  sont déjà en place, voir la section « Bureau XFCE par défaut »).
- **Personnalisation au démarrage, verrouillage parental** : ajouter des scripts
  dans `config/hooks/normal/`.
