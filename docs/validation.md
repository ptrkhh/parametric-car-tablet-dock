# Prototype validation record

This record separates digital geometry from physical qualification. No printed part, connector, tablet, dashboard, tape bond, or vehicle has been tested.

## Cradle candidate

The rigid cradle uses a recessed back frame, left front lip and roof, right retaining hooks, and a central rear contact. The provisional automatic detent is a floor tongue rooted in the left wall. Its 45-degree cone presses the docked lower-left corner up and right (`detent_preload` 1 mm interference, `detent_rise` 1.5 mm apex height). Its elastic behaviour is excluded from rigid interference checks.

The provisional release is 8 mm left, then 12 degrees clockwise viewed from above, then lift. USB engagement is assumed to be 6 mm until measured. The right hooks prevent the tested 1-degree yaw at 0, 50% and 100% of `plug_engagement` (0, 3 and 6 mm by default) without using the plug as a blocker. They clear only beyond `release_travel - clearance`, and `validate()` rejects a release travel that does not exceed `plug_engagement + clearance`. A 2 mm docked upward probe and a 1-degree left-edge-outward probe intersect the cradle.

Allowed slide and lift checks use the hull of their endpoint envelopes. Yaw uses 25 samples at 0.5-degree intervals, including endpoints. Each tablet face is inset 0.01 mm to avoid OpenSCAD's zero-volume face-contact export behaviour. These tests do not prove all intermediate angular poses, combined escape paths, forces, tolerance stacks, or deformation. Transforms in the fixture are independent of the production pose transform.

The undeflected detent cone intersects the docked tablet, so it engages. Along the sampled slide, yaw and lift path, which reversed is the installation path, the tablet touches only the cone's top 1.5 mm; those contacts lie on 45-degree faces and press the tongue down. The earlier side spring failed this check: un-yawing at full slide swept the tablet through the spring's stiff direction over 43 mm of its height, blocking installation.

The renderer tests reject parse failures and all WARNING/ERROR diagnostics, including CGAL warnings with exit status zero. Expected empty intersections require the exact empty-top-level diagnostic and no STL. Nonempty checks require a correctly sized binary STL with positive facet count; this is not mesh-topology analysis.

### Small sample

Export `part="motion_sample"` and `part="surrogate"`. The sample uses a 100 × 60 × 6.3 mm dummy with the tablet's provisional corner radius (`corner_r`), so its detent contact matches the full cradle. It preserves tab overlap and detent geometry but not the full tablet lever arm. Use it to inspect basic release and spring motion before printing the full cradle. Device-specific camera/control/USB cutouts are omitted from this reduced fixture; it contains no powered connector. Do not force a real tablet into this sample.

Physical checks remain UNRUN: slide force, tongue deflection/recovery, cone wear, automatic reseating, retention under upward/outward load, repeated cycles, actual USB disengagement margin, screen/bezel clearance, and hot ABS creep. Print both pieces, deburr, follow the intended sequence and its reverse, and record interference before changing clearance. Recheck full-size geometry after any change.

## Connector candidate

Both inserts fit within a common reference envelope and use the same two M3 attachment locations at X=tablet_w/2+18, Z=±34. The rear mount is integral to the full cradle; the removable cover approaches from the front. Seat each unpowered body into its insert by tilting under the front retaining lips, then mount the insert and cover. The rear mount has captive hex pockets. The CD0700 exposes both opposed ends; the Essager channel exposes its downward elbow exit. Downstream plug bodies remain outside. Do not force an unknown strain relief under a lip.

Actual insert/cover/cradle intersections are checked with only the intended face contacts at Y=-7 and Y=7 excluded by the 0.01 mm comparison tolerance. A shared cradle relief extends 60 mm above/below the assumed port. Independent 12 × 8 × 24 mm downstream plug witnesses pass through 13 mm outlet channels; these plug dimensions are provisional. Connector-body and camera/control/speaker reference witnesses do not intersect the model. Both complete connector housings clear the sampled removal path. A separate assumed USB tip has no collision with the tablet at the released slide/yaw poses. These checks use unmeasured seated transforms. They do not establish full electrical seating or zero port stress.

Print `part="fit_sample"` for both connector settings with `insert_clearance` 0.3, 0.5 and 0.7. The small motion sample tests rail fit; use `clearance` 0.3, 0.5 and 0.7 separately. Identify every piece with its clearance. Assemble unpowered first and measure axial alignment, end-stop contact, extraction distance, cable bend and body restraint before charging/audio tests. Any force through the USB port as a tablet stop is a failure. The insert wall between tablet and body carries the USB-C extraction load and is only 0.7 mm thick at the default clearance (0.5 mm at 0.7 mm) because bodies are assumed to start 2 mm beyond the tablet edge; inspect it on every fit sample and thicken it once the seated transform is measured. Charging, audio, microphone clearance, real camera view and fit remain UNRUN.

