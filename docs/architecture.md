# Architecture Overview

## Detection Layer
- tcpdump packet sampling
- UDP-only filtering
- Sustained PPS logic

## Context Layer
- FiveM HTTP API
- Live player count
- Severity scoring

## Alerting Layer
- Discord Webhooks
- Role-based escalation
- Failure notifications

## Control Layer
- systemd lifecycle
- Resource isolation
- Auto-restart & crash recovery
