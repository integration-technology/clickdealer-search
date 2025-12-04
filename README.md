# Clickdealer Search Monitor

Monitors Clickdealer for Volvo XC90s with a registration ending in "SOU".

## Features

### Scheduler (Vehicle Search)
- Runs automatically every 30 minutes
- Only checks between 8am-6pm (UK time)
- Searches for Volvo XC90s with registration ending in "SOU"
- Sends WhatsApp notification when matching vehicle is found
- Logs all activity

### Car Monitor
- Monitors a specific car (ID: 7460084) for status changes
- Checks every 15 minutes
- Notifies via WhatsApp when:
  - Price changes
  - Mileage changes
  - Car becomes unavailable
- Uses OTP recursion (GenServer) for reliability

## Usage

### One-time search (interactive)
```bash
mix run -e "ClickdealerSearch.run()"
```

### Start as background daemon
```bash
./run_daemon.sh
```

The scheduler will:
- Check every 30 minutes for vehicles
- Only run during business hours (8am-6pm)
- Alert via macOS notification when a registration ending in "SOU" is found
- Log all checks and results

### Stop the daemon
```bash
pkill -f 'clickdealer@localhost'
```

### Manual control in IEx
```bash
iex -S mix

# Run a one-time search check
ClickdealerSearch.run()

# Check the status of your monitored car
ClickdealerSearch.CarMonitor.get_state()

# Manually trigger a car status check
ClickdealerSearch.CarMonitor.check_now()

# The scheduler and car monitor are already running in the background
# You can check the logs or wait for notifications
```

## Configuration

Edit `lib/clickdealer_search/scheduler.ex` to change:
- `@interval_ms` - Check frequency (default: 30 minutes)
- `@target_suffix` - Registration ending to search for (default: "SOU")
- `within_operating_hours?/0` - Time window for checks (default: 8am-6pm)

## Notifications

When a matching vehicle is found, you'll receive:
- A WhatsApp message with the registration and price (when deployed to Linux)
- A macOS system notification (when running locally - legacy)
- A log entry with full details (registration, year, mileage, price)

## Deploying to Linux Server

For production use on a Linux server (so it runs 24/7), see **[DEPLOY.md](DEPLOY.md)** for complete instructions.

Quick summary:
1. Set up WhatsApp notifications (CallMeBot or Twilio)
2. Build release: `./deploy/build.sh`
3. Deploy to Linux server
4. Install as systemd service

The Linux deployment includes:
- Systemd service for automatic startup
- WhatsApp notifications instead of macOS notifications
- Automatic restart on failure
- Centralized logging via journalctl

