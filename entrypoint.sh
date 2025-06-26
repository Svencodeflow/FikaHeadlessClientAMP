#!/bin/bash
set -e

client_dir=/tarkov
config_path="${CONFIG_PATH:-configs/yourheadlessconfig.json}"

# Aus AMP-UI gesetzte Umgebungsvariablen
server_url="${SERVER_URL:-127.0.0.1}"
server_port="${PORT:-6969}"
profile_id="${PROFILE_ID:-}"
https="${HTTPS:-true}"
use_modsync="${USE_MODSYNC:-false}"
disable_batchmode="${DISABLE_BATCHMODE:-false}"
disable_nodynamicai="${DISABLE_NODYNAMICAI:-false}"
auto_restart_on_raid_end="${AUTO_RESTART_ON_RAID_END:-false}"
esync="${ESYNC:-false}"
fsync="${FSYNC:-false}"
ntsync="${NTSYNC:-false}"
use_graphics="${USE_GRAPHICS:-false}"
xvfb_debug="${XVFB_DEBUG:-false}"

# WINE Performance-Optimierungen
export WINEESYNC=0
export WINEFSYNC=0
export WINENTSYNC=0
[[ "$esync" == "true" ]] && export WINEESYNC=1
[[ "$fsync" == "true" ]] && export WINEFSYNC=1
[[ "$ntsync" == "true" ]] && export WINENTSYNC=1

# Vor dem Start prüfen, ob alle nötigen Dateien vorhanden sind
if [[ ! -f "$client_dir/EscapeFromTarkov.exe" ]]; then
    echo "========================================================"
    echo "FEHLER: EscapeFromTarkov.exe nicht gefunden!"
    echo "Lade deinen vollständigen Tarkov-Client-Ordner per FTP nach:"
    echo "   $client_dir"
    echo "und starte dann die Instanz neu!"
    echo "========================================================"
    sleep 3600
    exit 1
fi

if [[ ! -f "$client_dir/BepInEx/plugins/Fika.Headless.Client.dll" ]]; then
    echo "========================================================"
    echo "FEHLER: Fika.Headless.Client.dll nicht gefunden!"
    echo "Kopiere sie in $client_dir/BepInEx/plugins/"
    echo "========================================================"
    sleep 3600
    exit 1
fi

if [[ ! -f "$client_dir/$config_path" ]]; then
    echo "========================================================"
    echo "WARNUNG: $config_path nicht gefunden!"
    echo "Lege deine Headless-Config dort ab!"
    echo "Beispiel siehe Fika-Wiki: https://project-fika.gitbook.io/wiki/advanced-features/headless-client"
    echo "========================================================"
    sleep 3600
    exit 1
fi

# Startparameter bauen
extra_args="-headless"
[[ "$disable_batchmode" != "true" ]] && extra_args="$extra_args -batchmode"
[[ "$use_graphics" != "true" ]] && extra_args="$extra_args -nographics"
extra_args="$extra_args --config \"$config_path\""
[[ -n "$server_url" ]] && extra_args="$extra_args --server $server_url"
[[ -n "$server_port" ]] && extra_args="$extra_args --port $server_port"
[[ -n "$profile_id" ]] && extra_args="$extra_args --profile $profile_id"
[[ "$disable_nodynamicai" == "true" ]] && extra_args="$extra_args --disable-nodynamicai"
[[ "$auto_restart_on_raid_end" == "true" ]] && extra_args="$extra_args --auto-restart"
[[ "$use_modsync" == "true" ]] && extra_args="$extra_args --modsync"
[[ "$https" == "false" ]] && extra_args="$extra_args --no-https"

xvfb_args="--auto-servernum --server-args='-screen 0 1024x768x16'"
[[ "$xvfb_debug" == "true" ]] && xvfb_args="$xvfb_args -verbose"

echo "Starte Headless Client:"
echo "wine64 EscapeFromTarkov.exe $extra_args"

cd "$client_dir"
eval xvfb-run $xvfb_args wine64 EscapeFromTarkov.exe $extra_args
