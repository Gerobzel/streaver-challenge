import socket
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer


class HelloWorldHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"Hello Streaver!!"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        pass


class HealthCheckHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with socket.create_connection(("localhost", 80), timeout=2):
                code, body = 200, b"Service Healthy"
        except OSError:
            code, body = 503, b"Service Unavailable"
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        pass


def run_hello_world():
    HTTPServer(("0.0.0.0", 80), HelloWorldHandler).serve_forever()


if __name__ == "__main__":
    t = threading.Thread(target=run_hello_world, daemon=True)
    t.start()
    HTTPServer(("0.0.0.0", 8080), HealthCheckHandler).serve_forever()
