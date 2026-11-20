// Spatial fixtures for tests/test_geometry.py; `check` matches the test name without `test_`.
// Allowed motion / keep-out fixtures export an intersection that must be empty.
// Forbidden-motion probes export an intersection with a retaining feature that must be nonempty.
// Poses here are written as explicit matrices from the documented conventions, independently
// of tablet_pose() in dock.scad, so one sign error cannot make both agree.
include <../cad/dock.scad>
part = "none";

check = "";
sample = false;   // true: run on the motion-sample cradle and surrogate
stage = "";       // removal stage: "slide", "yaw" or "lift"
fraction = 0;     // position within a stage or plug engagement, 0..1
side = "";        // "left" or "right" half of the tablet frame
probe = 0;        // probe index within a fixture

w = sample ? sample_w : tablet_w;
h = sample ? sample_h : tablet_h;
probe_yaw = 1;    // degrees
probe_lift = 2;   // mm
lift_clear = h + clearance + wall + 1;
assert(probe_lift > clearance + collision_eps, "lift probe within clearance");

// Tablet inset by collision_eps per face so exact face contact is not a collision.
module body() tablet_envelope(w - 2 * collision_eps, tablet_t - 2 * collision_eps,
                              h - 2 * collision_eps, corner_r - collision_eps);

function translation(v) = [[1, 0, 0, v[0]], [0, 1, 0, v[1]], [0, 0, 1, v[2]], [0, 0, 0, 1]];
// Rotation about a vertical line through (px, py); positive a turns counter-clockwise from above.
function turn(a, px, py) = [[cos(a), -sin(a), 0, px - cos(a) * px + sin(a) * py],
                            [sin(a),  cos(a), 0, py - sin(a) * px - cos(a) * py],
                            [0, 0, 1, 0], [0, 0, 0, 1]];

module slid(s) multmatrix(translation([-s, 0, 0])) children();
// Removal yaw: left edge inward (+Y) about the rear contact line at the tablet back.
module yawed(a) multmatrix(turn(-a, 0, tablet_t / 2)) children();
module lifted(l) multmatrix(translation([0, 0, l])) children();
module released() yawed(release_yaw) slid(release_travel) body();

module half(which) {
    big = 1000;
    translate([which == "left" ? -big : 0, -big / 2, -big / 2]) cube(big);
}

module rigid() cradle_rigid(w, h, !sample);
// The separate right end cap; the motion sample has no housing.
module shell_cap() if (!sample) end_cap();

// ---- Connector witnesses, placed from the rules in docs/measurements.md ----
kind = "essager";
// The cover's tongues pass beyond the CD0700 body ends; the bay ends beyond their windows.
bay_half = cd0700_body[2] / 2 + snap_end[0] + snap_end[1];
function witness_size(k) = k == "cd0700" ? cd0700_body : essager_body;
function witness_top(k) = k == "cd0700" ? usb_z + cd0700_body[2] / 2 : usb_z + essager_plug_drop;
body_xc = w / 2 + connector_gap + witness_size(kind)[0] / 2;

module body_witness(k) {
    b = witness_size(k);
    translate([w / 2 + connector_gap, -b[1] / 2, witness_top(k) - b[2]]) cube(b);
}
// Plug shell from the body face into the docked port.
module plug_witness()
    translate([w / 2 - plug_engagement, -plug_tip[1] / 2, usb_z - plug_tip[0] / 2])
        cube([plug_engagement + connector_gap, plug_tip[1], plug_tip[0]]);
module along_z(z0, size, up) translate([body_xc - size[0] / 2, -size[1] / 2, up ? z0 : z0 - size[2]]) cube(size);
// Downstream plug bodies or strain relief, then 10 mm of cable, outward from the body.
module downstream_witness(k) {
    if (k == "cd0700") for (up = [true, false]) {
        z0 = usb_z + (up ? 1 : -1) * cd0700_body[2] / 2;
        along_z(z0, downstream_plug, up);
        along_z(z0 + (up ? 1 : -1) * downstream_plug[2], [cable_d, cable_d, 10], up);
    } else {
        z0 = witness_top(k) - essager_body[2];
        along_z(z0, essager_relief, false);
        along_z(z0 - essager_relief[2], [cable_d, cable_d, 10], false);
    }
}
// Touching faces are intended contacts: separate the parts by collision_eps.
module lid() translate([collision_eps, -collision_eps, 0]) connector_cover();
module mount() translate([0, collision_eps, 0]) rigid();
module hardware(k) { connector_insert(k); lid(); body_witness(k); downstream_witness(k); }

