"""Focused tests for scanner response semantics."""

import json
import unittest

from exporter import parse_bucket_usage as parse_usage


class ParseUsageTest(unittest.TestCase):
    def test_empty_and_populated_bucket(self):
        raw = json.dumps({"lastUpdate": "2026-10-30T19:38:30.329447834Z", "bucketsUsageInfo": {"empty": {"size": 0, "objectsCount": 0}, "staging": {"size": 1105120, "objectsCount": 5}}})
        updated, buckets = parse_usage(raw)
        self.assertGreater(updated, 0)
        self.assertEqual(buckets, [("empty", 0, 0), ("staging", 1105120, 5)])

    def test_missing_or_invalid_measurements_fail(self):
        for usage in ({"size": None, "objectsCount": 1}, {"size": -1, "objectsCount": 1}, {"size": 0}):
            raw = json.dumps({"lastUpdate": "2026-10-30T19:38:30Z", "bucketsUsageInfo": {"bucket": usage}})
            with self.subTest(usage=usage), self.assertRaises((ValueError, KeyError)):
                parse_usage(raw)

    def test_missing_timestamp_is_not_a_fresh_sample(self):
        with self.assertRaises(KeyError):
            parse_usage('{"bucketsUsageInfo": {}}')


if __name__ == "__main__":
    unittest.main()
