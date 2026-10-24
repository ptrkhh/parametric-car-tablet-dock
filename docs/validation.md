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

## Connector candidate

The cradle carries a rear mount behind a right-side bay, tied to both corner hooks by side rails at its outer edge. Each connector has its own insert with the same outer envelope and the same two M3 bolt positions. One cover fits both inserts.

- **Insert.** The body slides in from the right into a pocket that fits it with `insert_clearance` on every side; its plug shell passes through a hole in the wall facing the tablet. The insert's front wall conceals the body from the occupant view. The CD0700's two outlets and the Essager's downward cable channel open to the front, so cables lay in from the front.
- **Cover.** A right side plate closes the entry, and a boss stops the body against plug insertion. A front flange carries the two bolts, which clamp cover, insert and rear mount to captive nuts. The cover clears the outlets and installs with the downstream cables already plugged in.
- **Retention.** Extraction load (tablet sliding left) goes through the insert's tablet-side wall. Insertion load goes into the cover boss. The pocket holds the body in Y; the plug hole also limits Z movement because the CD0700 outlets are as large as its end faces.
- **Stops.** The tablet's right stop is in the corner hooks. The insert face stays 0.5 mm from the tablet edge, so the plug is never the end stop.

Assembly order:

1. Slide the unpowered body into its insert from the right.
2. Place the insert against the rear mount.
3. Plug the downstream cables in through the front-open outlets and press the cables into their channels.
4. Fit the cover and tighten the two M3 × 25 bolts.

| Test | Check |
|---|---|
| `test_both_insert_interfaces_match` | Each insert stays inside the common envelope; insert, cover and cradle do not overlap; bolt shanks pass through all three; body and plug clear every part |
| `test_connector_body_captured` | 1 mm shifts of body plus plug in ±X, ±Y and ±Z meet the insert or cover |
| `test_connector_clear_before_yaw` | Both configurations: insert, cover, body and downstream witnesses clear the slide sweep; with the plug added they clear 13 yaw poses (1-degree steps) and the lift sweep. The plug is out of the tablet before the yaw starts |
| `test_cable_outlets_open` | Downstream plug or strain-relief witnesses plus 10 mm of cable clear insert, cover and cradle |
| `test_device_feature_clearances` | Camera cones, speaker and key keep-outs clear cradle, insert and cover; the witnesses render nonempty |

Intended contacts (insert against the rear mount and against the cover) are separated by 0.01 mm in the fixtures so face contact does not count as overlap. Witnesses are placed from the documented rules in the fixture file, not from the CAD modules.

Limits: these checks use guessed seated transforms. They do not establish electrical seating, zero port stress, plug alignment tolerance, cable bend radius or the downstream route behind the tablet. The top CD0700 plug sits next to the assumed right speaker opening.

### Fit samples

