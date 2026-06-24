#!/usr/bin/env bash
# Démarre l'émulateur Android en headless, attend son boot complet,
# puis lance le serveur Appium. Utilisé comme CMD de l'image.
#
# ⚠️ L'émulateur exige /dev/kvm : ce script ne fonctionne que sur un hôte
# Linux avec virtualisation imbriquée (nœud GKE). Le build de l'image, lui,
# marche partout (ce script n'est pas exécuté au build).
set -euo pipefail

EMULATOR_NAME="${EMULATOR_NAME:-trusker_pixel5}"
APPIUM_PORT="${APPIUM_PORT:-4723}"

echo "==> Vérification de /dev/kvm"
if [ ! -e /dev/kvm ]; then
  echo "ERREUR: /dev/kvm absent. L'émulateur ne peut pas démarrer sans KVM." >&2
  echo "        Lance ce conteneur sur un hôte Linux avec virtualisation imbriquée." >&2
  exit 1
fi

echo "==> Démarrage du serveur ADB"
adb start-server

echo "==> Lancement de l'émulateur '${EMULATOR_NAME}' (headless)"
emulator -avd "${EMULATOR_NAME}" \
  -no-window -no-audio -no-boot-anim \
  -gpu swiftshader_indirect \
  -no-snapshot -accel on -wipe-data &

echo "==> Attente du device puis du boot complet..."
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  sleep 2
done
echo "==> Émulateur prêt."

echo "==> Démarrage d'Appium sur 0.0.0.0:${APPIUM_PORT}"
exec appium --address 0.0.0.0 --port "${APPIUM_PORT}" --relaxed-security
