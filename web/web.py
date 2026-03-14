#!/usr/bin/env python3
"""Static file server for the did:cow web UI (dev use — in prod, copy to nginx webroot)."""

import http.server
import os
from pathlib import Path

PORT = 6667
DIRECTORY = Path(__file__).parent / "static"


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DIRECTORY), **kwargs)

    def log_message(self, format, *args):
        print(f"{self.address_string()} {format % args}")


if __name__ == "__main__":
    with http.server.HTTPServer(("", PORT), Handler) as httpd:
        print(f"Serving {DIRECTORY} at http://localhost:{PORT}")
        httpd.serve_forever()
