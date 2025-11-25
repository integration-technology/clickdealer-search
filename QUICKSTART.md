# Quick Start Guide

## TL;DR - Deploy to Linux in 5 Minutes

### 1. Get WhatsApp API Key (CallMeBot - Free)
```
1. Save +34 644 44 36 64 to contacts
2. Send WhatsApp: "I allow callmebot to send me messages"
3. Note the API key you receive
```

### 2. Build on Mac
```bash
./deploy/build.sh
cd _build/prod/rel/clickdealer_search
tar -czf ~/clickdealer-search.tar.gz .
```

### 3. Deploy to Server
```bash
# On Mac
scp ~/clickdealer-search.tar.gz user@server:/tmp/
scp deploy/clickdealer-search.service user@server:/tmp/

# On Server
sudo mkdir -p /opt/clickdealer-search
sudo chown $USER:$USER /opt/clickdealer-search
cd /opt/clickdealer-search
tar -xzf /tmp/clickdealer-search.tar.gz
```

### 4. Configure Service
```bash
# Edit service file
nano /tmp/clickdealer-search.service

# Change these lines:
User=YOUR_USERNAME                         # Your server username
CALLMEBOT_PHONE=YOUR_PHONE                 # e.g., 447700900000
CALLMEBOT_API_KEY=YOUR_KEY                 # From step 1

# Install
sudo cp /tmp/clickdealer-search.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable clickdealer-search
sudo systemctl start clickdealer-search
```

### 5. Verify
```bash
sudo systemctl status clickdealer-search
sudo journalctl -u clickdealer-search -f
```

You're done! You'll get WhatsApp alerts every time a car with registration ending in "SOU" appears.

## What It Does

- Searches Clickdealer every 30 minutes
- Only runs 8am-6pm UK time
- Sends WhatsApp when it finds registrations ending in "SOU"
- Runs 24/7 automatically via systemd

## For Full Details

See [DEPLOY.md](DEPLOY.md) for complete instructions, troubleshooting, and Twilio setup.
