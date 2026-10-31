"""Expose MinIO scanner bucket metrics to Prometheus without listing objects."""

from __future__ import annotations

import json
import logging
import os
import re
import threading
from datetime import datetime

from minio.credentials import StaticProvider
from minio.minioadmin import MinioAdmin
from prometheus_client import REGISTRY, start_http_server
from prometheus_client.core import GaugeMetricFamily

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
LOGGER = logging.getLogger("storage_metrics_exporter")


def parse_bucket_usage(raw: str):
    """Validate scanner usage before exposing any bucket samples."""
    response = json.loads(raw)
    stamp = re.sub(r"(\.\d{6})\d+", r"\1", response["lastUpdate"])
    updated = datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    if updated.tzinfo is None:
        raise ValueError("scanner timestamp has no timezone")
    buckets = response["bucketsUsageInfo"]
    if not isinstance(buckets, dict):
        raise ValueError("bucket usage is not a mapping")
    result = []
    for bucket, usage in buckets.items():
        size, count = usage["size"], usage["objectsCount"]
        if not isinstance(bucket, str) or any(
            isinstance(value, bool) or not isinstance(value, int) or value < 0
            for value in (size, count)
        ):
            raise ValueError("invalid bucket measurement")
        result.append((bucket, size, count))
    return updated.timestamp(), result


class BucketUsageCollector:
    """Fetch MinIO's existing scanner accounting for each Prometheus scrape."""

    def __init__(self, client):
        self.client = client

    def describe(self):
        # Registration must not contact MinIO: Compose may start us before it is ready.
        yield GaugeMetricFamily("minio_bucket_usage_total_bytes", "Scanner-reported bucket bytes.", labels=["bucket"])
        yield GaugeMetricFamily("minio_bucket_usage_object_total", "Scanner-reported bucket objects.", labels=["bucket"])
        yield GaugeMetricFamily("minio_bucket_usage_last_update_timestamp_seconds", "Time of the last MinIO scanner usage update.")

    def collect(self):
        updated, buckets = parse_bucket_usage(self.client.get_data_usage_info())
        sizes = GaugeMetricFamily(
            "minio_bucket_usage_total_bytes", "Scanner-reported bucket bytes.", labels=["bucket"]
        )
        counts = GaugeMetricFamily(
            "minio_bucket_usage_object_total", "Scanner-reported bucket objects.", labels=["bucket"]
        )
        freshness = GaugeMetricFamily(
            "minio_bucket_usage_last_update_timestamp_seconds",
            "Time of the last MinIO scanner usage update.",
        )
        freshness.add_metric([], updated)
        for bucket, size, count in buckets:
            sizes.add_metric([bucket], size)
            counts.add_metric([bucket], count)
        yield sizes
        yield counts
        yield freshness


def _admin_client():
    endpoint = os.environ.get("MINIO_ENDPOINT", "minio:9000")
    return MinioAdmin(
        endpoint.removeprefix("http://").removeprefix("https://"),
        StaticProvider(os.environ["MINIO_ACCESS_KEY"], os.environ["MINIO_SECRET_KEY"]),
        secure=endpoint.startswith("https://"),
    )


if __name__ == "__main__":
    REGISTRY.register(BucketUsageCollector(_admin_client()))
    start_http_server(9105)
    LOGGER.info("Prometheus metrics server listening on :9105")
    threading.Event().wait()
