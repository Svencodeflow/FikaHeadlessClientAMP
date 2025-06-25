# --------- PHASE 1: BUILD SPT + FIKA ---------
FROM debian:bookworm AS build

# Basispakete inkl. git-lfs + bash
RUN apt update && apt install -y --no-install-recommends \
    curl ca-certificates git git-lfs bash dirmngr gpg

# ENV + Bash-Shell für asdf
ENV ASDF_DIR=/root/.asdf
ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:$PATH"
SHELL ["/bin/bash", "-c"]

# Installiere asdf & Node.js 20.11.1 (neueste Methode)
RUN git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.1 && \
    . "$ASDF_DIR/asdf.sh" && \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git && \
    bash $ASDF_DIR/plugins/nodejs/bin/import-release-team-keyring --no-tty && \
    asdf install nodejs 20.11.1 && \
    asdf global nodejs 20.11.1

# SPT Server bauen
ARG SPT_SERVER_SHA=3.11.3
ARG BUILD_TYPE=release

RUN git clone https://github.com/sp-tarkov/server.git /spt && \
    cd /spt/project && git checkout $SPT_SERVER_SHA && \
    git lfs install && git lfs pull && \
    npm install && npm run build:$BUILD_TYPE && \
    mv /spt/project/build /opt/build && rm -rf /spt

# --------- PHASE 2: HEADLESS AMP CONTAINER + RUNTIME ---------
FROM cubecoders/ampbase:xvfb

# Wine + Tools
RUN dpkg --add-architecture i386 && \
    apt update && apt install -y --no-install-recommends \
    wine64 wine32 curl aria2 unzip jq cron vim && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Serverfiles übernehmen
COPY --from=build /opt/build /opt/server

# Skripte einfügen (diese Dateien müssen im Repo sein!)
COPY entrypoint.sh /usr/bin/entrypoint
COPY scripts/backup.sh /usr/bin/backup
COPY scripts/download_unzip_install_mods.sh /usr/bin/download_unzip_install_mods
COPY data/cron/cron_backup_spt /etc/cron.d/cron_backup_spt

# Rechte setzen
RUN chmod +x /usr/bin/entrypoint /usr/bin/backup /usr/bin/download_unzip_install_mods

# SPT-Fika Port
EXPOSE 6969

# Einstiegspunkt
ENTRYPOINT ["/usr/bin/entrypoint"]