## Central support candidate

The keyed rectangular mast uses a longitudinal M5 slot with 50 mm between end centres and a cross bolt through both outer cheeks. The same bolt clamps the slide and retains it at travel ends. It must remain installed during height adjustment. Four M5 holes attach the mast flange to the bridge. Printed ribs support the flange; metal washers spread fastener loads.

The pitch joint has two cheeks, matching 5-degree teeth and a through M5 bolt with a captive nut. Tooth width follows `pitch_step` and `tooth_gap` (0.3 degrees per flank). Range is -15 to +15 degrees, at 5-degree indexes. Adjust only unloaded: loosen the bolt, spread the cheeks enough to disengage the teeth, reposition, reseat and tighten. Fine teeth, cheek flex and clamp force need service review and a coupon; the geometry does not establish strength. Do not force the joint across engaged teeth.

Digital tests cover heights 0/25/50 and pitch -15/0/+15: the tablet removal path against the mast, and the posed cradle, detent, cable clip and connector hardware against the mast. The earlier full-width bottom rail intersected the mast at -10 and -15 degrees; it now stops at the back-frame posts. All seven indexed tooth positions clear, rotating `tooth_gap + 0.5` degrees off an index in either direction hits the mating teeth, and the mast stays out of a generous independent cable corridor. The corridor reserves X=32..56, Y=45..105, Z=65..245 in the installed frame. At +15 degrees and zero height the cradle's top rail swings into its upper 12 mm, above the clip-to-mast cable loop. The corridor does not simulate a cable bending or confirm enough physical slack. Check the actual loop throughout continuous height adjustment and every pitch index, with cables connected but no load on the tablet port.

Export `slide_sample`, `mast_inner`, `pitch_joint` and `joint_rotor` for separate unpowered fit checks. The joint coupon omits the full cradle lever arm. Check bolt insertion, driver access, hex seating, washer bearing, full thread engagement without bottoming, zero cracked layers, smooth sliding, positive tooth engagement and no slip under the later declared load. All physical checks remain UNRUN.

## Standard feet

The same pad and yoke models are used at both ends of the bridge. Set `foot_pitch=[left,right]` (about X, fore/aft slope) and `foot_roll=[left,right]` (about Y, side-to-side slope), with ±15 degrees per axis. These parameters rotate standard parts; they do not generate dashboard contours. Neutral and opposite-corner angle combinations are checked against independently transformed planar contact fixtures, adjacent joint solids and driver-access witnesses. The base is checked against removal at all nine height/pitch combinations.

A separate cylindrical-dashboard fixture (250 mm radius) deliberately leaves a gap under a flat pad edge. Tangency is not full-area contact. Actual dashboard curvature, soft skins, texture, coatings, aged material, tape grade and removal damage remain UNRUN. Reject a placement with incomplete approved contact; do not fill a substantial gap with arbitrary tape stacks. A different location or standard pad concept may be needed if real dashboard geometry falls outside this model.

Fastener access must be checked before tape is applied. Set both foot angles on the actual surface without rocking, then tighten the four pivot clamps. The CAD pose is not a torque or friction rating. Driver sightline, vent access, vehicle functions and airbag clearance remain vehicle-specific checks.

## Physical protocols (all UNRUN)

Complete these records before an installed/road-use decision. These are proposed development checks, not safety ratings or a substitute for engineering qualification.