// ---- Device feature references (provisional placeholders) ----
module feature_witnesses() {
    translate([camera[0], tablet_t / 2, camera[1]]) rotate([-90, 0, 0])
        cylinder(h = 250, r1 = 0, r2 = 250 * tan(camera_half_angle));
    translate([front_camera[0], -tablet_t / 2, front_camera[1]]) rotate([90, 0, 0])
        cylinder(h = 150, r1 = 0, r2 = 150 * tan(camera_half_angle));
    for (x = [-w / 2 - 4, w / 2], z = speaker_z) translate([x, -tablet_t / 2, z - speaker_h / 2]) cube([4, tablet_t, speaker_h]);
    translate([control_x[0], -tablet_t / 2, h / 2]) cube([control_x[1] - control_x[0], tablet_t, 10]);
}

// Tablet swept through one removal stage: slide and lift are exact sweeps, yaw is one pose.
module removal(st) {
    assert(member(st, ["slide", "yaw", "lift"]), str("unknown stage: ", st));
    if (st == "slide") hull() { body(); slid(release_travel) body(); }
    else if (st == "yaw") yawed(fraction * release_yaw) slid(release_travel) body();
    else hull() { released(); lifted(lift_clear) released(); }
}

// ---- Installed frame: pad plane at Z=0. The post is fixed; the carriage turns about the pivot
// line; the cradle turns with it and slides along its own pitched Z by the height ----
height = 0;       // mm of height travel
pitch = 0;        // degrees from the nominal pitch
function rot_x(a) = [[1, 0, 0, 0], [0, cos(a), -sin(a), 0], [0, sin(a), cos(a), 0], [0, 0, 0, 1]];
pivot_installed = tablet_bottom_z + h / 2 + pivot[1];
function pitch_m(pp) = translation([0, pivot[0], pivot_installed]) * rot_x(-(nominal_pitch + pp))
    * translation([0, -pivot[0], -pivot_installed]);
function placement(hh, pp) = pitch_m(pp) * translation([0, 0, tablet_bottom_z + h / 2 + hh]);
module placed() multmatrix(placement(height, pitch)) children();
module support() { post(); multmatrix(pitch_m(pitch)) carriage(); }

// Cable keep-outs (assumed 5 mm cable): route in the cradle frame from the bay, along the floor
// and back through the clip; corridor beside the post down to the bridge. The loop between the
// clip and the corridor hangs free and is not modelled.
module cable_route() {
    c = cable_d;
    x0 = w / 2 + 5;
    xc = clip_x() - c / 2;
    translate([x0, 13, -h / 2 + 8]) cube([c, c, h / 2 - 8 + 55]);         // behind the bay, both outlets
    translate([xc, 13, -h / 2 + 8]) cube([x0 - xc + c, c, c]);            // along the bottom, behind the floor
    translate([xc, 13, -h / 2 + 8]) cube([c, tablet_t / 2 + spine[1] + 15 - 13, c]); // back through the clip
}
// M5 witnesses along a bolt axis (X), head on the -X side. b = [head face, nut face, length].
k_teeth = sin(pitch_step / 4);
cheek_in = lug_t / 2 + 2 * (k_teeth * teeth_r[1] + 0.4) + teeth_play;   // +X cheek inner plane
pitch_bolt = [-(lug_t / 2 + teeth_play + cheek_t), cheek_in + cheek_t, 35];
sleeve_out = tongue[0] / 2 + slide_gap + sleeve_wall[0];
clamp_bolt = [-sleeve_out, sleeve_out, 35];
head_mid = tablet_t / 2 + spine[1] + clearance + sleeve_wall[1] + slide_gap + tongue[1] / 2;
module rod_x(x0, x1, d, fn = 32) translate([x0, 0, 0]) rotate([0, 90, 0]) cylinder(d = d, h = x1 - x0, $fn = fn);
module bolt_clear(b) {
    wt = washer5[1];
    rod_x(b[0] - wt, b[0] - wt + b[2], 5);                                  // shank
    rod_x(b[0] - wt - collision_eps, b[0] - collision_eps, washer5[0]);         // washer
    rod_x(b[0] - wt - m5[4], b[0] - wt - collision_eps, m5[3]);             // head
    rod_x(b[0] - wt - m5[4] - 60, b[0] - wt - m5[4], m5[3]);                // hex key and hand
    rod_x(b[1] - m5[2] + collision_eps, b[1] - m5[2] + 4, 8 / cos(30), 6);  // 8 AF × 4 nut on the pocket floor
}
// Rings that must lie wholly inside material: under the washer and under the nut.
// Inset by collision_eps from the faces and the bore so no face coincides with the part.
module bolt_bearing(b) {
    e = collision_eps;
    difference() { rod_x(b[0] + e, b[0] + 0.5, washer5[0]); rod_x(b[0] - 1, b[0] + 1, m5[0] + 0.2); }
    difference() { rod_x(b[1] - m5[2] - 0.5, b[1] - m5[2] - e, 8); rod_x(b[1] - m5[2] - 1, b[1], m5[0] + 0.2); }
}
module at_pitch_bolt() translate([0, pivot[0], pivot_installed]) children();
// The clamp bolt crosses the carriage at the pivot height, through the rail head's middle.
module at_clamp_bolt() multmatrix(pitch_m(pitch)) translate([0, head_mid, pivot_installed]) children();

