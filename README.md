# Parametric dashboard tablet dock

OpenSCAD prototype for a bare Samsung Galaxy Tab S7 SM-T875, landscape with USB-C on the occupant's right. This is a geometric prototype and fit-sample package. **Do not order a full-size installed mount from these defaults yet.** Critical device/connector measurements, the print service's capabilities and vehicle qualification remain open.

The model includes a slide-left / left-edge-inward / lift cradle, two interchangeable connector inserts under a common cover, a keyed central mast with 50 mm height travel, pitch indexes from -15° to +15° in 5° steps, and two identical flat tape feet with independently adjustable angles. No dashboard-specific contours are generated.

## Start here

1. Read [measurement inputs](docs/measurements.md). Published values, assumptions and missing measurements are listed separately.
2. Inspect `cad/dock.scad` in OpenSCAD 2021.01 or later. Press F5 for assembly preview. All dimensions are millimetres.
3. Review the saved assembly images and fit coupons in `build/prototype/`. Generated files are ignored by Git; regenerate after changing parameters. `manifest.json` records their source revision, settings, bounds and hashes. The older concept illustration is exploratory; current CAD renders are the geometric reference.
4. Obtain actual measurements and service feedback using the checklist below. Start with unpowered coupons and the dummy tablet, not a complete installed mount.

The approved [design](docs/superpowers/specs/2026-10-19-tablet-dock-design.md), [implementation plan](docs/superpowers/plans/2026-10-19-tablet-dock.md), and [validation record](docs/validation.md) explain the intended behaviour and current evidence.

## Preview and export

Run from the repository root, using WSL Python and OpenSCAD:

```bash
python3 -m unittest discover -s tests -v
mkdir -p build/prototype
openscad --hardwarnings --export-format binstl -D 'part="cradle"' -o build/prototype/cradle.stl cad/dock.scad
openscad --hardwarnings --export-format binstl -D 'part="insert"' -D 'connector="cd0700"' -o build/prototype/insert-cd0700.stl cad/dock.scad
```

A successful exit alone is insufficient: reject any `WARNING`, `EXPORT-WARNING` or `ERROR` output. The Python suite does this automatically. Expected empty collision checks deliberately produce no STL.

Set `part="assembly"` for the assembled view. Example settings are `height_mm=50`, `pitch_deg=15`, `slide_mm=8`, `release_yaw_deg=12` and `lift_mm=0`. Removal controls are animation inputs; a render of an arbitrary pose is not proof that the path to it is safe. Coordinates: X occupant-right, Y toward the windshield, Z up. OpenSCAD Front is the occupant view. Positive pitch faces the screen toward the roof.

Change `connector` between `"essager"` and `"cd0700"`. Set feet using `foot_pitch=[left,right]` (about X, fore/aft slope) and `foot_roll=[left,right]` (about Y, side-to-side slope), each within ±15°. These are model limits, not physical hard stops. Changing any geometry requires rerunning the relevant fixtures with those measurements; the suite establishes only its explicitly tested configurations.

## Printable components and coupons

Each part selector exports one intended connected component in a candidate bed orientation. The service must review supports, layers, flatness, shrinkage, nozzle resolution and usable build volume before accepting that orientation. No slice profile or service build volume has been supplied.

| Selector | Quantity | Candidate orientation / concern |
|---|---:|---|
| `cradle` | 1 | Back toward bed; integrated hinge makes substantial supports likely. Service review required. |
| `insert` | 1 selected variant | Rear face down; inspect body lips, outlet slots and tolerances. |
| `cover` | 1 | Front face down; cosmetic face and cable-end access matter. |
| `mast_outer` | 1 | Flange down; check layer strength under bending and clamp load. |
| `mast_inner` | 1 | Side down; protect fine pitch teeth and slot accuracy. |
| `bridge` | 1 | Top face down; inspect nut bosses and pivot bores. |
| `foot_yoke` | 2 identical | Side down; inspect both pivot bores and nut pocket. |
| `tape_foot` | 2 identical | Flat tape face down; require an approved smooth, flat bonding face. |
| `motion_sample`, `surrogate` | 1 each | Small unpowered mechanism and dummy tablet. |
| `fit_sample` | Both variants | Same connector insert; compare clearances 0.3 / 0.5 / 0.7 mm. |
| `slide_sample`, `pitch_joint`, `joint_rotor` | 1 each | Reduced clamp/joint coupons; use `mast_inner` for the slide fit. |

