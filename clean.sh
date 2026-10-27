#!/bin/sh
# -----------------------------------------------------------------------------
# Nettoie les artefacts de construction (chroot, binary, ISO...).
#
# Par défaut, le cache des paquets téléchargés est conservé pour accélérer
# les reconstructions. Pour tout supprimer, y compris le cache :
#     sudo lb clean --purge
# -----------------------------------------------------------------------------
set -e

sudo lb clean
