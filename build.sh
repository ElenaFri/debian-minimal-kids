#!/bin/sh
# -----------------------------------------------------------------------------
# Construit l'image ISO debian-minimal-kids.
#
# « lb build » télécharge les paquets Debian et assemble le système ;
# cela nécessite les droits root et une connexion internet.
# Le journal complet est enregistré dans build.log (ignoré par Git).
# -----------------------------------------------------------------------------
set -e

sudo lb build 2>&1 | tee build.log
