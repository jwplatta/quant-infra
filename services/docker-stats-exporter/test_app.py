#!/usr/bin/env python3
"""Unit tests for Docker stats memory normalization."""

import importlib.util
import unittest
from pathlib import Path


APP_PATH = Path(__file__).with_name("app.py")
SPEC = importlib.util.spec_from_file_location("docker_stats_exporter_app", APP_PATH)
APP = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(APP)


class MemoryWorkingSetTests(unittest.TestCase):
    def test_subtracts_cgroup_v1_total_inactive_file(self):
        self.assertEqual(
            APP.memory_working_set_bytes({
                "usage": 1_000,
                "stats": {"total_inactive_file": 300},
            }),
            700,
        )

    def test_subtracts_cgroup_v2_inactive_file(self):
        self.assertEqual(
            APP.memory_working_set_bytes({
                "usage": 1_000,
                "stats": {"inactive_file": 250},
            }),
            750,
        )

    def test_prefers_cgroup_v1_value_when_both_are_present(self):
        self.assertEqual(
            APP.memory_working_set_bytes({
                "usage": 1_000,
                "stats": {"total_inactive_file": 300, "inactive_file": 200},
            }),
            700,
        )

    def test_falls_back_to_cgroup_v2_when_v1_value_is_invalid(self):
        self.assertEqual(
            APP.memory_working_set_bytes({
                "usage": 1_000,
                "stats": {"total_inactive_file": 1_200, "inactive_file": 200},
            }),
            800,
        )

    def test_returns_raw_usage_when_cache_is_missing_or_invalid(self):
        self.assertEqual(APP.memory_working_set_bytes({"usage": 1_000, "stats": {}}), 1_000)
        self.assertEqual(
            APP.memory_working_set_bytes({"usage": 1_000, "stats": {"inactive_file": 1_000}}),
            1_000,
        )
        self.assertEqual(
            APP.memory_working_set_bytes({"usage": 1_000, "stats": {"inactive_file": 1_200}}),
            1_000,
        )


if __name__ == "__main__":
    unittest.main()
