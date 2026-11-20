"""Geometry checks run through OpenSCAD in temporary directories.

Each render must finish without ERROR/WARNING diagnostics. A render either
produces a binary STL with at least one facet, or OpenSCAD's exact
empty-top-level diagnostic with no STL; anything else is a failure.
"""

import json
import os
import re
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
# Height and pitch extremes plus midpoints.
POSES = [(hh, pp) for hh in (0, 25, 50) for pp in (-15, 0, 15)]
# Foot (pitch, roll): neutral and the four corners; the other foot takes the opposite corner.
FOOT_COMBOS = [(0, 0), (15, 15), (-15, -15), (15, -15), (-15, 15)]
# Every printed piece, in its bed orientation: dock parts and fit/mechanism samples.
PRINTABLE = [{"part": p} for p in ("cradle", "end_cap", "cover", "post", "carriage", "bridge", "ballast_lid", "foot_yoke",
                                   "tape_foot", "motion_sample", "surrogate", "fit_sample", "slide_sample",
                                   "pitch_joint")]
PRINTABLE += [{"part": "insert", "connector": k} for k in ("essager", "cd0700")]


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


def render_stl(path, **defines):
    """(facet count, STL bytes, log) of a clean render; 0 facets means an empty result."""
    rc, log, stl = openscad(path, defines)
    bad = diagnostics(log)
    if bad:
        raise RenderError(f"{path.name} {defines}: {bad[:5]}")
    if rc == 0 and stl is not None:
        count = facet_count(stl)
        if count > 0:
            return count, stl, log
    if rc == 1 and stl is None and EMPTY in log:
        return 0, None, log
    raise RenderError(f"{path.name} {defines}: exit {rc}\n{log[-2000:]}")


def render(path, **defines):
    return render_stl(path, **defines)[0]


def stl_bounds(stl):
    """([min x, y, z], [max x, y, z]) of a binary STL."""
    count = facet_count(stl)
    pts = [struct.unpack_from("<3f", stl, 84 + 50 * i + 12 + 12 * k) for i in range(count) for k in range(3)]
    return [min(p[a] for p in pts) for a in range(3)], [max(p[a] for p in pts) for a in range(3)]