module cable_corridor() translate([24, pivot[0] - 10, bridge_top + flange[2] + 7]) cube([22, 30, pivot_installed - bridge_top - flange[2] + 5]);

// ---- Standard base: feet on independently tilted planar dashboard fixtures ----
foot_side = 1;    // -1 left, +1 right, 0 rear (a right foot on the tail)
fpitch = 0;       // foot angle about X for the foot under test
froll = 0;        // foot angle about Y for the foot under test
function rot_y(a) = [[cos(a), 0, sin(a), 0], [0, 1, 0, 0], [-sin(a), 0, cos(a), 0], [0, 0, 0, 1]];
function foot_x(s) = s == 0 ? tail_w / 2 + (foot_spacing - bridge[0]) / 2 : s * foot_spacing / 2;
function foot_at_y(s) = s == 0 ? foot_y + rear_reach : foot_y;
function hand(s) = s < 0 ? -1 : 1;                 // which way the pad is offset from its pivots
function fi(s) = s < 0 ? 0 : s > 0 ? 1 : 2;        // index into [left, right, rear]
// Pad frame (pad bottom centre at the origin) to installed: roll about the upper pivot, pitch
// about the lower pivot.
function pad_m(s, p, r) = translation([foot_x(s), foot_at_y(s), pivot_b_z]) * rot_y(r)
    * translation([0, 0, pivot_a_z - pivot_b_z]) * rot_x(p) * translation([0, 0, -pivot_a_z]);
function yoke_m(s, r) = translation([foot_x(s), foot_at_y(s), pivot_b_z]) * rot_y(r) * translation([0, 0, -pivot_b_z]);
// Dashboard: a 120 mm square slab whose top plane carries the pad, lowered by collision_eps.
module dash(s, p, r) multmatrix(pad_m(s, p, r)) translate([-60, -60, -20 - collision_eps]) cube([120, 120, 20]);
module pad_outline() offset(r = pad_r) square([pad[0] - 2 * pad_r, pad[1] - 2 * pad_r], center = true);
// Films 0.05–0.3 mm below and above the fixture plane over the pad footprint. The lower one
// must lie inside the dashboard and the upper one inside the CAD pad: together they require
// the real tape face to sit on the plane with full flat contact.
module contact_film(s, p, r, z = -0.3) multmatrix(pad_m(s, p, r)) translate([hand(s) * pad_offset, 0, z])
    linear_extrude(0.25) offset(delta = -0.2) pad_outline();
// Feet at test angles: the foot under test gets (fpitch, froll), the others the opposite corner.
function test_pitch() = [for (s = [-1, 1, 0]) s == foot_side ? fpitch : -fpitch];
function test_roll() = [for (s = [-1, 1, 0]) s == foot_side ? froll : -froll];
lug_half = foot_lug / 2;
cheek_out = lug_half + foot_gap + foot_cheek;
foot_bolt = [-cheek_out, cheek_out, 35];
// Lower bolt: axis X in the yoke frame, head on the outer side. Upper bolt: axis Y, head at the front.
module at_lower_bolt(s, r) multmatrix(yoke_m(s, r)) translate([0, 0, pivot_a_z]) rotate([0, 0, s < 0 ? 0 : 180]) children();
module at_upper_bolt(s) translate([foot_x(s), foot_at_y(s), pivot_b_z]) rotate([0, 0, 90]) children();
// Washers filling the two 1 mm gaps beside a lug.
// Washers (washer5 thick) against both lug faces; they fit only if each gap is wide enough.
module gap_washers() for (x = [-lug_half - washer5[1], lug_half])
    rod_x(x + collision_eps, x + washer5[1] - collision_eps, washer5[0]);
