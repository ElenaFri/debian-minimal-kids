#!/bin/sh
# =============================================================================
# run-qemu.sh — lance Kiddux dans QEMU avec le son activé.
#
# QEMU n'émule aucune carte son par défaut : on ajoute ici une carte Intel HDA
# (reconnue nativement par Linux) reliée au serveur audio de l'hôte (PipeWire,
# ou PulseAudio en repli — fourni par pipewire-pulse).
#
# Usage :
#   ./run-qemu.sh                  # démarre le live (son activé)
#   ./run-qemu.sh autre.iso        # sur une autre image
#   ./run-qemu.sh --install        # live + disque de 20 Go pour tester l'install
#   ./run-qemu.sh --installed      # démarre le système déjà installé sur le disque
# =============================================================================
set -e

ISO="debian-minimal-kids-amd64.hybrid.iso"
DISK="kids-test.qcow2"
INSTALL=0
INSTALLED=0
for arg in "$@"; do
    case "$arg" in
        --install)   INSTALL=1 ;;
        --installed) INSTALLED=1 ;;
        *.iso)       ISO="$arg" ;;
    esac
done

# Backend audio : pipewire si disponible, sinon pulseaudio.
AUDIO=pipewire
qemu-system-x86_64 -audiodev help 2>/dev/null | grep -qw pipewire || AUDIO=pa

# Options communes : mémoire, cœurs, carte son.
set -- -enable-kvm -m 2048 -smp 2 \
       -audiodev "${AUDIO},id=snd0" \
       -device ich9-intel-hda -device hda-duplex,audiodev=snd0

if [ "$INSTALLED" -eq 1 ]; then
    # Démarrer le système déjà installé : disque uniquement, sans CD.
    [ -f "$DISK" ] || { echo "Disque introuvable : $DISK (lance d'abord ./run-qemu.sh --install)" >&2; exit 1; }
    set -- "$@" -drive file="$DISK",format=qcow2 -boot c
else
    # Démarrer le live depuis l'ISO.
    [ -f "$ISO" ] || { echo "ISO introuvable : $ISO" >&2; exit 1; }
    set -- "$@" -cdrom "$ISO" -boot d
    if [ "$INSTALL" -eq 1 ]; then
        # Disque cible pour tester l'installation (créé une seule fois).
        [ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" 20G
        set -- "$@" -drive file="$DISK",format=qcow2
    fi
fi

exec qemu-system-x86_64 "$@"
