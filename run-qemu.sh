#!/bin/sh
# =============================================================================
# run-qemu.sh — lance l'ISO dans QEMU avec le son activé.
#
# QEMU n'émule aucune carte son par défaut : on ajoute ici une carte Intel HDA
# (reconnue nativement par Linux) reliée au serveur audio de l'hôte (PipeWire,
# ou PulseAudio en repli — fourni par pipewire-pulse).
#
# Usage :
#   ./run-qemu.sh                  # démarre le live (son activé)
#   ./run-qemu.sh autre.iso        # sur une autre image
#   ./run-qemu.sh --install        # ajoute un disque de 20 Go pour tester l'install
# =============================================================================
set -e

ISO="debian-minimal-kids-amd64.hybrid.iso"
INSTALL=0
for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=1 ;;
        *.iso)     ISO="$arg" ;;
    esac
done

[ -f "$ISO" ] || { echo "ISO introuvable : $ISO" >&2; exit 1; }

# Backend audio : pipewire si disponible, sinon pulseaudio.
AUDIO=pipewire
qemu-system-x86_64 -audiodev help 2>/dev/null | grep -qw pipewire || AUDIO=pa

set -- -enable-kvm -m 2048 -smp 2 \
       -cdrom "$ISO" -boot d \
       -audiodev "${AUDIO},id=snd0" \
       -device ich9-intel-hda -device hda-duplex,audiodev=snd0

if [ "$INSTALL" -eq 1 ]; then
    DISK="kids-test.qcow2"
    [ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" 20G
    set -- "$@" -drive file="$DISK",format=qcow2
fi

exec qemu-system-x86_64 "$@"