1. **Inputs and print inspection.** Record source revision, parameter file, filament grade/batch, printer, nozzle, layer height, wall/infill settings, orientation, supports and postprocessing. Ask the service to inspect every STL for connected solids, defects, unsupported surfaces and usable build-volume fit. Measure coupons, bores, nut pockets and flat tape faces; reject cracks, warped pads, loose body capture or obstructed controls. Repeat with the selected final material/process after any PLA trial.
2. **Fit and repeated removal.** Use the surrogate first. Plan 100 install/remove cycles, inspecting at 0/10/50/100. Record slide force with a gauge, detent recovery, wear, clearance and any permanent set. Verify that lift/outward escape is mechanically blocked while docked and that yaw cannot begin before actual USB disengagement. Zero unintended unplugging, fractures, jams or port side-load is required. Only then repeat carefully with the unpowered bare tablet. Record actual full-seating and end-stop positions for both connectors; never force the device against its port.
3. **Mass, load and locking.** Weigh all supported components; replace the 1,110 g planning budget. Measure each centre of mass and lever arm from the tape footprint. Record `F=sum(m_i)*a` and `M=sum(r_i cross F_i)` for the chosen bench forces/accelerations. Do not substitute an invented universal road acceleration. Secure the base to a sacrificial test fixture, use surrogate mass, and test full height at both pitch extremes. Record the chosen force, direction, dwell, clamp torque and measured movement. Any clamp slip, cracked layer, lost tooth engagement or permanent deformation is a failure. Establish loads and acceptance thresholds before increasing them.
4. **Heat/creep.** Measure cabin and mount temperatures in the intended parked-car conditions first. Choose and record a test temperature within the selected material, tape and connector specifications; no generic ABS temperature rating is assumed. Proposed development soak: 8 hours at the chosen temperature under measured surrogate load, three hot/cool cycles, with deflection readings hourly and after cooling. Test on a fixture without the tablet. Any progressive creep, released detent, loose clamp, bond lift or permanent set fails. A short soak does not establish long-term life.
5. **Adhesive contact and removal.** Select the exact tape grade with its supplier for the actual printed surface and dashboard material. Use expendable representative surfaces first, including texture/soft skin where applicable. Follow that tape's cleaning, pressure, dwell and removal instructions; no primer or solvent is assumed safe for the vehicle. Record bonded area, temperature, dwell, load and removal method. Reject rocking, unbonded regions, edge lift, finish marks, delamination or residue that cannot be removed by an approved method. Damage-free removal on the actual aged dashboard remains unproven until tested; it cannot be guaranteed from VHB branding.
6. **Electrical and cable checks.** After mechanical fit passes, verify charging during tablet use for each connector configuration, then audio for CD0700. Move through the full adjustment range and removal sequence. Record voltage/charging status, connector temperature, dropouts and cable tension. Reject intermittent charging/audio, crushed cables, strain-relief contact or port loading. Confirm the removable cover can be fitted with downstream plugs connected.
7. **Vehicle placement and vibration.** Before bonding, check driver sightlines, vents, controls, airbags, camera sightline and removal hand clearance in the W124. Repeat for every other vehicle; planar feet do not establish universal fit. After bench/heat/bond checks, begin stationary engine-on observations with surrogate mass. Record video of witness marks at each joint. A controlled low-speed assessment precedes representative rough surfaces; record speed, surface and duration. Reject any loosening, unintended release/unplugging, persistent wobble or unusable dashcam footage. Diagnose the moving joint before changing to twin supports. Do not adjust or remove the tablet while driving.
8. **Camera footage.** Inspect actual road footage at both height endpoints and all pitch indexes intended for use. Check that the lens aperture and full field of view avoid the frame, mast, cables, dashboard and reflections. Reposition only within the previously assessed vehicle envelope. Camera/control placeholders in CAD are not acceptance evidence.

## Qualification status

| Gate | Digital evidence | Physical status |
|---|---|---|
| Nominal tablet / cradle path | Sampled paths and forbidden probes pass for declared envelope | UNRUN; actual protrusions and clearances unmeasured |
| Connector location / cable exits | Both nominal variants and keep-outs checked | UNRUN; body, seated transform and electrical checks required |
| Mast overlap / pitch / feet | Declared positions and mating geometry checked | UNRUN; clamp force, teeth, stiffness and fatigue |
| Printable components | Renderer diagnostics and connected-volume checks | UNRUN; service slicer, actual build volume and print inspection |
| Cabin heat / creep | No thermal simulation | UNRUN |
| Adhesive contact / removal damage | Planar fixtures only; curved fixture intentionally shows a gap | UNRUN |
| Road stability / dashcam footage | No road or vibration simulation | UNRUN |
| Sightline / airbag / vehicle functions | No vehicle model or assessment | UNRUN |
| Crash retention | Not assessed | UNQUALIFIED |

The source and coupons can support the next measurement/fit iteration. They are not fitted manufacturing exports or an installed-mount approval.

## Export checks and reproducibility

Printable selectors now apply explicit candidate bed orientations. The suite reads binary STL bounds and checks bed Z=0; the surrogate must be 100 × 60 × 6.3 mm. The initial local `let` override did not propagate into globally defined OpenSCAD modules, so sample dimensions are now explicit module arguments. The corrected sample export is checked directly, in addition to the independent motion fixture.

The suite also rejects unknown fixture names (an unknown name must not masquerade as an empty intersection), negative fit clearances, insufficient retained mast overlap, invalid camera-cone angles, release travel that permits yaw before plug disengagement, and detent preload too small to hold the tablet against the cradle stops. Port offset is propagated through connector mount, insert and cover; that transform check does not qualify a non-default offset against every device feature. The visual port marker follows the tablet during removal.

`build/prototype/manifest.json` records the source revision, source hashes, CAD version, per-artifact overrides, STL bounds and hashes. Regenerate after any geometry change. Candidate bed orientation and a connected CGAL volume are not service slicer approval. The build-volume test is explicitly skipped until the print service supplies its usable volume.
