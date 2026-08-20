FROM node:22-alpine

# Install the MCP Inspector globally
RUN npm install -g @modelcontextprotocol/inspector@latest

# Seed the inspector's writable server catalog so mcp-server-everything-wrong
# is pre-onboarded. Placing the file here means the inspector finds it
# already present on first launch and skips writing its built-in
# DEFAULT_SEED_CONFIG over it — it's still the writable catalog, so servers
# can be edited/added from the UI afterwards.
#
# By default only mcp-server-everything-wrong is seeded. Pass
# ADD_MORE_MCP_SERVERS=true (via docker-compose.yaml's build arg, itself
# read from the shell environment) to also seed the inspector's own
# filesystem/everything demo servers.
ARG ADD_MORE_MCP_SERVERS=false
COPY inspector-mcp-config-minimal.json inspector-mcp-config-full.json /tmp/
RUN mkdir -p /root/.mcp-inspector && \
    if [ "$ADD_MORE_MCP_SERVERS" = "true" ]; then \
      cp /tmp/inspector-mcp-config-full.json /root/.mcp-inspector/mcp.json; \
    else \
      cp /tmp/inspector-mcp-config-minimal.json /root/.mcp-inspector/mcp.json; \
    fi && \
    rm -f /tmp/inspector-mcp-config-minimal.json /tmp/inspector-mcp-config-full.json

# Web UI (6274) and MCP Apps sandbox (6275). Actual bind address is
# controlled by the HOST / DANGEROUSLY_BIND_ALL_INTERFACES env vars set in
# docker-compose.yaml, not by a CLI flag.
EXPOSE 6274 6275

ENTRYPOINT ["npx", "@modelcontextprotocol/inspector"]

CMD ["--web"]
