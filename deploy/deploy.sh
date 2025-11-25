#!/usr/bin/env bash
set -e

# Automated deployment script for Clickdealer Search Monitor
# Usage: ./deploy/deploy.sh user@hostname

if [ -z "$1" ]; then
  echo "Usage: $0 user@hostname"
  echo "Example: $0 myuser@example.com"
  exit 1
fi

SERVER=$1
RELEASE_TAR="/tmp/clickdealer-search.tar.gz"

echo "🚀 Deploying Clickdealer Search Monitor to $SERVER"
echo ""

# Build the release
echo "📦 Building release..."
./deploy/build.sh

# Create tarball
echo ""
echo "📦 Creating deployment package..."
cd _build/prod/rel/clickdealer_search
tar -czf "$RELEASE_TAR" .
cd - > /dev/null

# Copy files to server
echo ""
echo "📤 Copying files to server..."
scp "$RELEASE_TAR" "$SERVER:/tmp/"
scp deploy/clickdealer-search.service "$SERVER:/tmp/"

echo ""
echo "✅ Files copied successfully!"
echo ""
echo "📋 Next steps on the server:"
echo ""
echo "  1. SSH into server:"
echo "     ssh $SERVER"
echo ""
echo "  2. Extract application:"
echo "     sudo mkdir -p /opt/clickdealer-search"
echo "     sudo chown \$USER:\$USER /opt/clickdealer-search"
echo "     cd /opt/clickdealer-search"
echo "     tar -xzf /tmp/clickdealer-search.tar.gz"
echo ""
echo "  3. Configure and install service:"
echo "     nano /tmp/clickdealer-search.service  # Edit credentials"
echo "     sudo cp /tmp/clickdealer-search.service /etc/systemd/system/"
echo "     sudo systemctl daemon-reload"
echo "     sudo systemctl enable clickdealer-search"
echo "     sudo systemctl start clickdealer-search"
echo ""
echo "  4. Verify:"
echo "     sudo systemctl status clickdealer-search"
echo ""
echo "See QUICKSTART.md or DEPLOY.md for detailed instructions"
