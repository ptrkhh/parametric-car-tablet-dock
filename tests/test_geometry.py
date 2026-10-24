"""Geometry checks run through OpenSCAD in temporary directories.

Each render must finish without ERROR/WARNING diagnostics. A render either
produces a binary STL with at least one facet, or OpenSCAD's exact
empty-top-level diagnostic with no STL; anything else is a failure.
"""

import json
import os
import struct
import subprocess
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCK = ROOT / "cad" / "dock.scad"
CHECKS = ROOT / "tests" / "geometry_checks.scad"
EMPTY = "Current top level object is empty."
# Full tablet and the reduced motion sample share every retention check.
SIZES = (False, True)
# Yaw stage: 25 poses at 1/24 of release_yaw (0.5 degrees at the default 12), endpoints included.
YAW_FRACTIONS = [i / 24 for i in range(25)]
KINDS = ("essager", "cd0700")


class RenderError(AssertionError):
    pass


def scad_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    return json.dumps(value)


def openscad(path, defines):
    """Return (exit code, combined log, STL bytes or None)."""
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out.stl"
        cmd = ["openscad", "--hardwarnings", "--export-format", "binstl", "-o", str(out)]
        for key, value in defines.items():
            cmd += ["-D", f"{key}={scad_value(value)}"]
        proc = subprocess.run(cmd + [str(path)], capture_output=True, text=True, timeout=900)
        stl = out.read_bytes() if out.exists() else None
    return proc.returncode, proc.stdout + proc.stderr, stl


def diagnostics(log):
    return [line for line in log.splitlines()
            if line.lstrip().startswith(("ERROR", "WARNING", "EXPORT-WARNING"))]


def facet_count(stl):
    if len(stl) < 84:
        raise RenderError(f"STL too short: {len(stl)} bytes")
    (count,) = struct.unpack_from("<I", stl, 80)
    if len(stl) != 84 + 50 * count:
        raise RenderError(f"STL size {len(stl)} does not match {count} facets")
    return count


def render(path, **defines):
    """Facet count of a clean render; 0 means OpenSCAD reported an empty result."""
    rc, log, stl = openscad(path, defines)
    bad = diagnostics(log)
    if bad:
        raise RenderError(f"{path.name} {defines}: {bad[:5]}")
    if rc == 0 and stl is not None:
        count = facet_count(stl)
        if count > 0:
            return count
    if rc == 1 and stl is None and EMPTY in log:
        return 0
    raise RenderError(f"{path.name} {defines}: exit {rc}\n{log[-2000:]}")


def checks(name, variants):
    """Facet counts of one fixture rendered for each define dict, in parallel."""
    with ThreadPoolExecutor(max_workers=os.cpu_count()) as pool:
        return list(pool.map(lambda d: render(CHECKS, check=name, **d), variants))


