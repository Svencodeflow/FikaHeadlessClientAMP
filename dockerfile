FROM cubecoders/ampbase:xvfb

# Optional: Debug-Zeile zur Basisprüfung
RUN echo "Building Fika Headless Image"

# Wine installieren (inkl. 32-Bit)
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --install-recommends wine64 wine32 xvfb winetricks && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Start-Skript bleibt AMP-konform
ENTRYPOINT ["/ampstart.sh"]
CMD []
