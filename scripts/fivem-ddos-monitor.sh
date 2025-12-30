#!/bin/bash
####################################################
# FiveM DDoS Monitor – Production
####################################################

INTERFACE="eth0"
FIVEM_PORTS=(30120 30121)
FIVEM_HOST="127.0.0.1"
FIVEM_HTTP_PORT=30120

SERVER_NAME="NovaTech RP"
PROVIDER_NAME="Galaxy Gate Hosting"

WEBHOOK_URL="PUT_DISCORD_WEBHOOK_URL_HERE"

STAFF_ROLE_ID="PUT_STAFF_ROLE_ID"
OWNER_ROLE_ID="PUT_OWNER_ROLE_ID"

CRITICAL_PPS=15000
SUSTAIN_SECONDS=5
ALERT_COOLDOWN=300

DUMP_DIR="/root/dumps"
LOG_FILE="/var/log/fivem-ddos.log"
LOCK_FILE="/tmp/fivem-ddos.lock"

mkdir -p "$DUMP_DIR"
touch "$LOG_FILE"

log() {
  echo "[$(date '+%F %T')] $1" >> "$LOG_FILE"
}

get_pps() {
  total=0
  for PORT in "${FIVEM_PORTS[@]}"; do
    count=$(tcpdump -n -i "$INTERFACE" udp port "$PORT" -c 1000 2>/dev/null | wc -l)
    total=$((total + count))
  done
  echo "$total"
}

get_players() {
  curl -s --max-time 2 http://$FIVEM_HOST:$FIVEM_HTTP_PORT/players.json \
    | jq length 2>/dev/null || echo 0
}

fivem_online() {
  curl -s --max-time 2 http://$FIVEM_HOST:$FIVEM_HTTP_PORT/info.json \
    | jq -e . >/dev/null 2>&1
}

cooldown_active() {
  [[ -f "$LOCK_FILE" ]] && (( $(date +%s) - $(cat "$LOCK_FILE") < ALERT_COOLDOWN ))
}

set_cooldown() {
  date +%s > "$LOCK_FILE"
}

send_discord() {
  curl -s -H "Content-Type: application/json" -X POST -d "$1" "$WEBHOOK_URL" >/dev/null
}

log "FiveM DDoS Monitor started"

while true; do
  sustained=0
  peak_pps=0

  for ((i=1;i<=SUSTAIN_SECONDS;i++)); do
    PPS=$(get_pps)
    (( PPS > peak_pps )) && peak_pps=$PPS
    (( PPS >= CRITICAL_PPS )) && sustained=$((sustained + 1))
    sleep 1
  done

  PLAYERS=$(get_players)

  if (( sustained == SUSTAIN_SECONDS )) && fivem_online && ! cooldown_active; then
    set_cooldown

    if (( PLAYERS >= 40 )); then
      SEVERITY="High – Live RP Impact"
      MENTION="<@&$OWNER_ROLE_ID>"
    else
      SEVERITY="Moderate – Staff Awareness"
      MENTION="<@&$STAFF_ROLE_ID>"
    fi

    ATTACK_JSON=$(cat <<EOF
{
  "content": "$MENTION",
  "embeds": [{
    "title": "🚨 DDoS Attack Detected – FiveM",
    "color": 15158332,
    "fields": [
      { "name": "Server", "value": "$SERVER_NAME", "inline": true },
      { "name": "Players", "value": "$PLAYERS", "inline": true },
      { "name": "Ports", "value": "${FIVEM_PORTS[*]}", "inline": true },
      { "name": "Peak PPS", "value": "$peak_pps", "inline": true },
      { "name": "Severity", "value": "$SEVERITY", "inline": false }
    ],
    "footer": { "text": "NovaTech FiveM Security" }
  }]
}
EOF
)
    send_discord "$ATTACK_JSON"

    tcpdump -i "$INTERFACE" udp port ${FIVEM_PORTS[0]} \
      -c 3000 -w "$DUMP_DIR/fivem_attack_$(date +%F_%T).pcap" 2>/dev/null &

    sleep 120

    RESOLVED_JSON=$(cat <<EOF
{
  "embeds": [{
    "title": "✅ Attack Mitigated",
    "color": 3066993,
    "fields": [
      { "name": "Server", "value": "$SERVER_NAME", "inline": true },
      { "name": "Peak PPS", "value": "$peak_pps", "inline": true },
      { "name": "Status", "value": "Normal Traffic", "inline": false }
    ]
  }]
}
EOF
)
    send_discord "$RESOLVED_JSON"
  fi

  sleep 5
done
