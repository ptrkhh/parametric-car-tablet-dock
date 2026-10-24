# Prototype validation record

This record separates digital geometry checks from physical qualification. No printed part, connector, tablet, dashboard, tape bond or vehicle has been tested.

Run the digital checks with `python3 -m unittest discover -s tests -v` (WSL Python 3, OpenSCAD 2021.01).

## Test runner

`tests/test_geometry.py` renders each case with `openscad --hardwarnings --export-format binstl` in a temporary directory. A render fails on any `ERROR`, `WARNING` or `EXPORT-WARNING` line, including CGAL warnings that exit 0. An expected-empty result needs exit code 1, the exact `Current top level object is empty.` diagnostic and no STL. A nonempty result needs a binary STL whose size matches a positive facet count. An unknown fixture name fails instead of passing as empty. This is not mesh-topology analysis.

## Cradle candidate

Removal: slide 8 mm left (`release_travel`), yaw 12 degrees clockwise from above (`release_yaw`) about the rear contact line at X=0 on the tablet back, then lift. Installation is the same path reversed. All values are provisional.

| Feature | Geometry | Purpose |
|---|---|---|
| Floor | Contact at the tablet bottom | Support |
| Central rear contact | 20 mm spine at X=0; bevelled 15 degrees (`yaw_relief`) on its left | Yaw pivot; inward stop |
| Left yaw pocket | Wedge behind the left half, 15 degrees from the tablet back, open upward | Lets the left end move inward and lift |
| Left wall | 0.5 mm beyond the fully slid left edge | Slide stop after release travel |
| Left lip | 5 mm over the front bezel, full height | Blocks the left edge moving outward |
| Left roof | 14 mm along the top edge from the docked left edge | Upward capture; the yawed left end lifts behind it |
| Right corner hooks | Front overlap 7.5 mm (`release_travel - clearance`), right stop, roof following the top-right corner arc | Block yaw while the plug is engaged; upward capture; right stop |
| Detent | 30 × 6 × 2 mm floor tongue rooted toward the centre; 45-degree bump | Automatic detent; compliant, excluded from rigid checks |

Contact faces (floor, rear contact, right stop) sit on the tablet faces. Faces the tablet moves past keep `clearance` (0.5 mm). USB engagement is assumed to be 6 mm until measured. `validate()` rejects a release travel that does not exceed `plug_engagement + clearance`, and a yaw relief that does not exceed the release yaw.

The roof length sets the yaw needed: the full tablet needs about 3.5 degrees to lift past the 14 mm roof, and the 100 mm motion sample needs about 11 degrees. Both use 12 degrees so the sample tests the same motion. The full tablet's right edge swings about 25 mm outward during the yaw; keep hands and cables clear there.

The detent bump apex is 1.5 mm (`detent_rise`) above the floor and 1 mm (`detent_preload`) inside the docked lower-left corner arc. Its contact normal is about 22 degrees from vertical. Most spring force therefore lifts the tablet against the roofs (taking up their 0.5 mm clearance) and only about 0.4 of it pushes the tablet right against the right stop. A higher rise steepens the holding face. Holding force, tongue strain (about 0.5 % at 1.5 mm tip deflection by beam estimate) and fatigue are physical tests.

## Digital motion checks

| Test | Fixture | Result |
|---|---|---|
| `test_slide_then_yaw_then_lift_clearance` | Slide and lift: hull of the stage's start and end envelopes (exact sweep for a convex body in translation). Yaw: 25 poses at 0.5-degree steps including both ends | Empty intersection with the rigid cradle, full size and motion sample |
| `test_connected_yaw_is_blocked` | 1-degree yaw at 0, 50 and 100 % of `plug_engagement` | Intersects the right hooks |
| `test_docked_lift_is_blocked` | 2 mm lift, checked separately on the left and right halves | Intersects the left roof and top-right hook |
| `test_docked_left_edge_outward_is_blocked` | 2 mm outward translation, left half only | Intersects the left lip |
| `test_detent_engages_docked_tablet` | Docked tablet against the bump | Intersects |
| `test_lift_without_enough_yaw_collides` | Lift after 2 degrees (full size) or 8 degrees (sample) | Intersects the left roof (negative control) |

The rigid cradle is everything except the detent bump above the floor, so along the checked path the tablet touches only the bump, whose height equals `detent_rise` by construction. Each tablet face is inset 0.01 mm (`collision_eps`) to avoid OpenSCAD's zero-volume face-contact export. Probe displacements exceed `clearance + collision_eps`. Fixture transforms are explicit matrices written independently of `tablet_pose()`.

A rotation probe about the right hook line was rejected: with a zero-overlap lip it still caught the back-left corner on a 0.03 mm sliver, a false pass.

Limits: these checks do not prove poses between yaw samples, combined escape paths (for example lift during a partial slide), forces, tolerance stacks or deformation. The envelope has no edge profile or camera island.

## Motion sample

`part="motion_sample"` is `cradle(100, 60)`: the same clearances, hook overlap, roof, lip, pocket angle and detent around a smaller tablet. `part="surrogate"` is the matching 100 × 60 × 6.3 mm dummy with the tablet's provisional `corner_r`, so the detent contact matches the full cradle. The sample does not reproduce the full tablet's lever arm or mass. It contains no connector or device cutouts. Do not force a real tablet into it.

```
openscad --hardwarnings --export-format binstl -D 'part="motion_sample"' -o build/prototype/motion_sample.stl cad/dock.scad
openscad --hardwarnings --export-format binstl -D 'part="surrogate"' -o build/prototype/surrogate.stl cad/dock.scad
```

Add `-D clearance=0.3` (or 0.7) to both commands for clearance variants, and mark each printed piece with its value.

Test procedure: deburr both pieces. Seat the surrogate (installation: place it tilted, press the right edge inward until flat, slide right over the detent). Then remove it: slide left against the detent to the wall, press the left edge inward, lift. Record any interference before changing a clearance, and recheck full-size geometry after any change.

Physical checks, all UNRUN: slide force, tongue deflection and recovery, bump wear, automatic reseating, retention under upward and outward load, repeated cycles, actual USB disengagement margin, screen/bezel coverage of the 7.5 mm hooks and 5 mm lip, and hot ABS creep.
