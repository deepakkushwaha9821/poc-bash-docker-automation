#!/usr/bin/env python3
import json
import os
import mimetypes
from http.server import HTTPServer, SimpleHTTPRequestHandler
from socketserver import ThreadingMixIn
from datetime import datetime

PORT = int(os.environ.get("PORT", 8000))
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FRONTEND_DIST = os.path.abspath(os.path.join(BASE_DIR, "..", "frontend", "dist"))


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


class AppRequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/health":
            self.send_json_response(200, {
                "status": "healthy",
                "service": "dummy-app",
                "database": "connected (mock DB pool ready)",
                "timestamp": datetime.utcnow().isoformat() + "Z"
            })
            return

        if self.path == "/api/db-health":
            self.send_json_response(200, {
                "status": "up",
                "database": "postgres",
                "latency_ms": 1.2,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            })
            return

        if self.path == "/api/info":
            self.send_json_response(200, {
                "service": "dummy-app",
                "version": "1.0.0",
                "frontend_built": os.path.isdir(FRONTEND_DIST)
            })
            return

        # Serve static assets from frontend/dist if available
        if os.path.isdir(FRONTEND_DIST):
            requested_path = self.path.split("?")[0].lstrip("/")
            file_path = os.path.join(FRONTEND_DIST, requested_path)
            
            if os.path.isfile(file_path):
                self.serve_file(file_path)
                return
            
            # SPA fallback: serve index.html for non-api routes
            index_path = os.path.join(FRONTEND_DIST, "index.html")
            if os.path.isfile(index_path):
                self.serve_file(index_path)
                return

        # Default fallback message if frontend is not yet built
        fallback_html = """<!DOCTYPE html>
<html>
<head><title>Dummy App</title></head>
<body style="font-family: sans-serif; padding: 2rem; background: #0f172a; color: #f8fafc;">
    <h1>Dummy App Backend Running</h1>
    <p>Status: <span style="color: #4ade80;">Active</span></p>
    <p>Endpoints: <a href="/api/health" style="color: #38bdf8;">/api/health</a> | <a href="/api/info" style="color: #38bdf8;">/api/info</a></p>
    <p>Frontend status: Not built yet (run <code>npm ci && npm run build</code> in frontend directory)</p>
</body>
</html>"""
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(fallback_html.encode("utf-8"))))
        self.end_headers()
        self.wfile.write(fallback_html.encode("utf-8"))

    def serve_file(self, file_path):
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = "application/octet-stream"
        
        with open(file_path, "rb") as f:
            content = f.read()

        self.send_response(200)
        self.send_header("Content-Type", mime_type)
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def send_json_response(self, code, data):
        response_bytes = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_bytes)))
        self.end_headers()
        self.wfile.write(response_bytes)

    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {self.client_address[0]} - {format % args}")


if __name__ == "__main__":
    server_address = ("", PORT)
    httpd = ThreadingHTTPServer(server_address, AppRequestHandler)
    print(f"Dummy App Service started on port {PORT}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server.")
        httpd.server_close()
