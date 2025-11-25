#!/usr/bin/env bash
set -e

echo "Building Clickdealer Search release..."

# Clean previous builds
rm -rf _build/prod

# Get dependencies
MIX_ENV=prod mix deps.get --only prod

# Compile
MIX_ENV=prod mix compile

# Build release
MIX_ENV=prod mix release

echo ""
echo "✅ Build complete!"
echo ""
echo "Release created at: _build/prod/rel/clickdealer_search"
echo ""
echo "To create a deployment tarball:"
echo "  cd _build/prod/rel/clickdealer_search"
echo "  tar -czf ~/clickdealer-search.tar.gz ."
echo ""
echo "Then copy to your Linux server and follow DEPLOY.md instructions"
