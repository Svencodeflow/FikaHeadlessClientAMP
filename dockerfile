# Phase 1: SPT + Fika bauen
FROM debian:bookworm AS build

RUN apt update && apt install -y --no-install-recommends \
    curl ca-certificates git git-lfs

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
ENV PATH="$PATH:/root/.asdf/bin:/root/.asdf/shims"
RUN . "$HOME/.asdf/asdf.sh" && \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git && \
    asdf install nodejs 20.11.1 && \
    asdf global nodejs 20.11.1

ARG SPT_SERVER_SHA=3.11.3
ARG BUILD_TYPE=release
RUN git clone https://github.com/sp-tarkov/server.git /spt && \
    cd /spt/project && git checkout $SPT_SERVER_SHA && git lfs pull && \
    npm install && npm run build:$BUILD_TYPE && \
    mv /spt/project/build /opt/build && rm -rf /spt

# Phase 2: Laufzeitumgebung
FROM cubecoders/ampbase:xvfb

# Wine & Tools
RUN dpkg --add-architecture i386 && \
    apt update && apt install -y --no-install-recommends \
    wine64 wine32 curl aria2 unzip jq cron vim && \
    apt clean && rm -rf /var/lib/apt/lists/*

# SPT+Fika-Server (aus Build-Phase)
COPY --from=build /opt/build /opt/server

# Skripte hinzufügen
COPY entrypoint.sh /usr/bin/entrypoint
COPY scripts/backup.sh /usr/bin/backup
COPY scripts/download_unzip_install_mods.sh /usr/bin/download_unzip_install_mods
COPY data/cron/cron_backup_spt /etc/cron.d/cron_backup_spt

# Mods können in diesem Skript geladen werden
RUN chmod +x /usr/bin/entrypoint /usr/bin/backup /usr/bin/download_unzip_install_mods

EXPOSE 6969

ENTRYPOINT ["/usr/bin/entrypoint"]
