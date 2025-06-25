# --------- PHASE 1: BUILD SPT + FIKA ---------
FROM debian:bookworm AS build

# Systempakete für Build
RUN apt update && apt install -y --no-install-recommends \
    curl ca-certificates git git-lfs bash gpg dirmngr gnupg unzip

# asdf + Node.js 20
ENV ASDF_DIR=/root/.asdf
ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:$PATH"
SHELL ["/bin/bash", "-c"]

RUN git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.1 && \
    . "$ASDF_DIR/asdf.sh" && \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git && \
    asdf install nodejs 20.11.1 && \
    asdf global nodejs 20.11.1

# SPT Build
ARG SPT_SERVER_SHA=3.11.3
ARG BUILD_TYPE=release

RUN git clone https://github.com/sp-tarkov/server.git /spt && \
    cd /spt/project && git checkout $SPT_SERVER_SHA && \
    git lfs install && git lfs pull && \
    npm install && npm run build:$BUILD_TYPE && \
    mv /spt/project/build /opt/build && rm -rf /spt

# --------- PHASE 2: HEADLESS AMP CONTAINER ---------
FROM cubecoders/ampbase:xvfb

# Tools für Fika & Wine
RUN dpkg --add-architecture i386 && \
    apt update && apt install -y --no-install-recommends \
    wine64 wine32 curl aria2 unzip jq cron vim && \
    apt clean && rm -rf /var/lib/apt/lists/*

# SPT+Fika vom Build übernehmen
COPY --from=build /opt/build /opt/server

# Skripte und Cronjobs (Pfad muss im Repo existieren)
COPY entrypoint.sh /usr/bin/entrypoint
COPY scripts/backup.sh /usr/bin/backup
COPY scripts/download_unzip_install_mods.sh /usr/bin/download_unzip_install_mods
COPY data/cron/cron_backup_spt /etc/cron.d/cron_backup_spt

# Rechte setzen
RUN chmod +x /usr/bin/entrypoint /usr/bin/backup /usr/bin/download_unzip_install_mods

# Fika Port
EXPOSE 6969

# Start des Servers
ENTRYPOINT ["/usr/bin/entrypoint"]
