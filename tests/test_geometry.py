"""Geometry checks run through OpenSCAD in temporary directories.

Each render must finish without ERROR/WARNING diagnostics. A render either
produces a binary STL with at least one facet, or OpenSCAD's exact
empty-top-level diagnostic with no STL; anything else is a failure.
"""

import json
import struct
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCK = ROOT / "cad" / "dock.scad"
EMPTY = "Current top level object is empty."


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


class GeometryTest(unittest.TestCase):
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
