FROM node:22-alpine

# Install the MCP Inspector globally
RUN npm install -g @modelcontextprotocol/inspector@latest

# Both candidate seed configs for the inspector's writable server catalog
# ship in the image; inspector-entrypoint.sh decides which one to install at
# container start (based on the ADD_MORE_MCP_SERVERS env var), not here —
# so switching between them only needs a restart, not a rebuild.
COPY inspector-mcp-config-minimal.json /opt/inspector-configs/minimal.json
COPY inspector-mcp-config-full.json /opt/inspector-configs/full.json
COPY inspector-entrypoint.sh /usr/local/bin/inspector-entrypoint.sh
RUN chmod +x /usr/local/bin/inspector-entrypoint.sh

# Web UI (6274) and MCP Apps sandbox (6275). Actual bind address is
# controlled by the HOST / DANGEROUSLY_BIND_ALL_INTERFACES env vars set in
# docker-compose.yaml, not by a CLI flag.
EXPOSE 6274 6275

ENTRYPOINT ["/usr/local/bin/inspector-entrypoint.sh"]

CMD ["--web"]
