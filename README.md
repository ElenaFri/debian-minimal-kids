# debian-minimal-kids

Un système GNU/Linux minimaliste basé sur Debian, pensé pour les enfants :
simplicité, autonomie et informatique intentionnelle. Moins de superflu, plus
d'exploration.

Construit avec [`live-build`](https://wiki.debian.org/DebianLive) à partir de
**Debian 13 « trixie »** (stable).

> État actuel : **base Debian fonctionnelle avec bureau XFCE**, en **français**,
> mais **sans aucune application utilisateur**. Les logiciels (navigateur,
> éducatif, jeux...) seront ajoutés plus tard, au fur et à mesure des choix du
> projet.

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

## Structure du projet

| Chemin | Rôle |
|--------|------|
| `auto/config` | Options de `lb config` figées → **build reproductible** (langue, clavier, utilisateur...) |
| `config/package-lists/live.list.chroot` | Composants minimaux du système live (généré) |
| `config/package-lists/locale.list.chroot` | Prise en charge du français (locale + clavier) |
| `config/package-lists/desktop.list.chroot` | Bureau XFCE + infrastructure (réseau, son) |
| `config/includes.installer/preseed.cfg` | Préconfiguration de l'installateur (français par défaut) |
| `config/hooks/` | Scripts de personnalisation (à venir) |
| `config/includes.chroot_*/` | Fichiers à injecter dans le système (à venir) |
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

- **Applications** : créer des listes dans `config/package-lists/`
  (une liste par thème, p. ex. `education.list.chroot`, `jeux.list.chroot`).
- **Réglages, thème, fond d'écran** : déposer les fichiers dans
  `config/includes.chroot_after_packages/`.
- **Personnalisation au démarrage, verrouillage parental** : ajouter des scripts
  dans `config/hooks/normal/`.
