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
