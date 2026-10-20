# Prototype validation record

This record separates digital geometry from physical qualification. No printed part, connector, tablet, dashboard, tape bond, or vehicle has been tested.

## Cradle candidate

The rigid cradle uses a recessed back frame, left front lip and roof, right retaining hooks, and a central rear contact. The flexible left spring supplies a provisional automatic detent; its elastic behaviour is excluded from rigid interference checks.

The provisional release is 8 mm left, then 12 degrees clockwise viewed from above, then lift. USB engagement is assumed to be 6 mm until measured. The right hooks prevent the tested 1-degree yaw at slides 0, 3, and 5.9 mm without using the plug as a blocker. A 2 mm docked upward probe and a 1-degree left-edge-outward probe intersect the cradle.

Allowed slide and lift checks use the hull of their endpoint envelopes. Yaw uses 25 samples at 0.5-degree intervals, including endpoints. Each tablet face is inset 0.01 mm to avoid OpenSCAD's zero-volume face-contact export behaviour. These tests do not prove all intermediate angular poses, combined escape paths, forces, tolerance stacks, or deformation. Transforms in the fixture are independent of the production pose transform.

The renderer tests reject parse failures and all WARNING/ERROR diagnostics, including CGAL warnings with exit status zero. Expected empty intersections require the exact empty-top-level diagnostic and no STL. Nonempty checks require a correctly sized binary STL with positive facet count; this is not mesh-topology analysis.

### Small sample

Export `part="motion_sample"` and `part="surrogate"`. The sample uses a 100 × 60 × 6.3 mm dummy with a provisional 5 mm corner radius. It preserves tab overlap and spring geometry but not the full tablet lever arm. Use it to inspect basic release and spring motion before printing the full cradle. It contains no powered connector. Do not force a real tablet into this sample.

Physical checks remain UNRUN: slide force, spring deflection/recovery, automatic reseating, retention under upward/outward load, repeated cycles, actual USB disengagement margin, screen/bezel clearance, and hot ABS creep. Print both pieces, deburr, follow the intended sequence and its reverse, and record interference before changing clearance. Recheck full-size geometry after any change.

## Connector candidate

Both inserts fit within a common reference envelope and use the same two M3 attachment locations at X=tablet_w/2+18, Z=±34. The rear mount is integral to the full cradle; the removable cover approaches from the front. Seat each unpowered body into its insert by tilting under the front retaining lips, then mount the insert and cover. The rear mount has captive hex pockets. The CD0700 exposes both opposed ends; the Essager channel exposes its downward elbow exit. Downstream plug bodies remain outside. Do not force an unknown strain relief under a lip.

Independent outlet witnesses and the camera/control/speaker reference witnesses do not intersect the model. Both complete connector housings clear the sampled removal path. A separate assumed USB tip has no collision with the tablet at the released slide/yaw poses. These checks use unmeasured seated transforms. They do not establish full electrical seating or zero port stress.

Print `part="fit_sample"` for both connector settings with `insert_clearance` 0.3, 0.5 and 0.7. The small motion sample tests rail fit; use `clearance` 0.3, 0.5 and 0.7 separately. Identify every piece with its clearance. Assemble unpowered first and measure axial alignment, end-stop contact, extraction distance, cable bend and body restraint before charging/audio tests. Any force through the USB port as a tablet stop is a failure. Charging, audio, microphone clearance, real camera view and fit remain UNRUN.

## Central support candidate

The keyed rectangular mast uses a longitudinal M5 slot with 50 mm between end centres and a cross bolt through both outer cheeks. The same bolt clamps the slide and retains it at travel ends. It must remain installed during height adjustment. Four M5 holes attach the mast flange to the bridge. Printed ribs support the flange; metal washers spread fastener loads.

The pitch joint has two cheeks, matching 5-degree teeth and a through M5 bolt with a captive nut. Range is -15 to +15 degrees, at 5-degree indexes. Adjust only unloaded: loosen the bolt, spread the cheeks enough to disengage the teeth, reposition, reseat and tighten. Fine teeth, cheek flex and clamp force need service review and a coupon; the geometry does not establish strength. Do not force the joint across engaged teeth.

Digital tests cover heights 0/25/50 and pitch -15/0/+15, the tablet removal path against the mast, all seven indexed tooth positions, and a generous independent cable corridor. The corridor reserves X=32..56, Y=45..105, Z=65..245 in the installed frame. It does not simulate a cable bending or confirm enough physical slack. Check the actual loop throughout continuous height adjustment and every pitch index, with cables connected but no load on the tablet port.

Export `slide_sample`, `mast_inner`, `pitch_joint` and `joint_rotor` for separate unpowered fit checks. The joint coupon omits the full cradle lever arm. Check bolt insertion, driver access, hex seating, washer bearing, full thread engagement without bottoming, zero cracked layers, smooth sliding, positive tooth engagement and no slip under the later declared load. All physical checks remain UNRUN.

## Standard feet

The same pad and yoke models are used at both ends of the bridge. Set `foot_pitch=[left,right]` and `foot_roll=[left,right]`, with ±15 degrees per axis. These parameters rotate standard parts; they do not generate dashboard contours. Neutral and opposite-corner angle combinations are checked against independently transformed planar contact fixtures, adjacent joint solids and driver-access witnesses. The base is checked against removal at all nine height/pitch combinations.

A separate cylindrical-dashboard fixture (250 mm radius) deliberately leaves a gap under a flat pad edge. Tangency is not full-area contact. Actual dashboard curvature, soft skins, texture, coatings, aged material, tape grade and removal damage remain UNRUN. Reject a placement with incomplete approved contact; do not fill a substantial gap with arbitrary tape stacks. A different location or standard pad concept may be needed if real dashboard geometry falls outside this model.

Fastener access must be checked before tape is applied. Set both foot angles on the actual surface without rocking, then tighten the four pivot clamps. The CAD pose is not a torque or friction rating. Driver sightline, vent access, vehicle functions and airbag clearance remain vehicle-specific checks.
