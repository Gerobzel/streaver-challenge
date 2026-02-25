import unittest
from unittest.mock import MagicMock, patch

from main import HelloWorldHandler, HealthCheckHandler


def make_handler(cls):
    """Instantiate a handler without an HTTP connection, mocking all I/O."""
    handler = cls.__new__(cls)
    handler.send_response = MagicMock()
    handler.send_header = MagicMock()
    handler.end_headers = MagicMock()
    handler.wfile = MagicMock()
    return handler


class TestHelloWorldHandler(unittest.TestCase):
    def test_returns_200_with_hello_world_body(self):
        handler = make_handler(HelloWorldHandler)

        handler.do_GET()

        handler.send_response.assert_called_once_with(200)
        handler.wfile.write.assert_called_once_with(b"Hello World")


class TestHealthCheckHandler(unittest.TestCase):
    def test_returns_200_when_port_80_is_reachable(self):
        handler = make_handler(HealthCheckHandler)

        with patch("main.socket.create_connection"):
            handler.do_GET()

        handler.send_response.assert_called_once_with(200)
        handler.wfile.write.assert_called_once_with(b"Service Healthy")

    def test_returns_403_when_port_80_is_unreachable(self):
        handler = make_handler(HealthCheckHandler)

        with patch("main.socket.create_connection", side_effect=OSError):
            handler.do_GET()

        handler.send_response.assert_called_once_with(403)
        handler.wfile.write.assert_called_once_with(b"Service Unavailable")


if __name__ == "__main__":
    unittest.main()
