#!/usr/bin/env python3
"""Read-only Prometheus exporter for Docker Engine container statistics."""

from __future__ import annotations

import json
import os
import socket
import time
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


DOCKER_SOCKET = os.environ.get("DOCKER_SOCKET", "/var/run/docker.sock")
POLL_INTERVAL_SECONDS = float(os.environ.get("POLL_INTERVAL_SECONDS", "15"))
LISTEN_PORT = int(os.environ.get("LISTEN_PORT", "9105"))


def escape_label(value: object) -> str:
    return str(value).replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')


def metric_labels(labels: dict[str, str]) -> str:
    return "{" + ",".join(f'{key}="{escape_label(value)}"' for key, value in labels.items()) + "}"


def docker_get(path: str) -> Any:
    request = f"GET {path} HTTP/1.1\r\nHost: docker\r\nConnection: close\r\n\r\n".encode()
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(5)
        client.connect(DOCKER_SOCKET)
        client.sendall(request)
        response = bytearray()
        while b"\r\n\r\n" not in response:
            response.extend(client.recv(65_536))

        header, _, body = response.partition(b"\r\n\r\n")
        if b"transfer-encoding: chunked" in header.lower():
            decoded = bytearray()
            while True:
                while b"\r\n" not in body:
                    body += client.recv(65_536)
                line, _, body = body.partition(b"\r\n")
                chunk_size = int(line, 16)
                while len(body) < chunk_size + 2:
                    body += client.recv(65_536)
                if chunk_size == 0:
                    body = bytes(decoded)
                    break
                decoded.extend(body[:chunk_size])
                body = body[chunk_size + 2:]
        else:
            content_length = next(
                (int(line.split(b":", 1)[1].strip()) for line in header.split(b"\r\n") if line.lower().startswith(b"content-length:")),
                None,
            )
            if content_length is not None:
                while len(body) < content_length:
                    body += client.recv(65_536)
                body = body[:content_length]

    status = header.split(b"\r\n", 1)[0]
    if b" 200 " not in status:
        raise RuntimeError(f"Docker API request {path} failed: {status.decode(errors='replace')}")
    return json.loads(body)


class DockerStatsCollector:
    def __init__(self) -> None:
        self.previous_cpu: dict[str, tuple[int, int, int, float]] = {}
        self.last_scrape: float | None = None
        self.metrics = ""
        self.error: str | None = None

    def scrape(self) -> None:
        lines = [
            "# HELP docker_container_up Whether Docker reports the container as running.",
            "# TYPE docker_container_up gauge",
            "# HELP docker_container_cpu_cores CPU cores used between Docker statistics snapshots.",
            "# TYPE docker_container_cpu_cores gauge",
            "# HELP docker_container_memory_usage_bytes Current container memory usage reported by Docker.",
            "# TYPE docker_container_memory_usage_bytes gauge",
            "# HELP docker_container_memory_limit_bytes Container memory limit reported by Docker.",
            "# TYPE docker_container_memory_limit_bytes gauge",
            "# HELP docker_container_network_receive_bytes_total Cumulative network bytes received by the container.",
            "# TYPE docker_container_network_receive_bytes_total counter",
            "# HELP docker_container_network_transmit_bytes_total Cumulative network bytes transmitted by the container.",
            "# TYPE docker_container_network_transmit_bytes_total counter",
        ]

        containers = docker_get("/containers/json?all=1")
        running_ids = [container["Id"] for container in containers if container.get("State") == "running"]
        with ThreadPoolExecutor(max_workers=8) as executor:
            stats_by_id = dict(
                zip(
                    running_ids,
                    executor.map(lambda container_id: docker_get(f"/containers/{container_id}/stats?stream=false"), running_ids),
                )
            )

        active_ids: set[str] = set()
        for container in containers:
            container_id = container["Id"]
            active_ids.add(container_id)
            compose = container.get("Labels", {})
            labels = {
                "container": container.get("Names", [container_id[:12]])[0].lstrip("/"),
                "service": compose.get("com.docker.compose.service", ""),
                "project": compose.get("com.docker.compose.project", ""),
            }
            rendered_labels = metric_labels(labels)
            running = container.get("State") == "running"
            lines.append(f"docker_container_up{rendered_labels} {1 if running else 0}")
            if not running:
                continue

            stats = stats_by_id[container_id]
            memory = stats.get("memory_stats", {})
            lines.append(f"docker_container_memory_usage_bytes{rendered_labels} {memory.get('usage', 0)}")
            lines.append(f"docker_container_memory_limit_bytes{rendered_labels} {memory.get('limit', 0)}")

            cpu = stats.get("cpu_stats", {})
            total_cpu = cpu.get("cpu_usage", {}).get("total_usage", 0)
            system_cpu = cpu.get("system_cpu_usage", 0)
            online_cpus = cpu.get("online_cpus") or len(cpu.get("cpu_usage", {}).get("percpu_usage", [])) or 1
            now = time.monotonic()
            previous = self.previous_cpu.get(container_id)
            cpu_cores = 0.0
            if previous:
                previous_total, previous_system, previous_cpus, _ = previous
                system_delta = system_cpu - previous_system
                if system_delta > 0:
                    cpu_cores = (total_cpu - previous_total) / system_delta * previous_cpus
            self.previous_cpu[container_id] = (total_cpu, system_cpu, online_cpus, now)
            lines.append(f"docker_container_cpu_cores{rendered_labels} {cpu_cores}")

            received = transmitted = 0
            for network in stats.get("networks", {}).values():
                received += network.get("rx_bytes", 0)
                transmitted += network.get("tx_bytes", 0)
            lines.append(f"docker_container_network_receive_bytes_total{rendered_labels} {received}")
            lines.append(f"docker_container_network_transmit_bytes_total{rendered_labels} {transmitted}")

        self.previous_cpu = {key: value for key, value in self.previous_cpu.items() if key in active_ids}
        self.metrics = "\n".join(lines) + "\n"
        self.last_scrape = time.monotonic()
        self.error = None

    def get_metrics(self) -> str:
        if self.last_scrape is None or time.monotonic() - self.last_scrape >= POLL_INTERVAL_SECONDS:
            try:
                self.scrape()
            except Exception as error:  # Keep the last good sample available to Prometheus.
                self.error = str(error)
        error_metric = 1 if self.error else 0
        return self.metrics + "# HELP docker_stats_exporter_scrape_error Whether the Docker API scrape failed.\n" \
            "# TYPE docker_stats_exporter_scrape_error gauge\n" \
            f"docker_stats_exporter_scrape_error {error_metric}\n"


COLLECTOR = DockerStatsCollector()


class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802
        if self.path != "/metrics":
            self.send_error(404)
            return
        payload = COLLECTOR.get_metrics().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, _format: str, *_args: object) -> None:
        return


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", LISTEN_PORT), MetricsHandler).serve_forever()
