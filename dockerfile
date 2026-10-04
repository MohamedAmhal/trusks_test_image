# Image émulateur Android + Appium — implémentation maison (from scratch).
#
# Construit une image autonome contenant : Android SDK, un émulateur Android
# (API 33 / Android 13), un AVD Pixel 5, le serveur Appium et le driver
# UIAutomator2. Utilisée par les tests e2e mobiles (trusk-automation) dans Argo.
# this is a test
# ⚠️ L'ÉMULATEUR exige /dev/kvm → ne démarre que sur un hôte Linux avec
# virtualisation imbriquée (nœud GKE). Le BUILD fonctionne partout
# (on n'exécute pas l'émulateur pendant le build).
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Paris \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_HOME=/opt/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# --- Dépendances système + libs requises par l'émulateur headless ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jdk-headless \
        wget unzip curl ca-certificates \
        libpulse0 libgl1 libnss3 libxcursor1 libxcomposite1 libxi6 \
        libasound2 libdbus-1-3 libx11-6 libxtst6 \
    && rm -rf /var/lib/apt/lists/*

# --- Node.js 20 + Appium 2 + driver UIAutomator2 ---
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g appium@2.19.0 \
    && appium driver install uiautomator2@2.45.1 \
    && rm -rf /var/lib/apt/lists/*

# --- Android SDK : command-line tools ---
ARG CMDLINE_TOOLS_VERSION=11076708
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator

# --- Paquets SDK : platform-tools, emulator, plateforme + system image API 33 ---
ARG ANDROID_API=33
ARG SYSTEM_IMAGE="system-images;android-33;google_apis;x86_64"
RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager --install \
        "platform-tools" \
        "emulator" \
        "platforms;android-${ANDROID_API}" \
        "${SYSTEM_IMAGE}" > /dev/null

# --- Création de l'AVD (Pixel 5, API 33) ---
RUN echo "no" | avdmanager create avd \
        --force \
        --name trusker_pixel5 \
        --package "${SYSTEM_IMAGE}" \
        --device "pixel_5"

# --- Script de démarrage : émulateur (headless) -> attente boot -> Appium ---
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 4723
CMD ["/usr/local/bin/start.sh"]
