import argparse
import os
from typing import cast

from .server import TRANSPORTS, Transport, serve


def _port(value: str) -> int:
    """Parse a TCP port, rejecting anything outside the valid range.

    argparse's plain `type=int` accepts any integer, so an out-of-range port
    reached the bind call and surfaced as an OverflowError traceback after
    uvicorn had already begun logging — which reads like a crash rather than the
    usage error it is.
    """
    port = int(value)
    if not 0 <= port <= 65535:
        raise argparse.ArgumentTypeError(f"port must be 0-65535, got {port}")
    return port


def _build_parser() -> argparse.ArgumentParser:
    """Build the CLI parser, each flag falling back to an env var then a default.

    Env values are supplied as argparse `default=`. That is load-bearing for
    --port: argparse applies `type=` to a default when the default is a string,
    which it is whenever MCP_PORT is set, so MCP_PORT=abc is rejected here with
    a usage message instead of crashing later.
    """
    parser = argparse.ArgumentParser(
        prog="mcp-server-everything-wrong",
        description="An intentionally insecure MCP server, for security demos.",
    )
    parser.add_argument(
        "--transport",
        choices=TRANSPORTS,
        default=os.environ.get("MCP_TRANSPORT", "stdio"),
        help="transport to serve on (env: MCP_TRANSPORT) (default: stdio)",
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("MCP_HOST", "0.0.0.0"),
        help="address to bind, HTTP only (env: MCP_HOST) (default: 0.0.0.0)",
    )
    parser.add_argument(
        "--port",
        type=_port,
        default=os.environ.get("MCP_PORT", 8000),
        help="port to bind, HTTP only (env: MCP_PORT) (default: 8000)",
    )
    return parser


def main() -> None:
    """MCP Server everything wrong - Show casing MCP vulnerabilties"""
    parser = _build_parser()
    args = parser.parse_args()

    # argparse enforces `choices` only for values passed on the command line,
    # never for defaults. Without this check an invalid MCP_TRANSPORT would slip
    # through and surface as a raw ValueError traceback from FastMCP.run().
    if args.transport not in TRANSPORTS:
        parser.error(
            f"invalid MCP_TRANSPORT: {args.transport!r} "
            f"(choose from {', '.join(TRANSPORTS)})"
        )

    # Not asyncio.run(): serve() is synchronous and mcp.run() starts its own
    # anyio event loop internally.
    serve(cast(Transport, args.transport), args.host, args.port)


if __name__ == "__main__":
    main()
