"""Real OpenSCAD boundary tests; no renderer or solid mocks."""
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAD = ROOT / 'cad' / 'dock.scad'


def render(source=CAD, **definitions):
    with tempfile.TemporaryDirectory(prefix='dock-test-') as tmp:
        output = Path(tmp) / 'part.stl'
        command = ['openscad', '--hardwarnings', '--export-format', 'binstl', '-o', str(output)]
        for key, value in definitions.items():
            command += ['-D', f'{key}={json.dumps(value)}']
        result = subprocess.run(command + [str(source)], capture_output=True, text=True, timeout=120)
        data = output.read_bytes() if output.exists() else b''
        return result.returncode, result.stdout + result.stderr, data


class ScadCase(unittest.TestCase):
    def assert_solid(self, result):
        code, log, data = result
        self.assertEqual(code, 0, log)
        self.assertNotIn('WARNING', log, log)
        self.assertNotIn('ERROR', log, log)
        self.assertGreater(len(data), 84, log)
        facets = struct.unpack('<I', data[80:84])[0]
        self.assertGreater(facets, 0, log)
        self.assertEqual(len(data), 84 + 50 * facets, log)


    def assert_empty(self, result):
        code, log, data = result
        self.assertNotEqual(code, 0, log)
        self.assertIn('Current top level object is empty.', log)
        self.assertNotIn('WARNING', log)
        self.assertNotIn('ERROR', log)
        self.assertFalse(data)

    def check(self, name, **definitions):
        return render(ROOT / 'tests' / 'geometry_checks.scad', check=name, **definitions)


class GeometryTests(ScadCase):
    def test_reference_compiles(self):
        self.assert_solid(render(part='reference'))

    def test_invalid_dimensions_rejected(self):
        for dimension in ('tablet_w', 'tablet_h', 'tablet_t'):
            with self.subTest(dimension=dimension):
                code, log, _ = render(part='reference', **{dimension: 0})
                self.assertNotEqual(code, 0)
                self.assertIn('positive tablet dimensions', log)

    def test_unknown_part_rejected(self):
        code, log, _ = render(part='missing')
        self.assertNotEqual(code, 0)
        self.assertIn('unknown part', log)

    def test_unknown_connector_rejected(self):
        code, log, _ = render(connector='missing')
        self.assertNotEqual(code, 0)
        self.assertIn('unknown connector', log)


class MotionTests(ScadCase):
    def test_slide_then_yaw_then_lift_clearance(self):
        self.assert_empty(self.check('slide_then_yaw_then_lift_clearance'))
        self.assert_empty(self.check('slide_then_yaw_then_lift_clearance', tablet_w=100, tablet_h=60, corner_r=5))

    def test_connected_yaw_is_blocked(self):
        for slide in (0, 3, 5.9):
            with self.subTest(slide=slide):
                self.assert_solid(self.check('connected_yaw_is_blocked', probe_slide=slide))

    def test_docked_lift_is_blocked(self):
        self.assert_solid(self.check('docked_lift_is_blocked'))

    def test_docked_left_edge_outward_is_blocked(self):
        self.assert_solid(self.check('docked_left_edge_outward_is_blocked'))

    def test_renderer_classification(self):
        fixtures = [('cube(2);', 'solid'),
                    ('intersection(){cube(2);translate([3,0,0])cube(2);}', 'empty'),
                    ('not valid scad !!!', 'error'),
                    ('union(){cube(2);translate([2,2,0])cube(2);}', 'warning')]
        with tempfile.TemporaryDirectory() as tmp:
            for source, expected in fixtures:
                with self.subTest(expected=expected):
                    path = Path(tmp) / 'fixture.scad'
                    path.write_text(source)
                    result = render(path)
                    if expected == 'solid': self.assert_solid(result)
                    elif expected == 'empty': self.assert_empty(result)
                    else:
                        with self.assertRaises(AssertionError): self.assert_solid(result)
                        with self.assertRaises(AssertionError): self.assert_empty(result)


class ConnectorTests(ScadCase):
    def test_both_insert_interfaces_match(self):
        for kind in ('essager', 'cd0700'):
            self.assert_solid(render(part='insert', connector=kind))
            self.assert_empty(self.check('both_insert_interfaces_match', connector=kind))

    def test_connector_clear_before_yaw(self):
        for kind in ('essager', 'cd0700'):
            self.assert_empty(self.check('connector_clear_before_yaw', connector=kind))

    def test_cable_outlets_open(self):
        for kind in ('essager', 'cd0700'):
            self.assert_empty(self.check('cable_outlets_open', connector=kind))

    def test_device_feature_clearances(self):
        self.assert_empty(self.check('device_feature_clearances'))


class SupportTests(ScadCase):
    def test_cradle_is_single_cgal_volume(self):
        result=render(part='cradle')
        self.assert_solid(result)
        self.assertRegex(result[1], r'Volumes:\s+2\b', 'cradle contains disconnected solids or enclosed voids')

    def test_height_and_pitch_limits(self):
        for height in (0,25,50):
            for pitch in (-15,0,15):
                self.assert_solid(render(part='reference', height_mm=height, pitch_deg=pitch))
        for values in ({'height_mm':-1},{'height_mm':51},{'pitch_deg':-16},{'pitch_deg':16}):
            code,log,_=render(part='reference', **values)
            self.assertNotEqual(code,0,log)
            self.assertIn('adjustment',log)

    def test_slide_overlap_at_max_height(self):
        self.assert_solid(self.check('slide_overlap_at_max_height'))

    def test_support_and_cable_clearance_at_extremes(self):
        for height in (0,25,50):
            for pitch in (-15,0,15):
                with self.subTest(height=height,pitch=pitch):
                    self.assert_empty(self.check('support_and_cable_clearance_at_extremes', height_mm=height,pitch_deg=pitch))

    def test_pitch_mating_clearance(self):
        for pitch in range(-15,16,5):
            self.assert_empty(self.check('pitch_mating_clearance',pitch_deg=pitch))


if __name__ == '__main__':
    unittest.main()
