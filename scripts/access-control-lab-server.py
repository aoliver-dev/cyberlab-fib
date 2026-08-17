#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse
from datetime import datetime
from pathlib import Path
import sys

LOG_PATH = Path("exercises/web-access-control/logs/access-control.log")
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

USERS = {
    "1": {"username": "admin", "role": "admin", "email": "admin@cyberlab.local"},
    "2": {"username": "alice", "role": "user", "email": "alice@cyberlab.local"},
    "3": {"username": "bob", "role": "user", "email": "bob@cyberlab.local"},
}

PASSWORDS = {
    "admin": "AdminStrong123!",
    "alice": "AliceStrong123!",
    "bob": "BobStrong123!",
}

SESSIONS = {
    "admin-session": "1",
    "alice-session": "2",
    "bob-session": "3",
}

class AccessControlHandler(BaseHTTPRequestHandler):
    server_version = "CyberLabAccessControl/1.0"

    def write_log(self, message):
        timestamp = datetime.utcnow().isoformat() + "Z"
        with LOG_PATH.open("a", encoding="utf-8") as log:
            log.write(f"{timestamp} {message}\n")

    def send_text(self, status, body, extra_headers=None):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("X-Lab-Server", "CyberLab Access Control")
        if extra_headers:
            for key, value in extra_headers.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(encoded)

    def get_cookie_value(self, name):
        cookie_header = self.headers.get("Cookie", "")
        for part in cookie_header.split(";"):
            if "=" in part:
                key, value = part.strip().split("=", 1)
                if key == name:
                    return value
        return None

    def current_user_id(self):
        session = self.get_cookie_value("session")
        return SESSIONS.get(session)

    def current_user(self):
        user_id = self.current_user_id()
        if user_id:
            return USERS.get(user_id)
        return None

    def render_profile(self, user_id):
        user = USERS.get(user_id)
        if not user:
            return None
        return (
            f"user_id={user_id}\n"
            f"username={user['username']}\n"
            f"role={user['role']}\n"
            f"email={user['email']}\n"
        )

    def do_POST(self):
        if self.path != "/login":
            self.send_text(404, "Not Found\n")
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(length).decode("utf-8")
        data = parse_qs(raw_body)

        username = data.get("username", [""])[0]
        password = data.get("password", [""])[0]

        if PASSWORDS.get(username) == password:
            user_id = next(uid for uid, data in USERS.items() if data["username"] == username)
            session = f"{username}-session"

            self.write_log(f"LOGIN username={username} result=success user_id={user_id}")

            self.send_text(
                200,
                "Login successful.\n",
                extra_headers={
                    "Set-Cookie": f"session={session}; HttpOnly; SameSite=Lax"
                }
            )
        else:
            self.write_log(f"LOGIN username={username} result=failed")
            self.send_text(401, "Unauthorized.\n")

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        requester_id = self.current_user_id()
        requester = self.current_user()

        if path == "/":
            self.send_text(200, "CyberLab Access Control Lab\n")
            return

        if path == "/profile":
            # Vulnerable endpoint:
            # It checks that the user is authenticated, but it does not check
            # whether the requested profile belongs to that user.
            target_id = query.get("id", [""])[0]

            if not requester:
                self.write_log(f"PROFILE_VULN requester=anonymous target={target_id} result=unauthenticated")
                self.send_text(401, "Unauthorized: login required.\n")
                return

            profile = self.render_profile(target_id)
            if not profile:
                self.write_log(f"PROFILE_VULN requester={requester_id} target={target_id} result=not_found")
                self.send_text(404, "User not found.\n")
                return

            self.write_log(f"PROFILE_VULN requester={requester_id} target={target_id} result=allowed")
            self.send_text(200, profile)
            return

        if path == "/secure-profile":
            # Secure endpoint:
            # Normal users can only read their own profile.
            # Admin can read all profiles.
            target_id = query.get("id", [""])[0]

            if not requester:
                self.write_log(f"PROFILE_SECURE requester=anonymous target={target_id} result=unauthenticated")
                self.send_text(401, "Unauthorized: login required.\n")
                return

            if requester["role"] != "admin" and requester_id != target_id:
                self.write_log(f"PROFILE_SECURE requester={requester_id} target={target_id} result=forbidden")
                self.send_text(403, "Forbidden: cannot access another user's profile.\n")
                return

            profile = self.render_profile(target_id)
            if not profile:
                self.write_log(f"PROFILE_SECURE requester={requester_id} target={target_id} result=not_found")
                self.send_text(404, "User not found.\n")
                return

            self.write_log(f"PROFILE_SECURE requester={requester_id} target={target_id} result=allowed")
            self.send_text(200, profile)
            return

        if path == "/admin-panel":
            if not requester:
                self.write_log("ADMIN_PANEL requester=anonymous result=unauthenticated")
                self.send_text(401, "Unauthorized: login required.\n")
                return

            if requester["role"] != "admin":
                self.write_log(f"ADMIN_PANEL requester={requester_id} result=forbidden")
                self.send_text(403, "Forbidden: admin role required.\n")
                return

            self.write_log(f"ADMIN_PANEL requester={requester_id} result=allowed")
            self.send_text(200, "Welcome to the admin panel.\n")
            return

        self.send_text(404, "Not Found\n")

    def log_message(self, format, *args):
        return

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8083
    server = HTTPServer(("127.0.0.1", port), AccessControlHandler)
    print(f"CyberLab access control server listening on http://127.0.0.1:{port}")
    server.serve_forever()

if __name__ == "__main__":
    main()