module foot_hardware(fn) for (s = [-1, 1, 0]) {
    r = test_roll()[fi(s)];
    at_lower_bolt(s, r) { if (fn == "clear") { bolt_clear(foot_bolt); gap_washers(); } else bolt_bearing(foot_bolt); }
    at_upper_bolt(s) { if (fn == "clear") { bolt_clear(foot_bolt); gap_washers(); } else bolt_bearing(foot_bolt); }
}
module test_base() base(test_pitch(), test_roll());

// ---- Weight tray: written from the parameters, independently of the CAD's tray functions ----
grow = 0;         // enlarges the weight block per face; the negative control
tray_in_x = [tail_w / 2 - ballast_wall - ballast[0], tail_w / 2 - ballast_wall];
tray_in_y = [foot_y + rear_reach - ballast[1] / 2, foot_y + rear_reach + ballast[1] / 2];
tray_floor = bridge_top - bridge[2] + ballast_wall;
// Weights filling the tray's stated inside, inset by collision_eps.
module ballast_block() let(e = collision_eps - grow) translate([tray_in_x[0] + e, tray_in_y[0] + e, tray_floor + e])
    cube([ballast[0] - 2 * e, ballast[1] - 2 * e, ballast[2] - 2 * e]);

if (check == "runner_solid") cube(1);
else if (check == "runner_empty") intersection() { cube(1); translate([2, 0, 0]) cube(1); }
else if (check == "slide_then_yaw_then_lift_clearance") intersection() { union() { rigid(); shell_cap(); } removal(stage); }
else if (check == "connected_yaw_is_blocked")
    intersection() { rigid(); yawed(probe_yaw) slid(fraction * plug_engagement) body(); }
else if (check == "connected_lift_is_blocked") {
    // While the plug is engaged the right end must neither lift (probe 0) nor roll up about
    // the slid left end once the left roof clearance is taken up (probe 1), on the right half.
    s = fraction * plug_engagement;
    px = -w / 2 - s + corner_r;
    pz = h / 2 + clearance;
    intersection() {
        rigid();
        half("right");
        if (probe == 0) lifted(probe_lift) slid(s) body();
        else multmatrix(translation([px, 0, pz]) * rot_y(-probe_yaw) * translation([-px, 0, -pz]))
            lifted(clearance - collision_eps) slid(s) body();
    }
}
else if (check == "docked_lift_is_blocked")
    intersection() { rigid(); half(side); lifted(probe_lift) body(); }
else if (check == "docked_left_edge_outward_is_blocked")
    // Outward translation, counted only against left-half features. (A turn about the right
    // hook line also catches the back-left corner on a zero-overlap lip edge: a false pass.)
    intersection() { rigid(); half("left"); multmatrix(translation([0, -probe_lift, 0])) body(); }
else if (check == "detent_engages_docked_tablet")
    intersection() { detent_bump(w, h); body(); }
else if (check == "both_insert_interfaces_match") {
    // Common envelope, no overlap with the cover (with its tongues) or cradle, body and plug
    // clear of every part.
    difference() {
        connector_insert(kind);
        e = collision_eps;
        translate([w / 2 + clearance - e, -cd0700_body[1] / 2 - 1 - insert_wall - e, usb_z - bay_half - e])
            cube([bay_w - clearance + 2 * e, cd0700_body[1] + 2 + 2 * insert_wall + 2 * e, 2 * bay_half + 2 * e]);
    }
    intersection() { connector_insert(kind); union() { lid(); mount(); } }
    intersection() { lid(); mount(); }
    intersection() { union() { body_witness(kind); plug_witness(); } union() { connector_insert(kind); lid(); mount(); } }
}
else if (check == "connector_body_captured") {
    // 1 mm shifts of the body and its plug must meet the insert or cover.
    shift = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]][probe];
    assert(1 > insert_clearance + collision_eps, "capture probe within clearance");
    intersection() { union() { connector_insert(kind); lid(); }
                     multmatrix(translation(shift)) { body_witness(kind); plug_witness(); } }
}
else if (check == "connector_body_held_in_z")
    // Body alone, without its plug shell: 1 mm along Z (the downstream plug axis) must meet
    // the insert or cover, or downstream plug forces go through the plug shell into the port.
    intersection() { union() { connector_insert(kind); lid(); }
                     multmatrix(translation([0, 0, probe == 0 ? 1 : -1])) body_witness(kind); }
