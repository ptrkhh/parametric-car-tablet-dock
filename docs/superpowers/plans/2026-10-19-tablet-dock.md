# Dashboard Tablet Dock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Native execution is recommended for this tightly coupled CAD prototype.

**Goal:** Produce a parametric OpenSCAD prototype, printable fit/mechanism samples, and a manufacturing handoff for the agreed tablet dock, while keeping physical qualification explicitly separate.

**Architecture:** One parameter file defines the device, connectors, clearances, and adjustment limits. One CAD file implements the cradle, connector inserts, mast, bridge, and standard feet, with separate assembly and printable-part views. Prove the constrained removal path before developing the complete support; advance physical qualification only when actual measurements and test results exist.

**Tech Stack:** Installed OpenSCAD 2021.01; WSL Python 3 standard library and `unittest` for subprocess-based geometry checks. No new CAD framework or Python dependencies. Use the print service's slicer review for manufacturing checks that OpenSCAD does not establish.

**Spec:** [Approved design brief](../specs/2026-10-19-tablet-dock-design.md), including the user's additions on upward capture, vehicle sightlines, airbag clearance, 500 g tablet mass, and crash-retention limits.

## Global Constraints

- Bare SM-T875: 253.8 × 165.3 × 6.3 mm; nominal mass 500 g. Camera and connector positions require separate measurements.
- Landscape; USB-C on the occupant's right. Approximately 50 mm height travel; preferably ±15 degrees of pitch about the nominal installed angle.
- Removal: slide left until unplugged, press left inward/right outward, then lift. Installation reverses that sequence. Automatic detent; no separate release button.
- Capture against outward movement and upward road shocks must come from cradle geometry, with upward capture clearing through the removal sequence.
- One central mast is preferred; do not implement twin tablet supports preemptively.
- Same standard dashboard bridge and feet across cars. No dashboard scans, custom contours, or car-specific reprints. Tape placement sets fore/aft position.
- Common right-side cover; two connector inserts. Downstream cable plugs stay outside the dock; cables must not obstruct removal or adjustment.
- ABS is the proposed final material, not a heat qualification. Use metal bolts and captive nuts for adjustment clamps.
- Do not obstruct cameras, controls, speaker/microphone openings, vehicle functions, driver's sightlines, or airbag deployment paths.
- The base supports tablet, cradle, mast, connectors, and relevant cables. Include their masses and lever arms in load estimates; 500 g alone is not the base design load.
- No production-ready, universal-fit, damage-free-removal, crash-safe, or road-qualified claims from render/STL success.
- Preserve the current checkout. Create an isolated implementation worktree after this plan's review; do not invent a remote or publish a repository. No remote currently exists.

## Review Focus

1. **Wrong release path:** tablet appears to animate correctly but actual solids collide, or permit lift/tilt while connected. Task 2 checks spatial interference and physical sequence.
2. **Connector misalignment:** an insert fits its body but loads the port or blocks a cable outlet. Task 3 checks both options and actual fit samples.
3. **Worst adjustment position:** full height and pitch remove slide overlap, loosen a clamp, or tension cables. Task 4 checks travel extremes; Task 6 checks load and heat.
4. **Non-flat dashboard:** tilted pads appear seated but lack adequate contact or conflict with visibility/airbags. Task 5 models slope fixtures; Task 6 checks real surfaces and installation.
5. **Manufacturing variation:** ABS shrinkage, layer orientation, or an unsupported feature defeats otherwise valid geometry. Tasks 3 and 6 use small fit samples, service review, and inspected prints.

## Files and interfaces

| File | Responsibility |
|---|---|
| `cad/parameters.scad` | Single source for dimensions, adjustment limits, tolerances, and clearly labelled provisional values. |
| `cad/dock.scad` | Geometry modules, assembly poses, printable orientation, and `part` selector. |
| `tests/geometry_checks.scad` | Independent spatial fixtures for allowed motion, forbidden movement, and adjustment limits. |
| `tests/test_geometry.py` | Run OpenSCAD in temporary directories; check diagnostics, expected solids/emptiness, and invalid inputs. |
| `docs/measurements.md` | Source/value/status for each critical measurement; provider requirements and load inputs. |
| `docs/validation.md` | Commands, exact tested parameters, observations, failures, and physical tests still unrun. |
| `README.md` | Setup, preview/export commands, assembly, hardware list, printing notes, and current qualification boundary. |
| `.gitignore` | Generated `build/`, Python cache, and test cache only. |

