# --------- PHASE 1: BUILD SPT + FIKA ---------
FROM debian:bookworm AS build

# Basispakete + GPG für Node.js via asdf
RUN apt update && apt install -y --no-install-recommends \
    curl ca-certificates git git-lfs gpg bash dirmngr

# GPG-Schlüssel für Node.js (nötig für asdf)
RUN mkdir -p ~/.gnupg && chmod 700 ~/.gnupg && \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8F35498B981C4E2CBF8356F42E3D84A4C8AAC63C \
    C4F0DFFF4E8C1A8236409E44A985F95BFA621E52

# asdf + Node.js 20.11.1
ENV ASDF_DIR=/root/.asdf
ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:$PATH"
SHELL ["/bin/bash", "-c"]

RUN git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.1 && \
    source $ASDF_DIR/asdf.sh && \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git && \
    asdf install nodejs 20.11.1 && \
    asdf global nodejs 20.11.1

# Build SPT Server
ARG SPT_SERVER_SHA=3.11.3
ARG BUILD_TYPE=release

RUN git clone https://github.com/sp-tarkov/server.git /spt && \
    cd /spt/project && git checkout $SPT_SERVER_SHA && \
    git lfs install && git lfs pull && \
    npm install && npm run build:$BUILD_TYPE && \
    mv /spt/project/build /opt/build && rm -rf /spt

# --------- PHASE 2: HEADLESS AMP CONTAINER + RUNTIME ---------
FROM cubecoders/ampbase:xvfb

# Wine, Cron, etc. für Headless-Client
RUN dpkg --add-architecture i386 && \
    apt update && apt install -y --no-install-recommends \
    wine64 wine32 curl aria2 unzip jq cron vim && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Server-Files übernehmen
COPY --from=build /opt/build /opt/server

# Skripte einfügen (stellen sicher, dass diese im Repo vorhanden sind!)
COPY entrypoint.sh /usr/bin/entrypoint
COPY scripts/backup.sh /usr/bin/backup
COPY scripts/download_unzip_install_mods.sh /usr/bin/download_unzip_install_mods
COPY data/cron/cron_backup_spt /etc/cron.d/cron_backup_spt

# Berechtigungen
RUN chmod +x /usr/bin/entrypoint /usr/bin/backup /usr/bin/download_unzip_install_mods

# Port für Fika Server
EXPOSE 6969

# Startscript
ENTRYPOINT ["/usr/bin/entrypoint"]
