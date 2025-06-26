FROM debian:bookworm

RUN apt update && apt install -y --no-install-recommends \
    wine64 xvfb curl unzip jq && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 ampuser

COPY entrypoint.sh /usr/bin/entrypoint
RUN chmod +x /usr/bin/entrypoint

WORKDIR /tarkov

ENTRYPOINT ["/usr/bin/entrypoint"]
