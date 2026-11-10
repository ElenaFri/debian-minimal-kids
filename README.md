# Kiddux

Système GNU/Linux minimaliste basé sur Debian 13 « trixie », pensé pour les
enfants : simplicité, autonomie et initiation à l'informatique.

Télécharger [ici](https://github.com/ElenaFri/debian-minimal-kids/releases/latest)
(ISO ~2,06 Gio, vérifiable avec `SHA256SUMS.txt`)
Il est à noter que la chrysalide est encore en pleine transformation vers le papillon, même si les mécanismes de base ont été implémentés.

Plus d'informations sur ce qui est à venir dans ma [« TODO list »](TODO.md). Vos retours sont précieux !

![Écran de démarrage](screenshots/default_boot_splash.png)

![Bureau par défaut](screenshots/default_desktop.png)

Applications : Firefox ESR, LibreOffice (texte, présentation), Gedit, Thunar,
VLC, Drawing, Galculator, qpdfview.
Jeux : Extreme Tux Racer, Luanti, Atomix, 2048, Swell Foop.

## Compatibilité

- PC 64 bits (amd64), BIOS ou UEFI avec Secure Boot ; ~2 Gio de RAM.
- Démarrage clé USB (image hybride) ou DVD. Essayer le mode live avant
  d'installer ; installation permanente via l'icône « Installer Kiddux » (Calamares).
- Non pris en charge : 32 bits, ARM (Raspberry Pi, Mac Apple Silicon) ; le
  matériel très récent et les anciennes puces WiFi Broadcom (b43) peuvent
  manquer de pilote.
- Test sans risque : machine virtuelle (voir `run-qemu.sh`).

## Construire

Prérequis : `live-build` et `debootstrap` (Debian, Ubuntu, LMDE...).

```bash
sudo apt install live-build debootstrap
./build.sh          # sudo lb build
./clean.sh          # repartir de zéro (garde le cache des paquets)
```

Résultat : `debian-minimal-kids-amd64.hybrid.iso`. Au démarrage du live, XFCE
en session automatique (`lisa` sur `kids-pc`), en français.

## Tester dans QEMU

Le son n'est pas émulé par défaut ; le script ajoute une carte Intel HDA reliée
à l'audio de l'hôte :

```bash
./run-qemu.sh              # live avec le son
./run-qemu.sh --install    # + disque de 20 Go pour tester l'installation
```

Commande équivalente, sur une seule ligne :

```bash
qemu-system-x86_64 -enable-kvm -m 2048 -smp 2 -cdrom debian-minimal-kids-amd64.hybrid.iso -boot d -audiodev pipewire,id=snd0 -device ich9-intel-hda -device hda-duplex,audiodev=snd0
```

## Le bureau

Toute la configuration vit dans `etc/skel/.config/` (via
`config/includes.chroot_after_packages/`), identique sur le live et le système
installé.

- Panneau du bas semi-transparent, texte blanc forcé (`gtk.css`) : bouton Menu
  (globe violet), bureaux, fenêtres, notifications et horloge « 7 novembre
  2026, 22h 29 » épinglées à droite.
- Dock vertical à gauche : Firefox, Gedit, Dessin, VLC, Thunar.
- Thème Yaru-magenta (GTK, icônes, bordures), pointeur ComixCursors-Orange,
  bureau épuré (seule l'icône « Installer Kiddux » sur le live).
- Fond d'écran « chat endormi à la bougie » en mode zoom : remplit l'écran à
  toute résolution, sans déformation.
- Splash Plymouth « kids » : icône sur tuile magenta, « debian 13 » en
  typographie Debian d'origine, adapté à toute résolution.
- Thunar en vue liste ; correcteur orthographique français actif partout.

Config XFCE : `xfce4-panel.xml` (panneaux, lanceurs dans `panel/launcher-<id>/`),
`xsettings.xml` (thème), `xfwm4.xml` (bordures, compositeur), `xfce4-desktop.xml`
(bureau). Le fond est posé par `kids-set-wallpaper` (autostart), xfdesktop 4.20
le rangeant sous une clé liée au connecteur du moniteur.

## Firefox

![Page Firefox par défaut](screenshots/default_firefox_start_page.png)

Configuré par `policies.json` (politiques) et `distribution.ini` (marque-pages).

- Marque-pages sur la barre personnelle : dossiers Vidéos (YouTube Kids, Disney+) et
  École (Khan Academy, Lumni, Scratch, 1jour1actu), Wikipédia en direct. Page
  d'accueil : Lumni.
- Moteur : Qwant Junior (verrouillé). Assistant IA : Le Chat Mistral.
- Thème Alpenglow appliqué au 1er lancement (AutoConfig `kids.cfg`).
- Allégé : télémétrie, études, comptes, mises à jour et navigation privée
  désactivés ; pas de page de bienvenue.

## Contrôle parental

1. DNS familial : un dnsmasq local force SafeSearch et le « Mode restreint »
   YouTube (commentaires et chat en direct masqués), puis transfère à OpenDNS
   FamilyShield (`99-kids-dns.conf`, `00-safe-search.conf`) ; DNS du DHCP
   ignorés, pas de contournement.
2. Firefox verrouillé : réseaux sociaux et sites de chat avec inconnus bloqués
   (`WebsiteFilter`), ajout d'extensions interdit, DoH et `about:config`
   désactivés, navigation privée coupée (historique consultable).
3. Couvre-feu : veille répétée de 21h30 à 7h00 (`kids-bedtime.*`, hook 0510).
   Réveiller la machine pendant cette plage la rendort dans la minute, la
   rendant inutilisable ; l'écran se verrouille à chaque réveil.
4. Comptes (système installé) : l'enfant a un compte sans droits
   d'administration (hors du groupe `sudo`) ; un mot de passe root distinct,
   choisi par le parent à l'installation, sert à administrer. L'enfant ne peut
   donc pas lever les protections ci-dessus. Le live n'est pas concerné.

Régler la plage : lignes `OnCalendar` du timer, puis `systemctl daemon-reload &&
systemctl restart kids-bedtime.timer`. Désactiver : `systemctl disable --now
kids-bedtime.timer`. Sur le système installé, lancer ces commandes en root
(`su -`, mot de passe du parent) ; sur le live, les préfixer de `sudo`. Le
couvre-feu est aussi actif sur le live : pour tester le soir, désactive-le
d'abord.

## Optimisations

- zram (zstd, 50 % RAM) + earlyoom, `vm.swappiness = 100` ; ModemManager et
  NM-wait-online masqués (hook 0510).
- Squashfs zstd niveau 22, menu GRUB UEFI à 3 s (hook 0520), `GRUB_TIMEOUT = 1`
  une fois installé.
- ISO allégée (hook 0540) : agent polkit léger (lxpolkit) sans la chaîne
  OpenCV/GDAL, PDF via qpdfview au lieu d'atril/yelp (pas de WebKitGTK),
  variantes de thèmes/curseurs et traductions superflues purgées, caches
  apt-file/xapian/plocate non construits.

## Structure du projet

| Chemin | Rôle |
|--------|------|
| `auto/config` | Options `lb config` figées |
| `config/package-lists/*.list.chroot` | Paquets : live, locale FR, bureau, applications, jeux, installateur Calamares |
| `config/includes.chroot_after_packages/etc/calamares/` | Branding Kiddux et réglages de l'installateur Calamares |
| `config/hooks/normal/0510-kids-performance.hook.chroot` | zram, earlyoom, couvre-feu ; services inutiles masqués |
| `config/hooks/normal/0520-grub-timeout.binary` | Menu GRUB UEFI : 3 s |
| `config/hooks/normal/0530-dconf-defaults.hook.chroot` | Compile les défauts dconf |
| `config/hooks/normal/0540-kids-slim.hook.chroot` | Allège l'image (agent polkit léger, thèmes/curseurs et traductions superflus) |
| `config/hooks/normal/0550-plymouth-theme.hook.chroot` | Embarque le thème Plymouth dans l'initramfs |
| `config/includes.chroot_after_packages/` | DNS, politiques/marque-pages/thème Firefox, Plymouth, dconf, skel XFCE, fond d'écran |
| `build.sh` / `clean.sh` / `run-qemu.sh` | Scripts pratiques (build, nettoyage, test QEMU avec son) |

## Réglages par défaut

| Paramètre | Valeur |
|-----------|--------|
| Langue / clavier | `fr_FR.UTF-8` / `fr` (AZERTY) |
| Fuseau | `Europe/Paris` |
| Utilisateur / machine | `lisa` / `kids-pc` |

Définis dans `auto/config`. Installation sur disque via Calamares (icône
« Installer Kiddux » sur le bureau du live) ; le système installé hérite du
français, du clavier AZERTY et du splash Plymouth.
