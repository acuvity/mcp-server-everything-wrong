FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1

ENV UV_LINK_MODE=copy

# Use the Python interpreter shipped in the uv image instead of downloading a
# standalone build (the pinned .python-version=3.10 differs from the 3.12 base).
ENV UV_PYTHON=python3.12
ENV UV_PYTHON_DOWNLOADS=never

RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project --no-dev --no-editable

ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync --frozen --no-dev --no-editable

FROM python:3.12-slim-bookworm

WORKDIR /app

COPY --from=uv /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH"

# Served over HTTP SSE; bind all interfaces so the port is reachable from outside
# the container. Override host/port with MCP_HOST / MCP_PORT.
ENV MCP_HOST=0.0.0.0
ENV MCP_PORT=8000
EXPOSE 8000

ENTRYPOINT ["mcp-server-everything-wrong"]