class GeometryTest(unittest.TestCase):
    def assert_all_empty(self, name, variants):
        for variant, count in zip(variants, checks(name, variants)):
            self.assertEqual(count, 0, f"{name} {variant}: geometry intersects")

    def assert_all_blocked(self, name, variants):
        for variant, count in zip(variants, checks(name, variants)):
            self.assertGreater(count, 0, f"{name} {variant}: motion not blocked")

    def test_runner_solid_fixture(self):
        self.assertGreater(render(CHECKS, check="runner_solid"), 0)

    def test_runner_empty_fixture(self):
        self.assertEqual(render(CHECKS, check="runner_empty"), 0)

    def test_runner_broken_fixture(self):
        with tempfile.TemporaryDirectory() as tmp:
            broken = Path(tmp) / "broken.scad"
            broken.write_text("cube(1)\n")  # missing semicolon: parse error
            with self.assertRaises(RenderError):
                render(broken)
        with self.assertRaises(RenderError):
            render(CHECKS, check="no_such_check")

    def test_slide_then_yaw_then_lift_clearance(self):
        variants = [{"sample": s, "stage": "slide"} for s in SIZES]
        variants += [{"sample": s, "stage": "lift"} for s in SIZES]
        variants += [{"sample": s, "stage": "yaw", "fraction": f} for s in SIZES for f in YAW_FRACTIONS]
        self.assert_all_empty("slide_then_yaw_then_lift_clearance", variants)

    def test_lift_without_enough_yaw_collides(self):
        # Negative control: the lift fixture must detect the left roof when the yaw is too small,
        # so an empty or misplaced cradle cannot pass the allowed-motion checks.
        variants = [{"sample": False, "stage": "lift", "release_yaw": 2},
                    {"sample": True, "stage": "lift", "release_yaw": 8}]
        self.assert_all_blocked("slide_then_yaw_then_lift_clearance", variants)

    def test_connected_yaw_is_blocked(self):
        # 0, 50 and 100 % of plug_engagement: yaw must stay blocked until the plug is out.
        variants = [{"sample": s, "fraction": f} for s in SIZES for f in (0, 0.5, 1)]
        self.assert_all_blocked("connected_yaw_is_blocked", variants)

    def test_docked_lift_is_blocked(self):
        variants = [{"sample": s, "side": side} for s in SIZES for side in ("left", "right")]
        self.assert_all_blocked("docked_lift_is_blocked", variants)

    def test_docked_left_edge_outward_is_blocked(self):
        self.assert_all_blocked("docked_left_edge_outward_is_blocked", [{"sample": s} for s in SIZES])

    def test_detent_engages_docked_tablet(self):
        self.assert_all_blocked("detent_engages_docked_tablet", [{"sample": s} for s in SIZES])

    def test_invalid_mechanism_parameters_rejected(self):
        cases = [
            ("release_travel must exceed plug_engagement + clearance", {"release_travel": 6.4}),
            ("clearance must be positive", {"clearance": 0}),
            ("yaw_relief must exceed release_yaw", {"yaw_relief": 12}),
            ("detent needs 0 < preload < rise < corner_r", {"detent_preload": 0}),
            ("detent needs 0 < preload < rise < corner_r", {"detent_preload": 1.5}),
            ("insert_clearance must be in (0, 1]", {"insert_clearance": 0}),
            ("insert_clearance must be in (0, 1]", {"insert_clearance": -0.2}),
            ("insert wall between tablet and connector body too thin", {"connector_gap": 1.2}),
        ]
        for message, defines in cases:
            with self.subTest(**defines):
                self.assert_rejected(message, **defines)

    def test_both_insert_interfaces_match(self):
        self.assert_all_empty("both_insert_interfaces_match", [{"kind": k} for k in KINDS])

    def test_connector_body_captured(self):
        variants = [{"kind": k, "probe": p} for k in KINDS for p in range(6)]
        self.assert_all_blocked("connector_body_captured", variants)

    def test_connector_clear_before_yaw(self):
        variants = [{"kind": k, "stage": s} for k in KINDS for s in ("slide", "lift")]
        variants += [{"kind": k, "stage": "yaw", "fraction": i / 12} for k in KINDS for i in range(13)]
        self.assert_all_empty("connector_clear_before_yaw", variants)

    def test_cable_outlets_open(self):
        self.assert_all_empty("cable_outlets_open", [{"kind": k} for k in KINDS])

    def test_device_feature_clearances(self):
        self.assertGreater(render(CHECKS, check="feature_witnesses_present"), 0)
        self.assert_all_empty("device_feature_clearances", [{"kind": k} for k in KINDS])

    def test_connector_parts_export(self):
        for defines in ({"part": "insert", "connector": "essager"}, {"part": "insert", "connector": "cd0700"},
                        {"part": "cover"}, {"part": "fit_sample"}):
            with self.subTest(**defines):
                self.assertGreater(render(DOCK, **defines), 0)

    def test_motion_sample_exports(self):
        for name in ("cradle", "motion_sample", "surrogate"):
            with self.subTest(part=name):
                self.assertGreater(render(DOCK, part=name), 0)
    def assert_rejected(self, message, **defines):
        rc, log, stl = openscad(DOCK, defines)
        self.assertNotEqual(rc, 0, f"{defines} rendered successfully")
        self.assertIsNone(stl)
        self.assertIn(message, log)

    def test_reference_compiles(self):
        self.assertGreater(render(DOCK, part="reference"), 0)
        self.assertGreater(render(DOCK, part="assembly"), 0)

    def test_invalid_dimensions_rejected(self):
        for name in ("tablet_w", "tablet_t", "tablet_h"):
            for bad in (0, -1):
                with self.subTest(name=name, value=bad):
                    self.assert_rejected("tablet dimensions must be positive", **{name: bad})

    def test_unknown_part_rejected(self):
        self.assert_rejected("unknown part", part="cradel")

    def test_unknown_connector_rejected(self):
        self.assert_rejected("unknown connector", connector="usb-a")


if __name__ == "__main__":
    unittest.main()
