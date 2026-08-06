#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs
from datetime import datetime
import json
import sys
from pathlib import Path

LOG_PATH = Path("exercises/web-http-fundamentals/logs/server.log")
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

class LabHandler(BaseHTTPRequestHandler):
    server_version = "CyberLabHTTP/1.0"

    def write_log(self, message):
        timestamp = datetime.utcnow().isoformat() + "Z"
        with LOG_PATH.open("a", encoding="utf-8") as log:
            log.write(f"{timestamp} {message}\n")

    def send_text(self, status, body, content_type="text/plain", extra_headers=None):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("X-Lab-Server", "CyberLab FIB")
        if extra_headers:
            for key, value in extra_headers.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(encoded)

    def do_GET(self):
        self.write_log(f"GET {self.path} from {self.client_address[0]}")

        if self.path == "/":
            body = """<!doctype html>
<html>
  <head><title>CyberLab HTTP Lab</title></head>
  <body>
    <h1>CyberLab HTTP Lab</h1>
    <p>This is the home page.</p>
  </body>
</html>
"""
            self.send_text(200, body, "text/html")

        elif self.path == "/admin":
            self.send_text(403, "Forbidden: admin area requires authorization.\n")

        elif self.path == "/headers":
            headers = {key: value for key, value in self.headers.items()}
            body = json.dumps(headers, indent=2)
            self.send_text(200, body + "\n", "application/json")

        elif self.path == "/set-cookie":
            self.send_text(
                200,
                "Cookie set.\n",
                extra_headers={"Set-Cookie": "session=lab-session-123; HttpOnly; SameSite=Lax"}
            )

        else:
            self.send_text(404, "Not Found\n")

    def do_POST(self):
        self.write_log(f"POST {self.path} from {self.client_address[0]}")

        length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(length).decode("utf-8")
        data = parse_qs(raw_body)

        if self.path == "/login":
            username = data.get("username", [""])[0]
            password = data.get("password", [""])[0]

            if username == "admin" and password == "CyberLab123!":
                self.send_text(
                    200,
                    "Login successful.\n",
                    extra_headers={"Set-Cookie": "session=authenticated-lab-session; HttpOnly; SameSite=Lax"}
                )
            else:
                self.send_text(401, "Unauthorized: invalid credentials.\n")
        else:
            self.send_text(404, "Not Found\n")

    def log_message(self, format, *args):
        return

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    server = HTTPServer(("127.0.0.1", port), LabHandler)
    print(f"CyberLab HTTP server listening on http://127.0.0.1:{port}")
    server.serve_forever()

if __name__ == "__main__":
    main()
