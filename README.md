# trusk-android-emulator

Image Docker **émulateur Android + Appium** (implémentation maison, *from
scratch*) utilisée par les tests end-to-end mobiles (`trusk-automation`) dans
les workflows Argo sur GKE.

## Contenu de l'image

Construite depuis `ubuntu:22.04`, elle embarque :

- **Android SDK** (command-line tools)
- **Émulateur Android** API 33 / Android 13, AVD **Pixel 5** (`trusker_pixel5`)
- Serveur **Appium 2** (port `4723`) + driver **UIAutomator2**
- Script de démarrage [`start.sh`](./start.sh) : lance l'émulateur en headless,
  attend le boot complet, puis démarre Appium.

## ⚠️ Contrainte d'exécution (importante)

L'émulateur exige **`/dev/kvm`** → il ne démarre que sur un hôte **Linux avec
virtualisation imbriquée** (nœud GKE). Sur **macOS / Apple Silicon**, KVM est
indisponible (pas de nested virt) : le *build* de l'image fonctionne, mais
l'émulateur **ne peut pas booter** localement. C'est attendu, pas un bug.

## Build local (valide le Dockerfile)

```bash
docker build --platform linux/amd64 -t trusk-android-emulator:local .
```

## Exécution (uniquement sur hôte Linux + KVM)

```bash
docker run -d --device /dev/kvm -p 4723:4723 trusk-android-emulator:local
# puis pointer les tests Appium sur localhost:4723
```

## Publication

Push sur `master` → le workflow [`.github/workflows/cd.yaml`](./.github/workflows/cd.yaml)
build l'image et la publie dans l'Artifact Registry Trusk (convention
« 1 repo = 1 image »).
