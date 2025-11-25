# Project Overview

## What This Does

Monitors Clickdealer for Volvo XC90s with registration ending in "SOU" (your old car being resold). Checks every 30 minutes between 8am-6pm and sends WhatsApp alerts when found.

## Quick Commands

### Local Development (macOS)
```bash
# One-time search
mix run -e "ClickdealerSearch.run()"

# Start with scheduler (uses macOS notifications)
iex -S mix
```

### Deploy to Linux
```bash
# Automated deployment
./deploy/deploy.sh user@yourserver.com

# Manual build only
./deploy/build.sh
```

## Project Structure

### Core Application
- `lib/clickdealer_search/application.ex` - OTP application supervisor
- `lib/clickdealer_search/search.ex` - API client for Clickdealer
- `lib/clickdealer_search/scheduler.ex` - 30-minute periodic scheduler
- `lib/clickdealer_search/notifier.ex` - WhatsApp notification handler

### Configuration
- `mix.exs` - Project config with release settings
- `deploy/clickdealer-search.service` - systemd service template

### Deployment
- `deploy/build.sh` - Builds production release
- `deploy/deploy.sh` - Automated deployment to server
- `run_daemon.sh` - Run as daemon on macOS (legacy)

### Documentation
- `README.md` - Main documentation
- `QUICKSTART.md` - 5-minute deployment guide
- `DEPLOY.md` - Complete deployment instructions
- `OVERVIEW.md` - This file

## Features

✅ Automatic scheduling (every 30 minutes)
✅ Time-based operation (8am-6pm only)
✅ WhatsApp notifications via CallMeBot or Twilio
✅ Systemd integration for Linux
✅ Self-contained release (no Erlang needed on server)
✅ Automatic restart on failure
✅ Centralized logging

## Configuration Options

All via environment variables (set in systemd service file):

### Required
- `NOTIFIER_TYPE` - "callmebot" or "twilio"
- For CallMeBot:
  - `CALLMEBOT_PHONE` - Your phone (e.g., 447700900000)
  - `CALLMEBOT_API_KEY` - API key from CallMeBot
- For Twilio:
  - `TWILIO_ACCOUNT_SID`
  - `TWILIO_AUTH_TOKEN`
  - `TWILIO_WHATSAPP_FROM`
  - `WHATSAPP_TO`

### Optional (change in code)
- Check interval: Edit `@interval_ms` in `scheduler.ex`
- Operating hours: Edit `within_operating_hours?/0` in `scheduler.ex`
- Target registration: Edit `@target_suffix` in `scheduler.ex`

## Technology Stack

- **Elixir 1.19** - Main language
- **OTP/BEAM** - Runtime and process supervision
- **HTTPoison** - HTTP client for API calls
- **Jason** - JSON parsing
- **systemd** - Linux service management

## Next Steps

1. **First Time Setup**: Follow [QUICKSTART.md](QUICKSTART.md)
2. **Detailed Instructions**: See [DEPLOY.md](DEPLOY.md)
3. **Customization**: Edit `lib/clickdealer_search/scheduler.ex`

## Support

Check the documentation:
- Quick start: `QUICKSTART.md`
- Full deployment: `DEPLOY.md`
- Troubleshooting: See "Troubleshooting" section in `DEPLOY.md`
