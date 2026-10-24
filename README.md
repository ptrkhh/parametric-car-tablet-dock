# Parametric car tablet dock

OpenSCAD prototype of a dashboard dock for a bare Samsung Galaxy Tab S7 (SM-T875) in landscape, USB-C on the occupant's right. The tablet slides left to unplug, tilts (left edge inward), and lifts out. Height adjusts 50 mm and pitch ±15° in 5° steps; two standard tape feet adjust ±15° in two axes. Both owned connectors (Essager 90° USB-C cable, CableCreation CD0700 adapter) fit interchangeable inserts under one cover.

**Status: unqualified prototype.** The geometry checks pass for the declared, mostly unmeasured inputs. Nothing has been printed, fitted, loaded, heated, bonded or driven. This is not a production-ready, universal-fit, damage-free-removal, crash-safe or road-qualified design. Crash retention is not designed or tested: in a collision the tablet or dock may detach and strike occupants. See [docs/validation.md](docs/validation.md) for what is and is not established.

## Files

| Path | Contents |
|---|---|
| `cad/parameters.scad` | Every dimension, limit and clearance; provisional values are marked |
| `cad/dock.scad` | Geometry, assembly poses, bed orientations and the `part` selector |
| `tests/geometry_checks.scad` | Spatial fixtures for allowed motion, forbidden motion and keep-outs |
| `tests/test_geometry.py` | Runs OpenSCAD on each fixture and part |
| `docs/measurements.md` | Source and status of each input; hardware; mass and lever arms |
| `docs/validation.md` | Digital checks, their limits, physical protocols and qualification status |
| `docs/superpowers/` | Approved design brief and implementation plan |

## Setup and checks

Requires OpenSCAD 2021.01 and Python 3 (standard library only). From WSL:

```
python3 -m unittest discover -s tests -v
```

The suite takes about five minutes and runs renders in parallel within available memory. `test_declared_build_volume` is skipped until the print service's usable volume is entered in `build_volume`.

## Preview and controls

Open `cad/dock.scad` in OpenSCAD; the Front view is the occupant view. Override controls with `-D`:

| Control | Range | Meaning |
|---|---|---|
| `part` | see below | What to render; default `assembly` |
| `connector` | `"essager"`, `"cd0700"` | Which insert and connector to show or export |
| `height_mm` | 0–50 | Locked height |
| `pitch_deg` | -15 to 15, multiples of 5 | Locked pitch from the nominal angle; + turns the screen toward the roof |
| `slide_mm`, `release_yaw_deg`, `lift_mm` | ≥ 0 | Removal poses: slide left, tilt the left edge inward, lift |
| `foot_pitch`, `foot_roll` | `[left, right]`, ±15 each | Foot angles to match the dashboard slope |

Example: `openscad -D height_mm=50 -D pitch_deg=15 -D slide_mm=8 -D release_yaw_deg=12 cad/dock.scad`

Invalid values (out of range, off the pitch index, unknown `part` or `connector`, too little slide overlap) stop the render with an assertion message.

## Printed parts

Export each part in its candidate bed orientation:

```
mkdir -p build/prototype
for p in cradle cover mast_outer mast_inner bridge foot_yoke tape_foot; do
  openscad --hardwarnings --export-format binstl -D "part=\"$p\"" -o build/prototype/$p.stl cad/dock.scad
done
for c in essager cd0700; do
  openscad --hardwarnings --export-format binstl -D 'part="insert"' -D "connector=\"$c\"" -o build/prototype/insert_$c.stl cad/dock.scad
done
```

| Part | Qty | Size on bed (mm) | Orientation |
|---|---|---|---|
| `cradle` | 1 | 288.3 × 174.8 × 91.7 | Front faces down |
| `insert` (`essager`, `cd0700`) | 1 each | 66.5 × 14.1 × 22.5 | Entry side down |
| `cover` | 1 | 66.5 × 17.1 × 10.8 | Side plate down |
| `mast_outer` | 1 | 70.0 × 50.0 × 84.7 | Flange down |
| `mast_inner` | 1 | 150.6 × 64.0 × 31.2 | Toothed cheek up; the tongue sits 1.2 mm above the bed and needs support |
| `bridge` | 1 | 156.0 × 54.0 × 38.0 | Plate down; the arm bosses need support |
| `foot_yoke` | 2 | 30.0 × 37.0 × 16.0 | On its side |
| `tape_foot` | 2 | 50.0 × 70.0 × 27.0 | Tape face down; keep it flat |