else if (check == "connector_clear_before_yaw") {
    // The plug is out before the yaw starts; the posed tablet never meets connector hardware.
    intersection() { union() { hardware(kind); if (stage != "slide") plug_witness(); } removal(stage); }
}
else if (check == "cable_outlets_open")
    intersection() { downstream_witness(kind); union() { connector_insert(kind); lid(); mount(); } }
else if (check == "device_feature_clearances")
    intersection() { feature_witnesses(); union() { rigid(); shell_cap(); connector_insert(kind); connector_cover(); } }
else if (check == "feature_witnesses_present") feature_witnesses();
else if (check == "pitch_teeth_lock")
    // Empty at a tooth index; any turn beyond the axial play off an index meets the mating teeth.
    intersection() { multmatrix(pitch_m(pitch)) carriage(); post(); }
else if (check == "slide_engagement") {
    // The rail head fills a thin slice at each end of the sleeve (probe 0 bottom, 1 top).
    z = pivot_installed + (probe == 0 ? -carriage_h / 2 : carriage_h / 2 - 0.5);
    intersection() { placed() rigid(); translate([-tongue[0] / 2, head_mid - 5, z]) cube([tongue[0], 10, 0.5]); }
}
else if (check == "tablet_below_pads")
    // At zero height the tablet reaches at least pad_drop below the pad plane.
    intersection() { placed() body(); translate([-500, -500, -500]) cube([1000, 1000, 500 - pad_drop]); }
else if (check == "dashboard_nose_keepout") {
    // Nothing below the pad plane closer than nose_gap to the pads' front edge (level dashboard).
    y0 = foot_y - pad[1] / 2 - nose_gap;
    intersection() {
        translate([-500, y0, -500]) cube([1000, 500, 500]);
        union() { placed() { rigid(); shell_cap(); hardware(kind); body(); released(); cable_route(); } support(); }
    }
}
else if (check == "mechanism_hidden_front")
    // Occupant (front) silhouette at zero height: support and base lie inside the tablet and housing.
    linear_extrude(1) difference() {
        projection() rotate([90, 0, 0]) { support(); test_base(); }
        projection() rotate([90, 0, 0]) placed() { body(); rigid(); shell_cap(); }
    }
else if (check == "housing_fit")
    // The end cap, with its tongues through the hooks, clears the cradle, insert, cover with its
    // tongues, connector, plugs and cable route.
    intersection() {
        translate([0, -collision_eps, 0]) end_cap();
        union() { rigid(); hardware(kind); cable_route(); }
    }
else if (check == "snaps_hold") {
    // A 1 mm move of a snapped part must meet what holds it. End cap and cover: pulled forward
    // (barbs behind the hooks and the rear mount) or pushed right (tongues in their windows).
    // Insert: up or down against the cover's tongues.
    assert(1 > snap[3] + 0.2 + collision_eps, "snap probe within clearance");
    // Seating faces are lifted off by collision_eps so only the tongues can meet anything.
    if (probe < 4) intersection() {
        rigid();
        multmatrix(translation(probe % 2 == 0 ? [0, -1, 0] : [1, -collision_eps, 0])) if (probe < 2) end_cap(); else connector_cover();
    }
    else intersection() { lid(); multmatrix(translation([0, 0, probe == 4 ? 1 : -1])) connector_insert(kind); }
}
else if (check == "support_and_cable_clearance_at_extremes") {
    assert(member(stage, ["slide", "yaw", "lift", "parts", "cables", "camera"]), str("unknown stage: ", stage));
    if (member(stage, ["slide", "yaw", "lift"])) intersection() { support(); placed() removal(stage); }
    else if (stage == "parts") {
        intersection() { support(); placed() { rigid(); shell_cap(); connector_insert(kind); connector_cover(); } }
        intersection() { post(); multmatrix(pitch_m(pitch)) carriage(); }
    }
    else if (stage == "cables") intersection() {
        union() { cable_corridor(); placed() cable_route(); }
        union() { support(); placed() { rigid(); shell_cap(); hardware(kind); } }
    }
    else intersection() { support(); placed() feature_witnesses(); }
}
else if (check == "support_fasteners_clear")
    intersection() {
        union() { at_pitch_bolt() bolt_clear(pitch_bolt); at_clamp_bolt() bolt_clear(clamp_bolt); }
        union() { support(); placed() { rigid(); hardware(kind); } }
    }
