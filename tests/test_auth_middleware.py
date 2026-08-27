"""Tests for BearerTokenMiddleware, isolated from the real MCP session handling.

Wraps a trivial downstream ASGI app rather than the full FastMCP streamable-http
app, since only the auth gate itself is under test here.
"""

import httpx
import pytest

from mcp_server_everything_wrong.server import BearerTokenMiddleware

TOKEN = "test-token-123"


async def _downstream(scope, receive, send):
    await send(
        {
            "type": "http.response.start",
            "status": 200,
            "headers": [(b"content-type", b"text/plain")],
        }
    )
    await send({"type": "http.response.body", "body": b"ok"})


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.fixture
def client():
    app = BearerTokenMiddleware(_downstream, TOKEN)
    transport = httpx.ASGITransport(app=app)
    return httpx.AsyncClient(transport=transport, base_url="http://test")


@pytest.mark.anyio
async def test_missing_header_rejected(client):
    async with client:
        response = await client.post("/mcp")
    assert response.status_code == 401


@pytest.mark.anyio
async def test_wrong_token_rejected(client):
    async with client:
        response = await client.post(
            "/mcp", headers={"Authorization": "Bearer wrong-token"}
        )
    assert response.status_code == 401


@pytest.mark.anyio
async def test_correct_token_passes_through(client):
    async with client:
        response = await client.post(
            "/mcp", headers={"Authorization": f"Bearer {TOKEN}"}
        )
    assert response.status_code == 200
    assert response.text == "ok"


@pytest.mark.anyio
async def test_duplicate_authorization_headers_rejected(client):
    # Both values correct: a naive dict(scope["headers"]) collapse would let
    # this through by keeping only the last one. Must be rejected outright.
    headers = [
        ("Authorization", f"Bearer {TOKEN}"),
        ("Authorization", f"Bearer {TOKEN}"),
    ]
    async with client:
        response = await client.post("/mcp", headers=headers)
    assert response.status_code == 401
