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


class GeometryTests(unittest.TestCase):
    def assert_solid(self, result):
        code, log, data = result
        self.assertEqual(code, 0, log)
        self.assertNotIn('WARNING', log, log)
        self.assertNotIn('ERROR', log, log)
        self.assertGreater(len(data), 84, log)
        facets = struct.unpack('<I', data[80:84])[0]
        self.assertGreater(facets, 0, log)
        self.assertEqual(len(data), 84 + 50 * facets, log)

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


if __name__ == '__main__':
    unittest.main()
