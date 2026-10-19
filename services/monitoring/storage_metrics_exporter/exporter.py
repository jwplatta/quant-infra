"""Expose read-only MinIO object inventory metrics to Prometheus."""

from __future__ import annotations

import logging
import os
import threading
import time

from minio import Minio
from prometheus_client import Gauge, start_http_server

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
LOGGER = logging.getLogger("storage_metrics_exporter")

REFRESH_SECONDS = int(os.getenv("STORAGE_METRICS_REFRESH_SECONDS", "86400"))
RETRY_SECONDS = int(os.getenv("STORAGE_METRICS_RETRY_SECONDS", "300"))
BUCKET_DATASETS = {
    "tickrake-staging": {
        "options": "options",
        "candles": "candles",
        "level_one": "level_one",
        "order_book": "order_book",
        "fundamentals": "fundamentals",
        "economic_events": "economic_events",
    },
    "tractatus-lakehouse": {
        "options": "options",
        "level_one_equities": "level_one",
        "level_one_futures": "level_one",
        "order_book": "order_book",
        "candles": "candles",
        "fundamentals": "fundamentals",
        "economic_events": "economic_events",
    },
}

OBJECT_BYTES = Gauge(
    "minio_storage_object_bytes",
    "Current object bytes in configured MinIO bucket dataset prefixes.",
    ["bucket", "dataset"],
)
OBJECT_COUNT = Gauge(
    "minio_storage_object_count",
    "Current object count in configured MinIO bucket dataset prefixes.",
    ["bucket", "dataset"],
)
LAST_REFRESH = Gauge(
    "minio_storage_inventory_last_refresh_timestamp_seconds",
    "Unix timestamp when the MinIO inventory was last refreshed successfully.",
)
REFRESH_ERRORS = Gauge(
    "minio_storage_inventory_refresh_errors",
    "Whether the most recent MinIO inventory refresh failed.",
)


def _client() -> Minio:
    endpoint = os.environ.get("MINIO_ENDPOINT", "minio:9000")
    return Minio(
        endpoint.removeprefix("http://").removeprefix("https://"),
        access_key=os.environ["MINIO_ACCESS_KEY"],
        secret_key=os.environ["MINIO_SECRET_KEY"],
        secure=endpoint.startswith("https://"),
    )


def refresh_inventory(client: Minio) -> None:
    """List only configured dataset prefixes and update aggregate gauges."""
    totals: dict[tuple[str, str], list[int]] = {
        (bucket, dataset): [0, 0]
        for bucket, prefixes in BUCKET_DATASETS.items()
        for dataset in set(prefixes.values())
    }
    for bucket, prefixes in BUCKET_DATASETS.items():
        for prefix, dataset in prefixes.items():
            for obj in client.list_objects(bucket, prefix=f"{prefix}/", recursive=True):
                if obj.size is None:
                    continue
                totals[(bucket, dataset)][0] += obj.size
                totals[(bucket, dataset)][1] += 1

    for (bucket, dataset), (byte_count, object_count) in totals.items():
        OBJECT_BYTES.labels(bucket=bucket, dataset=dataset).set(byte_count)
        OBJECT_COUNT.labels(bucket=bucket, dataset=dataset).set(object_count)
    for bucket in BUCKET_DATASETS:
        bucket_totals = [
            values for (bucket_name, _), values in totals.items() if bucket_name == bucket
        ]
        OBJECT_BYTES.labels(bucket=bucket, dataset="Totals").set(
            sum(values[0] for values in bucket_totals)
        )
        OBJECT_COUNT.labels(bucket=bucket, dataset="Totals").set(
            sum(values[1] for values in bucket_totals)
        )
    LAST_REFRESH.set(time.time())
    REFRESH_ERRORS.set(0)
    LOGGER.info("MinIO inventory refreshed for %d bucket and dataset pairs", len(totals))


def run_refresh_loop() -> None:
    client = _client()
    while True:
        try:
            refresh_inventory(client)
        except Exception:
            REFRESH_ERRORS.set(1)
            LOGGER.exception("MinIO inventory refresh failed")
            time.sleep(RETRY_SECONDS)
        else:
            time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    if REFRESH_SECONDS < 15:
        raise ValueError("STORAGE_METRICS_REFRESH_SECONDS must be at least 15")
    if RETRY_SECONDS < 15:
        raise ValueError("STORAGE_METRICS_RETRY_SECONDS must be at least 15")
    threading.Thread(target=run_refresh_loop, name="inventory-refresh", daemon=True).start()
    start_http_server(9105)
    LOGGER.info("Prometheus metrics server listening on :9105")
    threading.Event().wait()
