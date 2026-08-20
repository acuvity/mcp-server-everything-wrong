#!/bin/sh
set -e

CONFIG_DIR="/root/.mcp-inspector"
CONFIG_FILE="$CONFIG_DIR/mcp.json"

mkdir -p "$CONFIG_DIR"

# Only seed on a fresh catalog — never clobber servers added/edited from the
# UI on a container restart (or a mounted volume carrying prior state).
if [ ! -f "$CONFIG_FILE" ]; then
  if [ "$ADD_MORE_MCP_SERVERS" = "true" ]; then
    cp /opt/inspector-configs/full.json "$CONFIG_FILE"
  else
    cp /opt/inspector-configs/minimal.json "$CONFIG_FILE"
  fi
fi

exec npx @modelcontextprotocol/inspector "$@"