Use millimetres, degrees, and grams. In the unpitched tablet frame, X is occupant-right, Y is outward toward occupants, and Z is up. The tablet envelope is `[253.8, 6.3, 165.3]` in XYZ order. Positive removal yaw around Z moves the left edge inward and right edge outward; positive pitch around X turns the screen toward the roof. Define the tablet origin at its centre and derive its installed height from the bottom edge.

Public CAD controls: `part`, `connector` (`"essager"` or `"cd0700"`), `height_mm` (0–50), `pitch_deg` (-15–15 relative to nominal), `slide_mm` (nonnegative leftward travel), `release_yaw_deg` (nonnegative), and `lift_mm` (nonnegative). `slide_mm` is not inferred from the 15 mm protrusion estimate. Derive release travel from measured plug engagement plus clearance. Keep provisional release travel visibly labelled until measured.

Public geometry modules: `tablet_pose(slide_mm, release_yaw_deg, lift_mm)` transforms its children; `tablet_envelope()` produces the bare-tablet collision solid with measured protrusions/recesses; `cradle()` produces rigid retention geometry; `connector_insert(kind)` produces the corresponding insert; `connector_cover()` produces the common cover; `mast_outer()`, `mast_inner()`, `pitch_joint()`, `bridge()`, `foot_yoke()`, and `tape_foot()` produce support parts. `assembly()` composes the chosen configuration. Additional helpers stay private to the CAD file.

Spatial fixtures use `check` names matching their Python test names without the `test_` prefix. Allowed-motion/keep-out checks export the intersection solid and expect it to be empty; forbidden-motion probes expect a nonempty intersection with a retaining feature. Keep test transforms independent of the animation transform so a sign error cannot make both agree incorrectly. Numeric configuration assertions cover 50 mm travel, ±15-degree pitch, and positive retained slide overlap. None of these checks measures force or simulates flexible parts.

## Task 1: Establish the parameterized reference and checks

**Files:** Create `cad/parameters.scad`, `cad/dock.scad`, `tests/geometry_checks.scad`, `tests/test_geometry.py`, `docs/measurements.md`, `.gitignore`.

**Interfaces:** Produces the coordinate system, public controls, `tablet_pose(...)`, and `tablet_envelope()` used by every later task. Initial `part` values are `"reference"` and `"assembly"`.

- [ ] Record published dimensions separately from measured inputs and modelling assumptions. Identify missing port/camera/control positions, connector geometry, provider build volume, tolerances, nominal viewing angle, and base installation envelope. Unknown measurements do not become asserted facts.
- [ ] Add failing `unittest` cases: `test_reference_compiles`, `test_invalid_dimensions_rejected`, `test_unknown_part_rejected`, and `test_unknown_connector_rejected`. Require positive device dimensions; unknown selectors must fail clearly rather than emit an empty successful export.
- [ ] Run `python3 -m unittest discover -s tests -v`; confirm failures identify missing implementation.
- [ ] Implement the reference solid and selector/assertion boundary. Use only dimensions required for the task. Document any assumed geometry next to its parameter and in `docs/measurements.md`.
- [ ] Run the tests and inspect a front/rear reference render. Verify right-side USB convention and coordinate axes visually. Save prototypes under `build/prototype/`; do not call them fitted parts.
- [ ] Commit the reference and checks: `feat: add parametric tablet reference`.

## Task 2: Prove cradle motion and automatic retention

**Files:** Modify the CAD files and both test files; create `docs/validation.md`.

**Interfaces:** Consumes Task 1's envelope/pose. Produces `cradle()`, `part="cradle"`, `part="motion_sample"`, and a documented candidate release travel/yaw. The sample contains the retention surfaces and a tablet surrogate; it does not require an actual tablet or powered connector.

