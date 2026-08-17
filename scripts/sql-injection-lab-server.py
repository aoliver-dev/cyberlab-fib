#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse
from datetime import datetime
from pathlib import Path
import sqlite3
import sys

DB_PATH = Path("exercises/web-sql-injection/results/lab.db")
LOG_PATH = Path("exercises/web-sql-injection/logs/sql-injection.log")
DB_PATH.parent.mkdir(parents=True, exist_ok=True)
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("DROP TABLE IF EXISTS users")
    cur.execute("""
        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            email TEXT NOT NULL
        )
    """)

    cur.executemany(
        "INSERT INTO users (id, username, password, role, email) VALUES (?, ?, ?, ?, ?)",
        [
            (1, "admin", "AdminStrong123!", "admin", "admin@cyberlab.local"),
            (2, "alice", "AliceStrong123!", "user", "alice@cyberlab.local"),
            (3, "bob", "BobStrong123!", "user", "bob@cyberlab.local"),
        ],
    )

    conn.commit()
    conn.close()

class SQLiLabHandler(BaseHTTPRequestHandler):
    server_version = "CyberLabSQLi/1.0"

    def write_log(self, message):
        timestamp = datetime.utcnow().isoformat() + "Z"
        with LOG_PATH.open("a", encoding="utf-8") as log:
            log.write(f"{timestamp} {message}\n")

    def send_text(self, status, body):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("X-Lab-Server", "CyberLab SQL Injection")
        self.end_headers()
        self.wfile.write(encoded)

    def rows_to_text(self, rows):
        if not rows:
            return "No rows returned.\n"

        output = []
        for row in rows:
            output.append(
                f"user_id={row[0]} username={row[1]} role={row[2]} email={row[3]}"
            )
        return "\n".join(output) + "\n"

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        if path == "/":
            self.send_text(200, "CyberLab SQL Injection Lab\n")
            return

        if path == "/user-vulnerable":
            user_id = query.get("id", [""])[0]

            conn = sqlite3.connect(DB_PATH)
            cur = conn.cursor()

            # Intentionally vulnerable: user input is concatenated into SQL.
            sql = f"SELECT id, username, role, email FROM users WHERE id = {user_id}"

            self.write_log(f"USER_VULN id={user_id} query_type=string_concatenation")

            try:
                rows = cur.execute(sql).fetchall()
                self.send_text(200, self.rows_to_text(rows))
            except sqlite3.Error as error:
                self.send_text(500, f"SQL error: {error}\n")
            finally:
                conn.close()
            return

        if path == "/user-secure":
            user_id = query.get("id", [""])[0]

            conn = sqlite3.connect(DB_PATH)
            cur = conn.cursor()

            # Secure version: user input is passed as a parameter.
            sql = "SELECT id, username, role, email FROM users WHERE id = ?"

            self.write_log(f"USER_SECURE id={user_id} query_type=parameterized")

            rows = cur.execute(sql, (user_id,)).fetchall()
            conn.close()

            if rows:
                self.send_text(200, self.rows_to_text(rows))
            else:
                self.send_text(404, "User not found.\n")
            return

        self.send_text(404, "Not Found\n")

    def do_POST(self):
        if self.path not in ["/login-vulnerable", "/login-secure"]:
            self.send_text(404, "Not Found\n")
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(length).decode("utf-8")
        data = parse_qs(raw_body)

        username = data.get("username", [""])[0]
        password = data.get("password", [""])[0]

        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()

        if self.path == "/login-vulnerable":
            # Intentionally vulnerable: user input is concatenated into SQL.
            sql = (
                "SELECT id, username, role, email FROM users "
                f"WHERE username = '{username}' AND password = '{password}'"
            )

            self.write_log(f"LOGIN_VULN username={username} query_type=string_concatenation")

            try:
                row = cur.execute(sql).fetchone()
            except sqlite3.Error as error:
                conn.close()
                self.send_text(500, f"SQL error: {error}\n")
                return

        else:
            # Secure version: parameterized query.
            sql = (
                "SELECT id, username, role, email FROM users "
                "WHERE username = ? AND password = ?"
            )

            self.write_log(f"LOGIN_SECURE username={username} query_type=parameterized")
            row = cur.execute(sql, (username, password)).fetchone()

        conn.close()

        if row:
            self.send_text(
                200,
                f"Login successful.\nuser_id={row[0]} username={row[1]} role={row[2]}\n"
            )
        else:
            self.send_text(401, "Unauthorized.\n")

    def log_message(self, format, *args):
        return

def main():
    init_db()
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8084
    server = HTTPServer(("127.0.0.1", port), SQLiLabHandler)
    print(f"CyberLab SQL injection server listening on http://127.0.0.1:{port}")
    server.serve_forever()

if __name__ == "__main__":
    main()
