FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1

ENV UV_LINK_MODE=copy

RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project --no-dev --no-editable

ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync --frozen --no-dev --no-editable

FROM python:3.12-slim-bookworm

RUN groupadd --system app && useradd --system --gid app app

WORKDIR /app

COPY --from=uv --chown=app:app /root/.local /root/.local
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# /root/.local holds the standalone Python interpreter uv downloaded (the
# venv's bin/python symlinks into it); /root itself is 0700 by default, which
# would block the non-root "app" user from traversing into it.
RUN chmod o+x /root

ENV PATH="/app/.venv/bin:$PATH"

# Default port for the streamable HTTP transport. Documentation only — the
# server still starts on stdio unless MCP_TRANSPORT says otherwise.
EXPOSE 8000

USER app

ENTRYPOINT ["mcp-server-everything-wrong"]