- [ ] Add failing tests: `test_slide_then_yaw_then_lift_clearance`, `test_connected_yaw_is_blocked`, `test_docked_lift_is_blocked`, and `test_docked_left_edge_outward_is_blocked`. Inspect intersections between actual reference solids and rigid guides, not an artificial rule that merely rejects a forbidden pose.
- [ ] Run the tests and confirm the intended failures before adding retention features.
- [ ] Develop the first candidate from short overhanging edge tabs, a recessed left-side inward-clearance pocket, and a central rear contact surface that supports the seesaw motion. Add the automatic detent as a distinct compliant region; keep its intended deflection out of rigid-collision tests and test it physically. Do not alter the agreed movement to conceal a failed candidate.
- [ ] Sample each allowed stage with at least 11 poses including endpoints and additional poses at tab-clearance transitions. Model the connector's measured engagement envelope for the tilt interlock. Check forbidden motion before the tablet can clear a retaining feature; state the probed displacement and sampling limits. A few collision-free samples are not continuous-path or force proof.
- [ ] Implement the checks with `openscad --hardwarnings --export-format binstl`. The Python runner must distinguish the known empty-intersection diagnostic from genuine parse/render errors; include runner tests for a solid fixture, an empty fixture, and a broken fixture. Do not implement a new mesh-analysis library.
- [ ] Inspect front, side, rear, and overhead poses, including reverse installation. Export the small motion sample and document how to test with a surrogate. Record physical retention/release-force tests as unrun until performed.
- [ ] If the candidate cannot both capture the tablet and release in the specified order, stop full-cradle development and report the geometric conflict. Otherwise commit: `feat: prototype slide and tilt retention`.

## Task 3: Fit both connector options and complete the cradle

**Files:** Modify both CAD files, both test files, `docs/measurements.md`, and `docs/validation.md`.

**Interfaces:** Produces `connector_insert(kind)`, `connector_cover()`, `part="insert"`, `part="cover"`, and `part="fit_sample"`. Both inserts use the same cradle attachment and common cover. Actual critical dimensions remain an explicit manufacturing gate.

- [ ] Add failing tests: `test_both_insert_interfaces_match`, `test_connector_clear_before_yaw`, `test_cable_outlets_open`, and `test_device_feature_clearances`. Use separate cable/plug keep-out solids and camera/control/opening reference geometry; do not infer all feature locations from the outer tablet envelope.
- [ ] Run the failing tests, then implement body capture against insertion/extraction, locating surfaces, a removable cover, and open cable channels. The cover must install with the downstream cables already plugged in.
- [ ] Model the CD0700's opposed socket exits and the Essager's elbow exit. Keep downstream plugs outside the cover. Check both configurations throughout the Task 2 removal poses; connector position remains fixed to the cradle.
- [ ] Export connector/rail fit samples in a small set of clearly identified clearance variants. Obtain actual fit feedback before labelling any variant production-ready. Check that stops establish full seating without bottoming the port under structural load.
- [ ] Run the geometry suite and inspect the camera, speaker, microphone, and button clearances. Record charging/audio verification as unrun until checked with the actual hardware.
- [ ] Commit: `feat: add interchangeable connector inserts`.

## Task 4: Add the adjustable central support

**Files:** Modify both CAD files, both test files, and `docs/validation.md`.

**Interfaces:** Consumes the cradle attachment and cable exit positions. Produces `mast_outer()`, `mast_inner()`, `pitch_joint()` and corresponding `part` selectors. The mast-to-bridge and cradle-to-pitch interfaces become fixed inputs to Task 5.

- [ ] Add failing tests: `test_height_and_pitch_limits`, `test_slide_overlap_at_max_height`, and `test_support_and_cable_clearance_at_extremes`. Exercise heights 0, 25, and 50 mm and pitch offsets -15, 0, and +15 degrees, including removal at each combination. Reject out-of-range controls explicitly.
- [ ] Run the failing tests, then implement a keyed ribbed slide with a metal-bolt clamp and a pitch joint supported on both sides. Use matching radial teeth with 5-degree increments as the initial prototype choice; show the full ±15-degree usable range.
- [ ] Select ordinary metric bolts/nuts from documented dimensions; put fastener dimensions in the parameter file and hardware list. Verify captive-nut seating, tool access, clearance around bolt ends, and that tightening loads have structural bearing surfaces.
- [ ] Add a cable slack envelope spanning the adjustment range. Check clearance using representative cable diameters/bends, labelled assumptions until confirmed; a static routed line is not proof that adjustment is possible.
- [ ] Run geometry checks and inspect the assembly at the highest setting and both pitch extremes. Export a slide/joint fit sample before committing to full-size prints.
- [ ] Commit: `feat: add height and pitch adjustment`.

## Task 5: Add the standard dashboard bridge and feet

