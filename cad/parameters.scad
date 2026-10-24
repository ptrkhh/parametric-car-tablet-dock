// Single source for dock dimensions. Units: mm, degrees, grams.
// PROVISIONAL = modelling choice still to be measured or fit-tested; see docs/measurements.md.

// ---- Public controls (override with -D) ----
part = "assembly";      // see `parts` in dock.scad
connector = "essager";  // "essager" or "cd0700"
height_mm = 0;          // locked height travel
pitch_deg = 0;          // locked pitch relative to the nominal installed angle
slide_mm = 0;           // removal step 1: leftward travel, >= 0
release_yaw_deg = 0;    // removal step 2: left edge inward / right edge outward, >= 0
lift_mm = 0;            // removal step 3: upward lift, >= 0

// ---- Samsung Galaxy Tab S7 SM-T875, published nominal ----
tablet_w = 253.8;       // X, landscape width
tablet_t = 6.3;         // Y, thickness
tablet_h = 165.3;       // Z, landscape height
tablet_mass = 500;      // g

// ---- Tablet features (unmeasured) ----
corner_r = 8;           // PROVISIONAL outline corner radius
usb_z = 0;              // PROVISIONAL USB-C centre height from tablet centre, on the right edge
usb_marker = [9, 3.5];  // visual port marker (Z, Y), not a fit dimension

// Removal yaw turns about the rear contact line behind the tablet centre.
yaw_pivot = [0, tablet_t / 2, 0];

// ---- Cradle retention (PROVISIONAL until the motion sample is tested) ----
clearance = 0.5;        // running clearance at lips, roofs and hooks
plug_engagement = 6;    // USB-C insertion depth; unmeasured
release_travel = 8;     // leftward slide before yaw; must exceed plug_engagement + clearance
release_yaw = 12;       // yaw that moves the left end behind the left roof
yaw_relief = 15;        // wedge angle of the left pocket behind the tablet; > release_yaw
wall = 3;               // cradle wall thickness
floor_t = 6;            // bottom rail thickness under the tablet
back_t = 4;             // top-right rear rail depth
spine = [20, 12];       // central rear contact width (X) and depth (Y)
lip_overlap = 5;        // left lip over the front bezel
roof_len = 14;          // left roof along the top edge, from the docked left edge
hook_h = 22;            // right corner hook length along the edge
rail_h = 12;            // top-right rear rail height
end_depth = 30;         // left end wall depth behind the tablet back
detent_preload = 1;     // bump apex interference with the docked lower-left corner
detent_rise = 1.5;      // bump apex height above the floor
detent_tongue = [30, 6, 2]; // compliant floor tongue length (X), width (Y), thickness (Z)
detent_gap = 0.6;       // slot around the tongue
collision_eps = 0.01;   // test-only face inset; not a print clearance

// ---- Connectors and right-side bay (PROVISIONAL; seated transforms unmeasured) ----
connector_gap = 2;               // tablet right edge to connector body face
plug_tip = [8.4, 2.6];           // USB-C plug shell, Z × Y
cd0700_body = [12.7, 8.9, 49.3]; // X protrusion, Y thickness, Z length; centred on the port
essager_body = [12.7, 6.3, 16];  // 90-degree elbow, X, Y, Z; unmeasured
essager_plug_drop = 4;           // plug centre below the elbow top; the cable exits downward
downstream_plug = [12, 8, 24];   // CD0700 downstream plug bodies, X, Y, Z; unmeasured
essager_relief = [6, 6, 20];     // Essager strain relief below the elbow; unmeasured
cable_d = 5;                     // downstream cable diameter allowance
insert_clearance = 0.5;          // body pocket, plug hole, outlets and cover boss; fit variants 0.3/0.5/0.7
insert_wall = 1.6;               // insert front and back walls around the thickest body
bay_w = 23;                      // bay width from the tablet edge (X)
mount_t = 5;                     // rear mount thickness behind the insert
m3 = [3.4, 5.8, 2.7];            // M3 clearance hole, nut pocket across flats, pocket depth
m3_bolt_x = 19.5;                // insert/cover bolt X from the tablet edge

// ---- Device feature placeholders (PROVISIONAL; measure the tablet) ----
camera = [-110, 62];             // rear camera centre X, Z
camera_half_angle = 35;          // view cone half-angle; recording mode unmeasured
front_camera = [0, 77];          // front camera on the top bezel, X, Z
speaker_z = [-50, 50];           // speaker openings on both side edges
speaker_h = 16;                  // speaker opening height
control_x = [-95, -45];          // power and volume keys on the top edge

// ---- Motion sample: reduced cradle and surrogate with the same retention geometry ----
sample_w = 100;
sample_h = 60;

$fn = 32;
