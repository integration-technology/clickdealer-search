#!/usr/bin/env bash
# Runs the Clickdealer search scheduler as a background daemon

cd "$(dirname "$0")"

# Compile and start in detached mode
elixir --name clickdealer@localhost --detached -S mix run --no-halt

echo "Clickdealer search scheduler started in background"
echo "It will check every 30 minutes between 8am-6pm for registrations ending in SOU"
echo ""
echo "To stop: pkill -f 'clickdealer@localhost'"
echo "To view logs: tail -f _build/dev/lib/clickdealer_search/ebin/*.log"