def workers():
    # A CGAL render can take several hundred MB; stay inside available memory, not just cores.
    try:
        with open("/proc/meminfo") as meminfo:
            avail_mb = next(int(line.split()[1]) for line in meminfo if line.startswith("MemAvailable")) // 1024
    except (OSError, StopIteration):
        avail_mb = 4000
    return max(1, min(os.cpu_count() or 1, avail_mb // 400))


def checks(name, variants):
    """Facet counts of one fixture rendered for each define dict, in parallel."""
    with ThreadPoolExecutor(max_workers=workers()) as pool:
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

    def test_fixture_does_not_shadow_cad(self):
        # The fixture includes dock.scad, so a same-named module, function or variable would
        # silently replace the CAD definition inside every check. Only `part` is overridden.
        def names(path):
            return set(re.findall(r"^(?:module|function)\s+(\w+)|^(\w+)\s*=", path.read_text(), re.M))
        cad = names(DOCK) | names(ROOT / "cad" / "parameters.scad")
        clash = {n for pair in names(CHECKS) & cad for n in pair if n} - {"part"}
        self.assertEqual(clash, set())

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

    def test_connected_lift_is_blocked(self):
        # At 0, 50 and 100 % of plug_engagement: no lift, and no 1-degree roll about the left end.
        variants = [{"sample": s, "fraction": f, "probe": p} for s in SIZES for f in (0, 0.5, 1) for p in (0, 1)]
        self.assert_all_blocked("connected_lift_is_blocked", variants)

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

    def test_essager_body_held_in_z(self):
        self.assert_all_blocked("connector_body_held_in_z", [{"kind": "essager", "probe": p} for p in (0, 1)])

    @unittest.expectedFailure
    def test_cd0700_body_held_in_z(self):
        # OPEN GATE (docs/validation.md): the CD0700 outlets are sized for the placeholder
        # downstream plug bodies, which exceed its end faces, so only the plug shell holds the
        # body along Z. Remove expectedFailure once measured plugs allow end ledges.
        self.assert_all_blocked("connector_body_held_in_z", [{"kind": "cd0700", "probe": p} for p in (0, 1)])

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

    def test_height_and_pitch_limits(self):
        cases = [("height_mm out of range", {"height_mm": -1}), ("height_mm out of range", {"height_mm": 51}),
                 ("pitch_deg out of range", {"pitch_deg": -20}), ("pitch_deg out of range", {"pitch_deg": 20}),
                 ("pitch_deg must be a multiple of pitch_step", {"pitch_deg": 7})]
        for message, defines in cases:
            with self.subTest(**defines):
                self.assert_rejected(message, **defines)
        # Every index from -15 to +15 meshes with axial play; 1 degree off an index locks.
        self.assert_all_empty("pitch_teeth_lock", [{"height": hh, "pitch": pp} for hh in (0, 50)
                                                   for pp in range(-15, 16, 5)])
        self.assert_all_blocked("pitch_teeth_lock", [{"pitch": pp + d} for pp in (-15, 0, 15) for d in (-1, 1)])

    def test_slide_engagement(self):
        # The rail head reaches both ends of the carriage sleeve at zero and full height.
        self.assert_all_blocked("slide_engagement", [{"height": hh, "probe": p} for hh in (0, 50) for p in (0, 1)])
        self.assert_rejected("post too short for the pivot height", tablet_bottom_z=-40)

    def test_tablet_below_pads(self):
        # At the lowest height the tablet reaches pad_drop below the tape faces at every pitch index.
        self.assert_all_blocked("tablet_below_pads", [{"pitch": pp} for pp in range(-15, 16, 5)])
        # Negative control: 9 mm higher, the screen-up extreme no longer reaches below the tape.
        self.assert_all_empty("tablet_below_pads", [{"pitch": 15, "tablet_bottom_z": -20}])

    def test_dashboard_nose_keepout(self):
        variants = [{"height": hh, "pitch": pp, "kind": "cd0700"} for hh, pp in POSES]
        self.assert_all_empty("dashboard_nose_keepout", variants)
        # Negative control: feet 8 mm further forward put the swept cradle into the keep-out.
        self.assert_all_blocked("dashboard_nose_keepout", [{"pitch": -15, "kind": "cd0700", "foot_y": 100}])

    def test_mechanism_hidden_front(self):
        # Occupant view at the lowest height: post, carriage and base hide behind the tablet and housing.
        self.assert_all_empty("mechanism_hidden_front", [{"pitch": pp} for pp in (-15, 0, 15)])
        # Negative controls: at full height the base shows below the housing; a pivot 71 mm
        # higher puts the fork above the tablet's top edge.
        self.assert_all_blocked("mechanism_hidden_front", [{"height": 50}, {"pivot": [76, 80]}])

    def test_housing_fit(self):
        self.assert_all_empty("housing_fit", [{"kind": k} for k in KINDS])

    def test_snaps_hold(self):
        # No screws on the end cap, cover or insert: each must be stopped by its tongues.
        variants = [{"probe": p} for p in range(4)] + [{"probe": p, "kind": k} for p in (4, 5) for k in KINDS]
        self.assert_all_blocked("snaps_hold", variants)
        # Negative control: without barbs the end cap and the cover pull straight off.
        self.assert_all_empty("snaps_hold", [{"probe": p, "snap": [1.8, 5, 0, 0.3]} for p in (0, 2)])

    def test_snaps_go_in(self):
        # Every clipped part reaches its seat along one straight push, with the cables plugged in.
        plain = {"snap": [1.8, 5, 0, 0.3], "lid_fit": [1.2, 0.3, 0]}
        variants = [dict(plain, probe=p, fraction=f / 5, kind=k) for p in (0, 1) for f in range(1, 6) for k in KINDS]
        variants += [dict(plain, probe=2, fraction=f / 5) for f in range(1, 6)]
        self.assert_all_empty("snaps_go_in", variants)
        # Negative control: with barbs and bump the rigid shapes do not pass, so the path is really swept.
        self.assert_all_blocked("snaps_go_in", [{"probe": p, "fraction": 0.2} for p in (0, 1, 2)])

    def test_support_and_cable_clearance_at_extremes(self):
        base = [{"height": hh, "pitch": pp, "kind": "cd0700"} for hh, pp in POSES]
        variants = [dict(v, stage=s) for v in base for s in ("slide", "lift", "parts", "cables", "camera")]
        variants += [dict(v, stage="yaw", fraction=i / 6) for v in base for i in range(7)]
        self.assert_all_empty("support_and_cable_clearance_at_extremes", variants)

    def test_support_fasteners_clear(self):
        variants = [{"height": hh, "pitch": pp, "kind": "cd0700"} for hh, pp in POSES]
        self.assert_all_empty("support_fasteners_clear", variants)
        self.assert_all_empty("support_fasteners_bearing", [{"height": hh} for hh in (0, 50)])
        # One bolt size: the old 30 mm rail head made the sleeve wider than an M5 x 35 reaches.
        self.assert_rejected("too wide for the standard M5 bolt", tongue=[30, 18])

    def test_support_parts_export(self):
        for name in ("post", "carriage", "pitch_joint", "slide_sample"):
            with self.subTest(part=name):
                self.assertGreater(render(DOCK, part=name), 0)

    def test_two_axis_foot_adjustment(self):
        for defines in ({"foot_pitch": [16, 0, 0]}, {"foot_roll": [0, 0, -16]}):
            with self.subTest(**defines):
                self.assert_rejected("foot angles out of range", **defines)
        self.assert_rejected("take [left, right, rear]", foot_pitch=[0, 0])
        contact = [{"foot_side": s, "fpitch": p, "froll": r} for s in (-1, 1, 0) for p, r in FOOT_COMBOS]
        self.assert_all_empty("foot_contact", contact)
        self.assert_all_empty("foot_joints_clear", [{"fpitch": p, "froll": r} for p, r in FOOT_COMBOS])

    def test_curved_dashboard_breaks_flat_contact(self):
        # Tangency is not contact: a flat pad on a 250 mm radius leaves a gap at its ends.
        self.assert_all_blocked("curved_dashboard_gap", [{"foot_side": 1}])

    def test_foot_clamps_have_tool_access(self):
        self.assert_all_empty("foot_clamps_tool_access", [{"fpitch": p, "froll": r} for p, r in FOOT_COMBOS])
        self.assert_all_empty("foot_clamps_bearing", [{"fpitch": p, "froll": r} for p, r in FOOT_COMBOS[:2]])

    def test_ballast_fit(self):
        self.assert_all_empty("ballast_fit", [{}])
        # Negative control: weights 1 mm larger per face than the stated inside do not fit.
        # The lid cannot lift (probe 1) or slide back out (probe 2).
        self.assert_all_blocked("ballast_fit", [{"grow": 1}, {"probe": 1}, {"probe": 2}])
        # Negative controls: upright lips let the lid lift; without the bump it slides out.
        self.assert_all_empty("ballast_fit", [{"probe": 1, "lid_fit": [2.5, 0.3, 0.6]}, {"probe": 2, "lid_fit": [1.2, 0.3, 0]}])
        # A tail too short would put the tray over the front pads.
        self.assert_rejected("rear_reach too short", rear_reach=80)

    def test_base_clears_removal_envelope(self):
        base = [{"height": hh, "pitch": pp, "kind": "cd0700"} for hh, pp in POSES]
        variants = [dict(v, stage=s) for v in base for s in ("slide", "lift")]
        variants += [dict(v, stage="yaw", fraction=i / 3) for v in base for i in range(4)]
        # Height only lifts the cradle away from the base, so parts are checked at height 0.
        variants += [{"height": 0, "pitch": pp, "kind": "cd0700", "stage": "parts", "fpitch": p, "froll": r}
                     for pp in (-15, 0, 15) for p, r in FOOT_COMBOS]
        self.assert_all_empty("base_clears_removal_envelope", variants)

    def test_base_parts_export(self):
        for name in ("bridge", "ballast_lid", "foot_yoke", "tape_foot"):
            with self.subTest(part=name):
                self.assertGreater(render(DOCK, part=name), 0)

    def printable_exports(self):
        with ThreadPoolExecutor(max_workers=workers()) as pool:
            return list(pool.map(lambda d: (d, render_stl(DOCK, **d)), PRINTABLE))

    def test_all_printable_parts_export(self):
        for defines, (count, stl, log) in self.printable_exports():
            with self.subTest(**defines):
                self.assertGreater(count, 0)
                # CGAL reports the outer volume plus one per connected solid.
                volumes = re.findall(r"Volumes:\s+(\d+)", log)
                self.assertIn(volumes, ([], ["2"]), "not one connected solid")
                lo, hi = stl_bounds(stl)
                self.assertAlmostEqual(lo[2], 0, places=2, msg="not on the bed")
                if defines["part"] == "surrogate":
                    sizes = sorted(round(b - a, 2) for a, b in zip(lo, hi))
                    self.assertEqual(sizes, [6.3, 60, 100])

    def test_declared_build_volume(self):
        text = (ROOT / "cad" / "parameters.scad").read_text()
        volume = [float(v) for v in re.search(r"^build_volume = \[([^\]]*)\]", text, re.M).group(1).split(",")]
        if min(volume) <= 0:
            self.skipTest("print service build volume unknown: part fit UNVERIFIED")
        for defines, (count, stl, log) in self.printable_exports():
            lo, hi = stl_bounds(stl)
            size = [b - a for a, b in zip(lo, hi)]
            with self.subTest(**defines, size=[round(s, 1) for s in size]):
                # The part may turn 90 degrees on the bed; its height is fixed by the orientation.
                fits_xy = all(s <= v for s, v in zip(sorted(size[:2]), sorted(volume[:2])))
                self.assertTrue(fits_xy and size[2] <= volume[2])

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
