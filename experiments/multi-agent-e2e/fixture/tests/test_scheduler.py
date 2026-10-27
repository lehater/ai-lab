import unittest

from scheduler import intervals_overlap


class IntervalTests(unittest.TestCase):
    def test_partially_overlapping(self):
        self.assertTrue(intervals_overlap((10, 20), (15, 25)))

    def test_contained(self):
        self.assertTrue(intervals_overlap((10, 30), (15, 20)))

    def test_disjoint(self):
        self.assertFalse(intervals_overlap((10, 20), (25, 30)))

    def test_touching_boundary_is_not_overlap(self):
        # The sole intentionally RED test in the initial fixture.
        self.assertFalse(intervals_overlap((10, 20), (20, 30)))

    def test_reverse_touching_boundary_is_not_overlap(self):
        self.assertFalse(intervals_overlap((20, 30), (10, 20)))

    def test_invalid_interval(self):
        with self.assertRaises(ValueError):
            intervals_overlap((10, 10), (12, 20))


if __name__ == "__main__":
    unittest.main()
