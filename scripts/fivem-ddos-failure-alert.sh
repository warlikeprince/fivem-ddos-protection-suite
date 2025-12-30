#!/bin/bash

WEBHOOK_URL="PUT_DISCORD_WEBHOOK_URL_HERE"
HOST=$(hostname)
TIME=$(date '+%F %T')

curl -s -H "Content-Type: application/json" -X POST -d "{
  \"embeds\": [{
    \"title\": \"⚠️ FiveM DDoS Monitor Failed\",
    \"color\": 16753920,
    \"fields\": [
      { \"name\": \"Host\", \"value\": \"$HOST\", \"inline\": true },
      { \"name\": \"Time\", \"value\": \"$TIME\", \"inline\": false }
    ]
  }]
}" "$WEBHOOK_URL" >/dev/null