Export `part="fit_sample"` (the cradle's right side from the top hook down past the bay), plus `part="insert"` for each connector and `part="cover"`, at `insert_clearance` 0.3, 0.5 and 0.7:

```
openscad --hardwarnings --export-format binstl -D 'part="fit_sample"' -o build/prototype/fit_sample.stl cad/dock.scad
openscad --hardwarnings --export-format binstl -D 'part="insert"' -D 'connector="cd0700"' -D insert_clearance=0.5 -o build/prototype/insert_cd0700_0.5.stl cad/dock.scad
openscad --hardwarnings --export-format binstl -D 'part="cover"' -D insert_clearance=0.5 -o build/prototype/cover_0.5.stl cad/dock.scad
```

Label every printed piece with its connector and clearance. Assemble unpowered first. Hold the bare tablet's right edge against the top hook's stop and measure plug axial alignment, seating depth, extraction distance, body restraint and cable bend. Inspect the 0.8 to 1.2 mm tablet-side wall on every sample. Any tablet load through the USB port, or a stop that lets the plug bottom before the tablet reaches the hook, is a failure.

Physical checks, all UNRUN: connector fit, alignment and seating, extraction and insertion retention, charging during use for both connectors, CD0700 audio, cover fitting with cables connected, real camera view, speaker, microphone and key clearance.

## Central support candidate

- **Height.** A keyed 30 × 18 mm tongue (`mast_inner`) slides in a sleeve (`mast_outer`) on a four-bolt flange with front and back gussets. One M5 cross bolt passes through both side walls and a 50 mm slot in the tongue. Tightening it squeezes the side walls onto the tongue, because the back wall is split above the bolt. The same bolt stops travel at 0 and 50 mm, so it must stay installed while adjusting. At full height 28.65 mm of tongue remains in the sleeve.
- **Pitch.** A lug on the cradle spine sits between two fork cheeks on the tongue, supported on both sides by one M5 bolt. The lug's +X face and the +X cheek carry matching 5-degree face teeth (Hirth form, 45-degree flanks); the -X faces are plain. Every index from -15 to +15 degrees meshes with 0.2 mm axial play. 1 degree off an index the teeth collide, so a clamped joint can only sit on an index.
- **Adjusting pitch.** Do this unloaded. Loosen the bolt, spread the +X cheek about 1.2 mm so the teeth clear, turn to the next index, reseat and tighten. Do not force the joint across engaged teeth.
- **Cable.** A clip on the cradle beside the fork holds the cable near the pitch axis. From there a loop reaches a corridor beside the mast down to the flange.

| Test | Check |
|---|---|
| `test_height_and_pitch_limits` | Height outside 0–50, pitch outside ±15 and pitch off the 5-degree index are rejected; all seven indexes mesh at heights 0 and 50; ±1 degree off -15, 0 and +15 collides |
| `test_slide_overlap_at_max_height` | At full height the tongue reaches `min_overlap` (25 mm) below the sleeve top; `validate()` rejects a configuration with less |
| `test_support_and_cable_clearance_at_extremes` | At heights 0/25/50 and pitch -15/0/+15: the slide and lift sweeps and 7 yaw poses clear the mast; cradle, connector hardware and mast parts do not overlap; the cable route, loop and corridor are clear; the camera, speaker and key keep-outs clear the mast |
| `test_support_fasteners_clear` | At the same nine poses: both M5 bolts' shanks, washers, heads, a 60 mm hex-key path and seated nuts clear every part; full rings under each washer and nut lie inside material |
| `test_fixture_does_not_shadow_cad` | No fixture name replaces a CAD module, function or variable |

The last test exists because a fixture helper named `along_x` silently replaced the CAD module of the same name inside every check, halving every bolt hole and the lug radius. All support results above were produced after that fix.

Limits: the cable keep-outs are free volumes, not a simulated cable. They do not prove bend radius, slack length or that a loop stays in its corridor. The teeth are rigid solids; tooth strength, cheek flex during adjustment, clamp force and slip under load are physical tests. The cradle bottom clears the sleeve by 4.8 mm at -15 degrees.

### Support coupons

Export `slide_sample` (top 40 mm of the sleeve with the split and clamp bolt), `mast_inner` and `pitch_joint` (the cradle lug on its web) before printing the full cradle:

```
openscad --hardwarnings --export-format binstl -D 'part="slide_sample"' -o build/prototype/slide_sample.stl cad/dock.scad
```

Check bolt insertion, hex-key access, nut seating, washer bearing, full thread engagement without bottoming, smooth sliding, positive tooth engagement at every index and no cracked layers. The joint coupon omits the full cradle's lever arm. Physical checks, all UNRUN: clamp holding force, tooth strength and wear, cheek flex, slip under the declared load, cable slack through the full height range at every pitch index with the cables connected and no load on the tablet port.

## Standard feet

Both feet use the same pad (`tape_foot`) and yoke (`foot_yoke`); the left foot is the right one turned 180 degrees. The pad's lug turns about X inside the yoke (lower pivot, fore/aft slope). The yoke turns about Y between two arms of the bridge (upper pivot, side-to-side slope). Set `foot_pitch=[left, right]` and `foot_roll=[left, right]` within ±15 degrees. These angles rotate standard parts; nothing generates a dashboard contour.

| Test | Check |
|---|---|
| `test_two_axis_foot_adjustment` | Angles beyond ±15 are rejected. For each foot at neutral and the four corner combinations, a planar fixture built from the fixture's own matrices carries the pad: a 0.25 mm film under the whole pad lies inside the fixture (full flat contact within 0.05 mm) and no part of the foot enters it. A 1-degree mismatch between fixture and foot fails this. Bridge, yokes and pads never overlap, with the other foot at the opposite corner |
| `test_curved_dashboard_breaks_flat_contact` | On a 250 mm radius dashboard (axis X) tangent at the pad centre, the flat pad's contact film is not wholly inside: about 2.5 mm gap at the pad ends. Tangency is not contact |
| `test_foot_clamps_have_tool_access` | At the same angle combinations: all four M5 bolts' shanks, head washers, heads, 60 mm hex-key paths, seated nuts and the eight 1 mm gap washers clear every base part, the mast and both dashboard planes; full rings under each washer and nut lie inside material |
| `test_base_clears_removal_envelope` | At heights 0/25/50 and pitch -15/0/+15 the slide and lift sweeps and 4 yaw poses clear the base. At height 0 (the lowest cradle) and all three pitches, cradle, connector hardware, cable keep-outs and mast clear the base at every foot angle combination |

The tool-access check assumes the cradle is off while the feet are set: stand the base on the surface, set both feet without rocking, tighten the four pivot bolts, then fit the mast, cradle and tape. The bridge sits 10 mm above the pad plane at its centre on a flat surface, and the flange bolt tips 7 mm above it; a dashboard that rises between the feet must not touch them.

The first foot design failed the joint check: at +15/+15 degrees the pad's inner corner rose into the bridge arms. Offsetting the pads 10 mm outboard of their pivots fixed it.

Physical checks, all UNRUN: contact on the real W124 surface and other dashboards (curvature, soft skins, texture, coatings, aged material), rocking after the clamps are tightened, washer friction and bolt torque, hot creep at the pivots, adhesive selection, bond and removal damage, driver sightline, vent and control access, and airbag cover and deployment-path clearance. Reject a placement without full flat contact; do not fill a substantial gap with stacked tape. A different location or pad concept may be needed if the real dashboard falls outside this model.

## Motion sample

`part="motion_sample"` is `cradle(100, 60)`: the same clearances, hook overlap, roof, lip, pocket angle and detent around a smaller tablet. `part="surrogate"` is the matching 100 × 60 × 6.3 mm dummy with the tablet's provisional `corner_r`, so the detent contact matches the full cradle. The sample does not reproduce the full tablet's lever arm or mass. It contains no connector or device cutouts. Do not force a real tablet into it.

```
openscad --hardwarnings --export-format binstl -D 'part="motion_sample"' -o build/prototype/motion_sample.stl cad/dock.scad
openscad --hardwarnings --export-format binstl -D 'part="surrogate"' -o build/prototype/surrogate.stl cad/dock.scad
```

Add `-D clearance=0.3` (or 0.7) to the `motion_sample` command for clearance variants (the surrogate does not change), and mark each printed piece with its value.

Test procedure: deburr both pieces. Seat the surrogate (installation: place it tilted, press the right edge inward until flat, slide right over the detent). Then remove it: slide left against the detent to the wall, press the left edge inward, lift. Record any interference before changing a clearance, and recheck full-size geometry after any change.

Physical checks, all UNRUN: slide force, tongue deflection and recovery, bump wear, automatic reseating, retention under upward and outward load, repeated cycles, actual USB disengagement margin, screen/bezel coverage of the 7.5 mm hooks and 5 mm lip, and hot ABS creep.

## Printable exports

`test_all_printable_parts_export` renders all 14 printed pieces (the eight dock parts, with both inserts, and the five samples) in their candidate bed orientations. Each must render without diagnostics, form one connected solid in CGAL's report, and rest on Z=0; the surrogate must measure 100 × 60 × 6.3 mm. `test_declared_build_volume` is **skipped** because the service has not supplied its usable volume; part fit is UNVERIFIED. With a 256 mm cube entered as a trial, only the cradle (288.3 × 174.8 × 91.7 mm) failed. Bed sizes for every part are in the README.

A candidate orientation, a connected CGAL volume and a clean export are not slicer approval, mesh qualification or a print-quality result.

## Physical protocols (all UNRUN)

These are proposed development checks, to be run in order, before any installed or road-use decision. They are not safety ratings and do not replace engineering qualification. Record every result as pass, fail or UNRUN, with the inputs used.

1. **Inputs and print inspection.** Record source revision, overrides, filament grade and batch, printer, nozzle, layer height, walls, infill, orientation, supports and post-processing. Have the service inspect every STL in its slicer for defects, unsupported surfaces and build-volume fit. Measure coupons, bores, nut pockets, tooth form and flat tape faces. Reject cracks, warped pads, loose body capture or obstructed controls. Repeat with the final material after any PLA trial.
2. **Fit and repeated removal.** Start with the surrogate and motion sample. Plan 100 install/remove cycles, inspecting at 0, 10, 50 and 100. Record slide force against the detent with a gauge, detent recovery, wear and permanent set. Confirm that lift and outward escape are blocked while docked and that the tilt cannot start before the real USB plug is out. Any unintended unplugging, fracture, jam or side load on the port is a failure. Only then repeat with the unpowered bare tablet, recording real seating and end-stop positions for both connectors; never force the tablet against its port.
3. **Mass, load and locking.** Weigh every supported part and replace the 1,106 g planning figure in docs/measurements.md. Measure each centre of mass and lever arm from the tape footprint and record F = Σmᵢ·a and M = Σrᵢ × Fᵢ for the chosen bench accelerations; do not invent a universal road acceleration. Fix the base to a sacrificial plate, load a surrogate mass, and test full height at both pitch extremes. Record force, direction, dwell, clamp torque and movement. Any clamp slip, tooth skip, cracked layer or permanent deformation is a failure. Set loads and pass thresholds before increasing them.
4. **Heat and creep.** First measure cabin and mount temperatures in the intended parked conditions. Choose a test temperature within the filament, tape and connector specifications; no generic ABS temperature rating is assumed. Proposed development soak: 8 hours under measured surrogate load, three hot/cool cycles, deflection read hourly and after cooling, on a fixture without the tablet. Progressive creep, a released detent, a loose clamp, bond lift or permanent set is a failure. A short soak does not establish long-term life.
5. **Adhesive contact and removal.** Select the tape grade with its supplier for the printed surface and the dashboard material. Test first on expendable representative surfaces, including texture and soft skin. Follow the tape's cleaning, pressure, dwell and removal instructions; no primer or solvent is assumed safe for the vehicle. Record bonded area, temperature, dwell, load and removal method. Reject rocking, unbonded regions, edge lift, finish marks, delamination or residue that an approved method cannot remove. Damage-free removal from the actual aged dashboard stays unproven until tested.
6. **Electrical and cables.** After mechanical fit passes, verify charging during use with each connector, then CD0700 audio. Move through the full height and pitch range and the removal sequence with cables connected. Record charging status, connector temperature, dropouts and cable tension. Reject intermittent charging or audio, crushed cables, strain-relief contact or port loading. Confirm the cover fits with the downstream cables plugged in.
7. **Vehicle placement and vibration.** Before bonding, check driver sightline, vents, controls, airbag covers and deployment paths (vehicle documentation), camera view and removal hand clearance in the W124; repeat for every other vehicle. After the bench, heat and bond checks, observe stationary with the engine running and surrogate mass, with witness marks filmed at each joint. Then a controlled low-speed run before representative rough surfaces; record speed, surface and duration. Reject any loosening, unintended release or unplugging, persistent wobble or unusable camera footage. If the central mast fails, identify whether the mast, cradle, foot joint, adhesive or dashboard moves before considering twin supports.
8. **Camera footage.** Record road footage at both height limits and every pitch index intended for use. Check that the lens's full field of view clears the cradle, mast, cables, dashboard and reflections. The CAD camera placeholders are not evidence.

## Qualification status

| Gate | Digital evidence | Physical status |
|---|---|---|
| Removal path and retention | Sampled sweeps and forbidden-motion probes pass for the nominal envelope, full size and sample | UNRUN; real protrusions, clearances and detent force unmeasured |
| Connector fit and cable outlets | Both inserts, cover, keep-outs and removal path checked with guessed seated transforms | UNRUN; bodies, seating, retention and electrical function unmeasured |
| Height slide and pitch joint | Overlap, tooth indexing, fastener fit and clearances at nine poses checked | UNRUN; clamp force, tooth strength, stiffness and fatigue |
| Feet and base | Flat contact on tilted planar fixtures; curved fixture shows a gap; joints, tool access and removal clearances checked | UNRUN; real dashboard contact, rocking and clamp friction |
| Printable parts | Clean exports, connected solids, candidate bed orientation | UNRUN; service slicer review, build volume UNVERIFIED, print inspection |
| Cabin heat and creep | No thermal analysis | UNRUN |
| Adhesive contact and removal damage | Planar fixtures only | UNRUN |
| Load, vibration and road stability | Planning mass and lever arms only | UNRUN |
| Camera footage | Placeholder view cone only | UNRUN |
| Sightline, airbag, vehicle functions | No vehicle model | UNRUN |
| Crash retention | Not assessed | UNQUALIFIED |

The source and samples support the next measurement and fit iteration. They are not fitted manufacturing exports or an approval to install.
