# Tuning Guide

## PPS Thresholds
Small servers:
- CRITICAL_PPS: 6000–9000

Medium servers:
- CRITICAL_PPS: 12000–18000

Large servers:
- CRITICAL_PPS: 20000+

## Player Severity
Adjust escalation logic based on:
- Peak concurrent players
- RP sensitivity
- Event schedules

## Multi-Server
Add ports to:
```bash
FIVEM_PORTS=(30120 30121 30122)
