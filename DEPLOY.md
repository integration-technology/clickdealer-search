# Deployment Guide for Linux

This guide explains how to deploy the Clickdealer Search Monitor to a Linux server.

## Prerequisites

- Linux server (Ubuntu/Debian/CentOS/etc.)
- SSH access to the server
- Erlang/OTP installed on the build machine (your Mac)

## Step 1: Set Up WhatsApp Notifications

You have two options for WhatsApp notifications:

### Option A: CallMeBot (Free, Simple)

1. Save CallMeBot number to your contacts: +34 644 44 36 64
2. Send a WhatsApp message to that number with: `I allow callmebot to send me messages`
3. You'll receive an API key in response
4. Note your phone number (with country code, no + or spaces)
   - Example: UK number 07700900000 becomes 447700900000

### Option B: Twilio (More Reliable, Paid)

1. Sign up at https://www.twilio.com/
2. Get a Twilio WhatsApp-enabled number
3. Note your Account SID, Auth Token, and WhatsApp number
4. Your recipient number must be in format `whatsapp:+447700900000`

## Step 2: Build the Release

On your Mac (this machine), run:

```bash
cd /Users/owain/Dropbox/src/tries/2025-11-25-clickdealer-search
./deploy/build.sh
```

This creates a self-contained release that can run on any Linux x86_64 system.

## Step 3: Package for Deployment

Create a tarball:

```bash
cd _build/prod/rel/clickdealer_search
tar -czf ~/clickdealer-search.tar.gz .
```

## Step 4: Copy to Linux Server

Transfer the tarball to your server:

```bash
scp ~/clickdealer-search.tar.gz your-user@your-server:/tmp/
```

## Step 5: Install on Server

SSH into your server and run:

```bash
# Create application directory
sudo mkdir -p /opt/clickdealer-search
sudo chown $USER:$USER /opt/clickdealer-search

# Extract the release
cd /opt/clickdealer-search
tar -xzf /tmp/clickdealer-search.tar.gz

# Test it runs
./bin/clickdealer_search start
./bin/clickdealer_search stop
```

## Step 6: Configure systemd Service

Copy and configure the service file:

```bash
# Copy service file to your home directory first
scp deploy/clickdealer-search.service your-user@your-server:/tmp/
```

On the server, edit the service file:

```bash
sudo nano /tmp/clickdealer-search.service
```

Update these values:
- `User=YOUR_USERNAME` → your actual username
- `CALLMEBOT_PHONE=YOUR_PHONE_NUMBER` → your phone (e.g., 447700900000)
- `CALLMEBOT_API_KEY=YOUR_API_KEY` → your CallMeBot API key

Or if using Twilio, comment out CallMeBot lines and uncomment Twilio lines.

Install the service:

```bash
sudo cp /tmp/clickdealer-search.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable clickdealer-search
sudo systemctl start clickdealer-search
```

## Step 7: Verify It's Running

Check service status:

```bash
sudo systemctl status clickdealer-search
```

View logs:

```bash
# Real-time logs
sudo journalctl -u clickdealer-search -f

# Recent logs
sudo journalctl -u clickdealer-search -n 50
```

## Management Commands

```bash
# Start service
sudo systemctl start clickdealer-search

# Stop service
sudo systemctl stop clickdealer-search

# Restart service
sudo systemctl restart clickdealer-search

# View status
sudo systemctl status clickdealer-search

# View logs
sudo journalctl -u clickdealer-search -f
```

## Testing WhatsApp Notifications

You can test the notification manually by connecting to the running application:

```bash
/opt/clickdealer-search/bin/clickdealer_search remote

# In the console:
# Create a test match
test_match = %{"vrm" => %{"raw" => "ABC SOU"}, "year" => %{"raw" => 2020}, "mileage" => %{"raw" => "50,000"}, "price" => %{"raw" => 25000}}
ClickdealerSearch.Notifier.send_alert([test_match])

# Exit with Ctrl+C twice
```

## Updating the Application

When you make changes:

1. Rebuild on your Mac: `./deploy/build.sh`
2. Create new tarball
3. Copy to server
4. Stop service: `sudo systemctl stop clickdealer-search`
5. Extract new version to `/opt/clickdealer-search`
6. Start service: `sudo systemctl start clickdealer-search`

## Troubleshooting

### Service won't start
- Check logs: `sudo journalctl -u clickdealer-search -n 50`
- Verify permissions: `/opt/clickdealer-search` should be owned by the service user
- Check environment variables in service file

### WhatsApp not sending
- Check logs for error messages
- Verify API credentials are correct
- Test credentials manually using curl

### Application crashes
- Check logs: `sudo journalctl -u clickdealer-search`
- Verify Erlang is compatible (OTP 24+)
- Check network connectivity from server

## Configuration Changes

To change check frequency, registration pattern, or hours:

1. Edit `lib/clickdealer_search/scheduler.ex` on your Mac
2. Rebuild and redeploy following "Updating" steps above

Current settings:
- Check interval: 30 minutes
- Operating hours: 8am - 6pm UK time
- Target registration: Ends with "SOU"