**Files:** Modify both CAD files, both test files, `docs/measurements.md`, and `docs/validation.md`.

**Interfaces:** Produces `bridge()`, `foot_yoke()`, `tape_foot()` and corresponding `part` selectors. Feet are identical standard parts; assembly settings change per installation, not the printed contact contours.

- [ ] Add failing tests: `test_two_axis_foot_adjustment`, `test_foot_clamps_have_tool_access`, and `test_base_clears_removal_envelope`. Create flat and independently tilted planar fixtures in the test file. These fixtures test geometry, not real-dashboard compatibility.
- [ ] Run the failing tests, then implement two orthogonal clamping pivots per foot using metal bolts/nuts. Use broad standard tape faces and a rigid bridge. Keep cable exit and removal clearance available throughout the supported adjustment range.
- [ ] Select the provisional pad footprint and foot angle limits from actual available mounting space and declared loading assumptions. Record limits and full supported mass/lever arms. If measurements are unavailable, retain explicit prototype values and do not claim adequate adhesive area or car fit.
- [ ] Check same-foot geometry on both slope fixtures. Demonstrate that substantial curvature is outside a flat pad's contact model; do not pass a curved fixture merely because it touches at a few points.
- [ ] Run the geometry suite and inspect the complete assembly. Record W124 and other-dashboard contact checks, driver sightline checks, and vehicle-specific airbag checks as unrun until performed.
- [ ] Commit: `feat: add standard adjustable tape feet`.

## Task 6: Prepare the print handoff and qualification record

**Files:** Create `README.md`; update CAD printable orientations, tests, `docs/measurements.md`, and `docs/validation.md`. Generated exports go under `build/prototype/` and are not source code.

**Interfaces:** Produces reproducible assembly views, one export per printable component, a hardware list, and a qualification checklist. It does not manufacture, buy hardware, bond the mount, or claim passed physical tests without evidence.

- [ ] Add `test_all_printable_parts_export` and `test_declared_build_volume` once the service's usable volume is known. Each intended solid part must export nonempty without OpenSCAD errors/warnings. Unknown build volume must be reported as unverified, not silently treated as unlimited.
- [ ] Review print orientation, overhangs, layer loading, clamp bearing surfaces, and accessible supports with the service. Split a part only if actual build-volume or strength requirements demand it; keep splits away from critical loaded features where possible and recheck the joint.
- [ ] Run `python3 -m unittest discover -s tests -v` and `git diff --check`. Create `build/prototype/`, then export with a command such as `openscad --hardwarnings --export-format binstl -D 'part="cradle"' -o build/prototype/cradle.stl cad/dock.scad`. Inspect all parts in the service's slicer for connected solids, defects, supports, and printable dimensions. STL existence alone is not mesh or manufacturing qualification.
- [ ] Document assembly order, clamp access, connector swap, installation/removal, and tape/cable locations. Include exact source revision, CAD settings, measurement assumptions, hardware, filament, orientation, and print settings with any delivered prototype.
- [ ] Define physical protocols before testing: load and moment assumptions, measured cabin/part temperature range and soak duration, repeat-cycle count, detent-force observations, representative surfaces, vibration/road conditions, and failure criteria. Do not invent universal acceleration or temperature ratings. Start with surrogate mass and inspect before testing the actual tablet.
- [ ] Record pass/fail/unrun separately for fit, constrained removal, adjustment locking, printed-part heat/creep, adhesive contact and removal damage, electrical operation, road stability, camera footage, and sightline/airbag clearance. Keep crash retention explicitly unqualified. If the central mast fails, identify the moving component before revisiting twin supports.
- [ ] Commit the source and handoff: `docs: document dock printing and validation`. Physical work awaiting the user/service stays open with concrete next inputs; do not mark those gates complete to close the implementation task.

## Plan review and execution boundary

This plan is ready for review before CAD implementation. Recommend native execution: the same mechanism, coordinate system, and measured inputs connect every task, so one implementer avoids repeated context handoffs. A final independent review can check the implementation before any manufacturing recommendation; physical qualification remains separate.

After plan review and execution-method selection, begin in an isolated worktree using the approved spec and this plan. Missing measurements permit explicitly provisional CAD and samples where meaningful; they block dependent fitted exports and qualification, not unrelated work. A failed removal-path proof blocks downstream refinement of that cradle until resolved.