ABS is the proposed final candidate, pending grade and service review. PLA may be used for room-temperature fit samples only; a successful PLA fit does not qualify an ABS part or an in-car installation. Infill, walls, layer height, orientation, supports, shrink compensation and annealing are **unset** until the service proposes a process. Record the actual settings and filament batch with every tested print.

## Provisional hardware list

| Item | Quantity | Location |
|---|---:|---|
| M3 × 25 socket cap bolt + DIN 934 nut | 2 pairs | Connector cover / insert / cradle |
| M5 × 50 socket cap bolt + DIN 934 nut | 2 pairs | Height clamp and pitch clamp |
| M5 × 20 socket cap bolt + DIN 934 nut | 4 pairs | Mast flange / bridge |
| M5 × 40 socket cap bolt + DIN 934 nut | 4 pairs | Two axes per foot |
| M3 flat washer | 2 | Cover bolt heads |
| M5 flat washer | 18 | Ten under bolt heads; eight measured 1 mm spacers inside foot pivots |
| Selected automotive-compatible double-sided tape | Not selected | Two flat foot faces |

Lengths and pockets are provisional. Check the actual washer sizes, nut standard, full thread engagement, driver access and bolt-end clearance on coupons. Nuts enter their open hex pockets before assembly. Do not bottom a bolt or crush printed walls to remove play. The internal foot washers close the designed gaps so clamping does not require bending each cheek inward by 1 mm. Measure the actual washer/print stack and shim for full contact; do not use torque to close a large remaining gap. Metal washers/bolts are listed hardware, not printed parts or modeled solids. Clamp torque and vibration locking are unqualified.

## Assembly and use

1. Fit the unpowered connector body into its matching insert, under its retaining lips. Confirm both plug shoulders and cable exits. Attach insert and cover with the two M3 bolts and nuts. The front-removable cover permits already-connected downstream cables to stay outside.
2. Insert the inner mast through the outer mast, align the longitudinal slot and fit the M5 height bolt. Keep this bolt installed while adjusting height; it also retains the tongue at the travel ends.
3. Fit the cradle's two pitch cheeks around the toothed mast head. Install the M5 pitch bolt and nut. Unloaded, loosen and spread the cheeks enough to disengage the teeth, choose an index, reseat, then tighten. Never force engaged teeth past one another.
4. Bolt the mast flange to the bridge. Assemble each identical foot and yoke with its two M5 pivots. Each pivot has a 1 mm gap on either side of its central lug: fit one measured 1 mm M5 washer in each gap (four internal washers per foot), in addition to the head washers. Confirm tool access before bonding anything.
5. Route cables through the open right-side channels, behind the tablet to the open clip, then into a loose service loop beside the mast. Check the entire adjustment/removal range without tugging the port or violating actual cable bend limits.
6. With an unpowered dummy, rehearse installation: lower slightly tilted, right edge toward the occupants; press the right side flat; slide right. Removal: hold the tablet, slide left fully, press the left side inward so the right side swings outward, then lift. Do not tilt a partly engaged USB plug.
7. Only after fit/load/heat checks: assess the real mounting location, full pad contact, sightlines, camera view and vehicle-specific airbag/vent/function clearance. Follow the selected tape manufacturer's surface preparation and cure procedure. Set both foot angles without rocking; tighten before tape application.

The provisional hard-stop and plug position must be calibrated together. The tablet must reach mechanical support without bottoming or side-loading USB-C. Charging/audio and road-camera operation need actual hardware tests.

## Qualification boundary

Digital checks cover sampled interference, nominal connector envelopes, component exports, indexed pitch positions and selected foot/height combinations. They do not prove strength, fatigue, heat resistance, adhesive compatibility, damage-free removal, real dashboard fit or crash retention.

Follow the [physical test protocols](docs/validation.md) with surrogate mass first. Record failed as well as passed results. If vibration fails, identify whether motion comes from feet, bridge, slide, hinge or cradle before considering twin supports.
