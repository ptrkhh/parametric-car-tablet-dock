"""Regenerate build/prototype/: every printable STL, the clearance variants, previews and manifest.json.

Run from the repository root with `python3 export.py` (WSL; previews need xvfb-run).
Each STL must render without diagnostics, form one connected solid and rest on Z=0,
the same gates as test_all_printable_parts_export. build/ is git-ignored.
"""
import hashlib
import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tests"))
from test_geometry import DOCK, KINDS, PRINTABLE, render_stl, stl_bounds, workers  # noqa: E402

OUT = ROOT / "build" / "prototype"
GAPS = (0.3, 0.5, 0.7)  # fit variants named in docs/validation.md
SOURCES = ["README.md", "cad/dock.scad", "cad/parameters.scad", "tests/geometry_checks.scad",
           "tests/test_geometry.py", "docs/measurements.md", "docs/validation.md"]
# name, OpenSCAD eye and centre, overrides. Orthographic, so only the direction matters.
VIEWS = [
    ("assembly-front", "0,-550,160,0,25,130", {}),
    ("assembly-rear", "400,500,330,0,25,145", {}),
    ("release", "380,-500,300,0,40,130", {"slide_mm": 8, "release_yaw_deg": 12}),
    ("release-top", "0,0,650,0,30,100", {"slide_mm": 8, "release_yaw_deg": 12}),
    ("high-pitch-up", "350,-500,300,0,65,160", {"height_mm": 50, "pitch_deg": 15}),
    ("high-pitch-down", "350,-500,300,0,65,160", {"height_mm": 50, "pitch_deg": -15}),
    ("low-pitch-down", "350,-500,300,0,40,40", {"pitch_deg": -15}),
    ("feet-angles", "380,500,290,0,65,130", {"foot_roll": [15, -15, 15], "foot_pitch": [-15, 15, -15]}),
]


def jobs():
    for d in PRINTABLE:
        yield d["part"] + ("-" + d["connector"] if "connector" in d else ""), d
    for g in GAPS:
        for kind in KINDS:
            yield f"insert-{kind}-{g}", {"part": "insert", "connector": kind, "insert_clearance": g}
        yield f"cover-{g}", {"part": "cover", "insert_clearance": g}
        yield f"motion_sample-{g}", {"part": "motion_sample", "clearance": g}


def build(job):
    name, defines = job
    count, stl, log = render_stl(DOCK, **defines)
    assert count and stl, f"{name}: empty render"
    lo, hi = stl_bounds(stl)
    assert abs(lo[2]) < 0.01, f"{name}: not on the bed, min Z {lo[2]}"
    assert re.findall(r"Volumes:\s+(\d+)", log) in ([], ["2"]), f"{name}: not one connected solid"
    (OUT / f"{name}.stl").write_bytes(stl)
    return {"file": f"{name}.stl", "overrides": defines, "sha256": hashlib.sha256(stl).hexdigest(),
            "bounds_mm": [lo, hi], "size_mm": [round(b - a, 3) for a, b in zip(lo, hi)]}


def view(name, camera, defines):
    path = OUT / f"{name}.png"
    cmd = ["xvfb-run", "-a", "openscad", "--hardwarnings", "-o", str(path), f"--camera={camera}",
           "--projection=o", "--viewall", "--autocenter", "--imgsize=1200,850"]
    for key, value in defines.items():
        cmd += ["-D", f"{key}={json.dumps(value)}"]
    run = subprocess.run(cmd + [str(DOCK)], capture_output=True, text=True, timeout=300)
    log = run.stdout + run.stderr
    assert run.returncode == 0 and "WARNING" not in log and "ERROR" not in log, f"{name}: {log}"
    return {"file": path.name, "overrides": {"part": "assembly", **defines}, "camera": camera,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=workers()) as pool:
        stls = list(pool.map(build, list(jobs())))
    for a in stls:
        print(a["file"], a["size_mm"], flush=True)
    pngs = [view(*v) for v in VIEWS]
    volume = [float(v) for v in re.search(r"^build_volume = \[([^\]]*)\]", (ROOT / "cad/parameters.scad").read_text(), re.M)
              .group(1).split(",")]
    git = lambda *a: subprocess.check_output(["git", *a], cwd=ROOT, text=True).strip()
    cad = subprocess.run(["openscad", "--version"], capture_output=True, text=True)
    manifest = {
        # ponytail: no revision when the tree is dirty; the hashes below still identify the sources.
        "source_revision": None if git("status", "--porcelain") else git("rev-parse", "HEAD"),
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "cad_version": (cad.stdout + cad.stderr).strip(),
        "qualification": "Geometric prototype only; physical and print-service gates unrun.",
        "units": "mm",
        "defaults": "cad/parameters.scad",
        "build_volume_mm": volume if min(volume) > 0 else None,
        "source_hashes": {n: hashlib.sha256((ROOT / n).read_bytes()).hexdigest() for n in SOURCES},
        "artifacts": stls + pngs,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Exported {len(stls)} STLs and {len(pngs)} views to {OUT.relative_to(ROOT)}.")


if __name__ == "__main__":
    main()
