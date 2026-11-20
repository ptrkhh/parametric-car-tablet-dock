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
// Printed snap tongues hold the cover and the end cap; no screws. A tongue is relaxed once seated.
snap = [1.8, 5, 1.1, 0.3];       // tongue thickness (Z, the bending direction), width (X), barb height, window clearance
snap_x = 19;                     // cover tongue X from the tablet edge
snap_end = [4.2, 4.4];           // tongue centres beyond the CD0700 body ends (Z), bay ends beyond the tongue centres

// ---- Device feature placeholders (PROVISIONAL; measure the tablet) ----
camera = [-110, 62];             // rear camera centre X, Z
camera_half_angle = 35;          // view cone half-angle; recording mode unmeasured
front_camera = [0, 77];          // front camera on the top bezel, X, Z
speaker_z = [-50, 50];           // speaker openings on both side edges
speaker_h = 16;                  // speaker opening height
control_x = [-95, -45];          // power and volume keys on the top edge

// ---- Central support (PROVISIONAL; installation height and viewing angle unmeasured) ----
// A short fixed post carries the pitch fork; the height slide sits behind the tablet, between
// the pitch carriage and a rail on the cradle, so the screen can hang below the tape faces.
height_travel = 50;        // locked height range, along the cradle's own vertical (tilts with pitch)
pitch_range = 15;          // ± locked pitch about the nominal angle
pitch_step = 5;            // face-tooth index
nominal_pitch = 0;         // installed screen pitch at pitch_deg = 0; vertical until measured
tablet_bottom_z = -29;     // tablet bottom above the pad plane at zero height and pitch; lower limit is vent flow (unmeasured)
pad_drop = 5;              // the tablet's lowest point must sit this far below the pad plane at zero height, every pitch
pivot = [76, 9];           // pitch axis: Y behind the tablet, Z above the tablet centre at zero height (cradle frame)
lug_t = 12;                // carriage lug thickness (X)
lug_r = 30;                // carriage lug radius
cheek_t = 8;               // post fork cheek thickness
cheek_r = 32;              // fork cheek radius
teeth_r = [18, 28];        // face-tooth annulus on the lug and the +X cheek
teeth_play = 0.2;          // axial play at an index; about 0.4 to 0.6 degrees of rotational play
tongue = [21, 18];         // height rail head on the cradle, X × Y; X keeps the sleeve inside the M5 bolt length
rail_web = 10;             // web joining the rail head to the spine (X)
carriage_h = 60;           // carriage sleeve length along the rail, centred on the pivot
slide_gap = 0.3;           // per side between rail head and sleeve
sleeve_wall = [6, 4];      // side walls (X; carry the clamp nut), front lips and back wall (Y)
bridge_top = 18;           // bridge plate top, where the post stands, above the pad plane
flange = [70, 50, 5];      // post flange X, Y, Z
flange_front = 14;         // flange front edge ahead of the pitch axis (Y); clears the cradle at -15 degrees
min_overlap = 25;          // retained slide engagement at both ends of the travel
m5 = [5.6, 8.4, 4.4, 8.5, 5]; // clearance hole, nut pocket across flats, pocket depth, head diameter, head height
m5_len = 35;               // the only purchased screw: every adjustment clamp takes this M5 length
washer5 = [10, 1];         // M5 washer OD, thickness

// ---- Standard base: bridge and three identical tape feet (PROVISIONAL; no dashboard measured) ----
foot_spacing = 140;        // between the feet's pivot centres (X)
foot_y = 108;              // feet centre line (installed Y), behind the swept cradle
pad = [50, 70, 6];         // flat tape pad X, Y, thickness
pad_r = 8;                 // pad corner radius
pad_offset = 10;           // pad centre outboard of its pivots, so a tilted pad passes under the bridge arms
foot_pitch = [0, 0, 0];    // [left, right, rear] about X; + raises the pad's inward (+Y) edge
foot_roll = [0, 0, 0];     // [left, right, rear] about Y; + lowers the pad's occupant-right (+X) edge
foot_range = 15;           // ± per axis
pivot_a_z = 19;            // lower foot pivot (axis X) above the pad plane
pivot_b_z = 40;            // upper foot pivot (axis Y) above the pad plane
foot_lug = 16;             // lug thickness between cheeks
foot_gap = 1;              // washer gap each side of a lug
foot_cheek = 6;            // cheek thickness
bridge = [70, 63, 8];      // plate X, Y (from the flange front back past the foot pivots), Z; top at bridge_top
nose_gap = 10;             // dashboard nose allowance: nothing below the pad plane within this of the pads' front edge
// The screen hangs ahead of the front feet, so the dock tips forward. A tail carries a third foot
// and a weight tray toward the windshield: the weights cancel the pull on the rear tape.
// Weights are cheaper than printed length, so the tail is short and the tray roomy; no printed
// part is meant to act as weight.
rear_reach = 150;          // rear foot behind the front feet (Y); longer needs fewer weights
tail_w = 20;               // tail beam width (X), on the centre line from the bridge plate to the tray
ballast = [100, 80, 20];   // weight tray inside X, Y, Z, beside the rear foot
ballast_wall = 2.5;        // tray walls, floor and lid
lid_fit = [1.2, 0.3, 0.6]; // sliding lid: lip foot on the rim, running clearance, detent bump height

// ---- Housing: OEM-style surround on the front and sides; the back stays open (PROVISIONAL) ----
shell_t = 2.5;             // wall thickness
shell_gap = 0.5;           // gap from the shell to the cradle, cover and hooks it hides
shell_r = [14, 4];         // corner radius seen from the front, edge round on the front and back edges
hook_chamfer = 9;          // outer corners of the right hooks, so they stay inside the rounded corners
cap_snap = [15, 74];       // end cap snap tongues: X from the tablet edge, ±Z through the right hooks

// ---- Print service ----
build_volume = [0, 0, 0];  // usable ABS volume X, Y, Z; 0 = not yet supplied, fit unverified

// ---- Motion sample: reduced cradle and surrogate with the same retention geometry ----
sample_w = 100;
sample_h = 60;

$fn = 32;