The cradle needs a bed of at least about 290 × 176 mm. Do not split it until the service states its usable volume; then choose splits away from the hooks, roofs, detent and lug, and recheck the joint.

Fit and mechanism samples, to print first: `motion_sample` with `surrogate`, `fit_sample` with both inserts and the cover, `slide_sample` with `mast_inner`, and `pitch_joint` (the cradle lug coupon). Variants and procedures are in [docs/validation.md](docs/validation.md).

### Printing notes for the service review

- Material: PLA for indoor fit samples only; PETG for mechanism samples; ABS is the proposed final material, subject to the actual filament and to heat testing. Ask for warp control on the large flat parts.
- Check every STL in the service's slicer for defects, supports and printable features. STL export is not mesh or manufacturing qualification.
- Weak layer directions to review: the cradle lug web carries the cradle's weight across its layers when printed front-down; the mast sleeve carries the fore/aft moment across its layers when printed upright; the bridge arms bend partly across layers. The face teeth (1.6–2.4 mm pitch, 0.8–1.2 mm deep) are near FDM resolution.
- Clearances (0.5 rail, 0.5 insert, 0.3 slide, 0.2 tooth play) are print allowances to tune with the samples.

## Hardware

Ordinary steel or stainless metric hardware; verify every size on a coupon.

| Item | Qty | Use |
|---|---|---|
| M3 × 25 socket head, ISO 4032 M3 nut | 2 | Insert and cover to the cradle |
| M5 × 35 socket head | 5 | Pitch joint (1), foot pivots (4) |
| M5 × 45 socket head | 1 | Height clamp |
| M5 × 16 socket head | 4 | Mast flange to bridge |
| DIN 934 M5 nut | 10 | All M5 bolts (captive pockets) |
| DIN 125 M5 washer (10 OD × 1) | 18 | Under each pitch, clamp, foot and flange bolt head (10), and in the eight 1 mm foot-pivot gaps (8) |

Tape: not selected. Choose the grade with its supplier for the printed surface and the actual dashboard material.

## Assembly

1. Fit the eight gap washers and assemble each foot: pad lug into the yoke (lower M5 × 35, head outboard), yoke between the bridge arms (upper M5 × 35, head at the front).
2. Bolt the outer mast to the bridge (4 × M5 × 16, nuts from below).
3. Stand the base on the chosen surface without tape. Set both feet so each pad lies flat with no rocking, then tighten the four pivot bolts. The feet must be set with the cradle off; check driver sightline, vents, controls and airbag covers before going further.
4. Slide the inner mast into the sleeve and fit the clamp bolt through the slot (it also stops travel; keep it fitted). Set the height and tighten.
5. Place the cradle lug between the fork cheeks, fit the pitch bolt, choose an index and tighten.
6. Slide the unpowered connector into its insert from the right, place the insert against the rear mount, plug in the downstream cables through the front outlets, lay the cables in their channels and the cable clip, and fit the cover with two M3 × 25 bolts.
7. Only after the fit, load and heat checks in docs/validation.md pass, bond the pads with the selected tape following its surface preparation, pressure and dwell instructions.

**Install the tablet:** place it tilted (left edge inward) into the cradle, press the right edge inward until it is flat against the guides, then slide right to engage USB-C and the detent.

**Remove the tablet:** slide left against the detent until USB-C is out and the tablet reaches the left wall, press the left edge inward (the right edge swings about 25 mm outward), then lift. Do not adjust or remove the tablet while driving.

**Adjust height:** loosen the clamp bolt, move the mast within the slot, retighten.

**Adjust pitch:** unloaded, loosen the pitch bolt, spread the toothed cheek about 1.2 mm so the teeth clear, turn to the next 5° index, reseat and tighten. Never force the joint across engaged teeth.

**Swap connector:** remove the two M3 bolts and the cover, unplug the downstream cables, slide the connector out, fit the other insert and connector, then reassemble as in step 6.

## Handoff record

With every delivered prototype, record: the source revision (`git rev-parse HEAD`), every `-D` override used for each STL, the measurement assumptions in docs/measurements.md, the hardware list, the filament grade and batch, printer, nozzle, layer height, walls, infill, orientation, supports and post-processing. Physical results go into docs/validation.md as pass, fail or UNRUN.
