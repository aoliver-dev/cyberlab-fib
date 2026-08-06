#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs
from datetime import datetime
from pathlib import Path
import sys

LOG_PATH = Path("exercises/web-cookies-sessions/logs/server.log")
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

VALID_SESSION = "authenticated-lab-session"

class SessionLabHandler(BaseHTTPRequestHandler):
    server_version = "CyberLabSessionHTTP/1.0"

    def write_log(self, message):
        timestamp = datetime.utcnow().isoformat() + "Z"
        with LOG_PATH.open("a", encoding="utf-8") as log:
            log.write(f"{timestamp} {message}\n")

    def send_text(self, status, body, extra_headers=None):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("X-Lab-Server", "CyberLab FIB Sessions")
        if extra_headers:
            for key, value in extra_headers.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(encoded)

    def get_cookie_value(self, name):
        cookie_header = self.headers.get("Cookie", "")
        cookies = {}

        for part in cookie_header.split(";"):
            if "=" in part:
                key, value = part.strip().split("=", 1)
                cookies[key] = value

        return cookies.get(name)

    def do_GET(self):
        self.write_log(
            f"GET {self.path} from {self.client_address[0]} Cookie={self.headers.get('Cookie', '-')}"
        )

        if self.path == "/":
            self.send_text(200, "CyberLab Sessions Lab\n")

        elif self.path == "/dashboard":
            session = self.get_cookie_value("session")

            if session == VALID_SESSION:
                self.send_text(200, "Welcome to the authenticated dashboard.\n")
            else:
                self.send_text(401, "Unauthorized: valid session cookie required.\n")

        elif self.path == "/logout":
            self.send_text(
                200,
                "Logged out.\n",
                extra_headers={
                    "Set-Cookie": "session=deleted; Max-Age=0; HttpOnly; SameSite=Lax"
                }
            )

        elif self.path == "/insecure-cookie":
            self.send_text(
                200,
                "Insecure cookie set.\n",
                extra_headers={
                    "Set-Cookie": "session=insecure-lab-session"
                }
            )

        elif self.path == "/secure-cookie":
            self.send_text(
                200,
                "Better cookie set.\n",
                extra_headers={
                    "Set-Cookie": "session=better-lab-session; HttpOnly; SameSite=Lax"
                }
            )

        else:
            self.send_text(404, "Not Found\n")

    def do_POST(self):
        self.write_log(
            f"POST {self.path} from {self.client_address[0]} Cookie={self.headers.get('Cookie', '-')}"
        )

        length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(length).decode("utf-8")
        data = parse_qs(raw_body)

        if self.path == "/login":
            username = data.get("username", [""])[0]
            password = data.get("password", [""])[0]

            if username == "admin" and password == "CyberLab123!":
                self.send_text(
                    200,
                    "Login successful. Session created.\n",
                    extra_headers={
                        "Set-Cookie": f"session={VALID_SESSION}; HttpOnly; SameSite=Lax"
                    }
                )
            else:
                self.send_text(401, "Unauthorized: invalid credentials.\n")
        else:
            self.send_text(404, "Not Found\n")

    def log_message(self, format, *args):
        return

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8081
    server = HTTPServer(("127.0.0.1", port), SessionLabHandler)
    print(f"CyberLab session server listening on http://127.0.0.1:{port}")
    server.serve_forever()

if __name__ == "__main__":
    main()
