from .server import serve


def main():
    """MCP Server everything wrong - Show casing MCP vulnerabilties"""
    import asyncio

    asyncio.run(serve())


if __name__ == "__main__":
    main()