else if (check == "foot_contact") {
    // The foot under test sits flat on its own tilted plane and nothing of it enters the plane.
    difference() { contact_film(foot_side, fpitch, froll); dash(foot_side, fpitch, froll); }
    difference() { contact_film(foot_side, fpitch, froll, 0.05); foot(foot_side, fpitch, froll); }
    intersection() { foot(foot_side, fpitch, froll); dash(foot_side, fpitch, froll); }
}
else if (check == "curved_dashboard_gap")
    // A 250 mm radius dashboard (axis X) tangent at the pad centre: the flat pad cannot touch
    // all of it, so the contact film is not wholly inside.
    difference() {
        contact_film(foot_side, 0, 0);
        translate([foot_x(foot_side), foot_at_y(foot_side), -250 - collision_eps]) rotate([0, 90, 0]) cylinder(r = 250, h = 120, center = true, $fn = 360);
    }
else if (check == "foot_joints_clear") {
    // Bridge, yokes and pads never overlap one another at the test angles.
    for (s = [-1, 1, 0]) {
        p = test_pitch()[fi(s)];
        r = test_roll()[fi(s)];
        intersection() { union() { bridge(); ballast_lid(); } union() { foot_yoke_at(s, r); tape_foot_at(s, p, r); } }
        intersection() { foot_yoke_at(s, r); tape_foot_at(s, p, r); }
    }
}
else if (check == "foot_clamps_tool_access")
    intersection() {
        foot_hardware("clear");
        union() {
            test_base();
            translate([0, 0, collision_eps]) post();
            for (s = [-1, 1, 0]) dash(s, test_pitch()[fi(s)], test_roll()[fi(s)]);
        }
    }
else if (check == "foot_clamps_bearing") difference() { foot_hardware("bearing"); test_base(); }
else if (check == "snaps_go_in") {
    // Fitting path: end cap (probe 0) and cover (1) pushed straight back over their last 25 mm,
    // lid (2) slid back along the rim over its whole length. The test runs it without barbs and
    // bump, which the tongues and the lid spring over; anything else in the way blocks the part.
    if (probe == 0) intersection() { union() { rigid(); hardware(kind); } translate([0, -fraction * 25 - collision_eps, 0]) end_cap(); }
    else if (probe == 1) intersection() { union() { mount(); connector_insert(kind); body_witness(kind); downstream_witness(kind); }
                                          translate([collision_eps, -fraction * 25 - collision_eps, 0]) connector_cover(); }
    else intersection() { union() { bridge(); post(); for (s = [-1, 1, 0]) foot(s, 0, 0); }
                          translate([0, -fraction * (ballast[1] + 2 * ballast_wall), collision_eps]) ballast_lid(); }
}
else if (check == "ballast_fit") {
    // Probe 0: weights the size of the tray's stated inside fit under the lid, and the lid lies
    // on the rim between the lips. The lips stop a 1 mm lift (1); the bump stops 1 mm of sliding out (2).
    if (probe == 0) {
        intersection() { union() { bridge(); ballast_lid(); } ballast_block(); }
        intersection() { bridge(); translate([0, 0, collision_eps]) ballast_lid(); }
    }
    else intersection() { bridge(); multmatrix(translation(probe == 1 ? [0, 0, 1] : [0, -1, collision_eps])) ballast_lid(); }
}
else if (check == "base_clears_removal_envelope") {
    assert(member(stage, ["slide", "yaw", "lift", "parts"]), str("unknown stage: ", stage));
    intersection() {
        test_base();
        if (stage == "parts") union() {
            placed() { rigid(); shell_cap(); hardware(kind); cable_route(); }
            translate([0, 0, collision_eps]) support();
            cable_corridor();
        }
        else placed() removal(stage);
    }
}
else if (check == "support_fasteners_bearing")
    difference() {
        union() { at_pitch_bolt() bolt_bearing(pitch_bolt); at_clamp_bolt() bolt_bearing(clamp_bolt); }
        support();
    }
else assert(false, str("unknown check: ", check));
