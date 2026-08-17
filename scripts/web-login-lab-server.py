#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs
from datetime import datetime
from pathlib import Path
import sys

LOG_PATH = Path("exercises/web-login-detection/logs/web-login.log")
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

USERS = {
    "admin": "CyberLab123!",
    "alice": "AliceStrong123!",
    "bob": "BobStrong123!",
    "deploy": "DeployStrong123!",
}

class LoginLabHandler(BaseHTTPRequestHandler):
    server_version = "CyberLabWebLogin/1.0"

    def client_ip(self):
        return self.headers.get("X-Forwarded-For", self.client_address[0])

    def write_log(self, username, result, status):
        timestamp = datetime.utcnow().isoformat() + "Z"
        ip = self.client_ip()
        user_agent = self.headers.get("User-Agent", "-").replace(" ", "_")

        line = (
            f"{timestamp} "
            f"ip={ip} "
            f"method=POST "
            f"path=/login "
            f"username={username} "
            f"result={result} "
            f"status={status} "
            f"user_agent={user_agent}"
        )

        with LOG_PATH.open("a", encoding="utf-8") as log:
            log.write(line + "\n")

    def send_text(self, status, body):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("X-Lab-Server", "CyberLab Web Login")
        self.end_headers()
        self.wfile.write(encoded)

    def do_GET(self):
        if self.path == "/":
            self.send_text(200, "CyberLab Web Login Lab\n")
        else:
            self.send_text(404, "Not Found\n")

    def do_POST(self):
        if self.path != "/login":
            self.send_text(404, "Not Found\n")
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(length).decode("utf-8")
        data = parse_qs(raw_body)

        username = data.get("username", [""])[0]
        password = data.get("password", [""])[0]

        if USERS.get(username) == password:
            self.write_log(username, "success", 200)
            self.send_text(200, "Login successful.\n")
        else:
            self.write_log(username, "failed", 401)
            self.send_text(401, "Unauthorized.\n")

    def log_message(self, format, *args):
        return

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8082
    server = HTTPServer(("127.0.0.1", port), LoginLabHandler)
    print(f"CyberLab web login server listening on http://127.0.0.1:{port}")
    server.serve_forever()

if __name__ == "__main__":
    main()
