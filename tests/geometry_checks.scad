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

// ---- Connector witnesses, placed from the rules in docs/measurements.md ----
kind = "essager";
// Bolts sit beyond the CD0700 body ends; the bay ends beyond the nut pockets.
bolt_z = cd0700_body[2] / 2 + 1 + m3[0] / 2 + 1.5;
bay_half = bolt_z + m3[1] / 2 + 1.5;
function body_size(k) = k == "cd0700" ? cd0700_body : essager_body;
function body_top(k) = k == "cd0700" ? usb_z + cd0700_body[2] / 2 : usb_z + essager_plug_drop;
body_xc = w / 2 + connector_gap + body_size(kind)[0] / 2;

module body_witness(k) {
    b = body_size(k);
    translate([w / 2 + connector_gap, -b[1] / 2, body_top(k) - b[2]]) cube(b);
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
        z0 = body_top(k) - essager_body[2];
        along_z(z0, essager_relief, false);
        along_z(z0 - essager_relief[2], [cable_d, cable_d, 10], false);
    }
}
// M3 shanks through the cover flange, insert and rear mount.
module bolt_witness()
    for (s = [-1, 1]) translate([w / 2 + m3_bolt_x, 0, usb_z + s * bolt_z])
        rotate([90, 0, 0]) cylinder(d = 3, h = 60, center = true);
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

if (check == "runner_solid") cube(1);
else if (check == "runner_empty") intersection() { cube(1); translate([2, 0, 0]) cube(1); }
else if (check == "slide_then_yaw_then_lift_clearance") {
    assert(member(stage, ["slide", "yaw", "lift"]), str("unknown stage: ", stage));
    intersection() {
        rigid();
        if (stage == "slide") hull() { body(); slid(release_travel) body(); }
        else if (stage == "yaw") yawed(fraction * release_yaw) slid(release_travel) body();
        else hull() { released(); lifted(lift_clear) released(); }
    }
}
else if (check == "connected_yaw_is_blocked")
    intersection() { rigid(); yawed(probe_yaw) slid(fraction * plug_engagement) body(); }
else if (check == "docked_lift_is_blocked")
    intersection() { rigid(); half(side); lifted(probe_lift) body(); }
else if (check == "docked_left_edge_outward_is_blocked")
    // Outward translation, counted only against left-half features. (A turn about the right
    // hook line also catches the back-left corner on a zero-overlap lip edge: a false pass.)
    intersection() { rigid(); half("left"); multmatrix(translation([0, -probe_lift, 0])) body(); }
else if (check == "detent_engages_docked_tablet")
    intersection() { detent_bump(w, h); body(); }
else if (check == "both_insert_interfaces_match") {
    // Common envelope, no overlap with the cover or cradle, bolts clear through all three,
    // body and plug clear of every part.
    difference() {
        connector_insert(kind);
        e = collision_eps;
        translate([w / 2 + clearance - e, -cd0700_body[1] / 2 - 1 - insert_wall - e, usb_z - bay_half - e])
            cube([bay_w - clearance + 2 * e, cd0700_body[1] + 2 + 2 * insert_wall + 2 * e, 2 * bay_half + 2 * e]);
    }
    intersection() { connector_insert(kind); union() { lid(); mount(); } }
    intersection() { lid(); mount(); }
    intersection() { bolt_witness(); union() { connector_insert(kind); lid(); mount(); } }
    intersection() { union() { body_witness(kind); plug_witness(); } union() { connector_insert(kind); lid(); mount(); } }
}
else if (check == "connector_body_captured") {
    // 1 mm shifts of the body and its plug must meet the insert or cover.
    shift = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]][probe];
    assert(1 > insert_clearance + collision_eps, "capture probe within clearance");
    intersection() { union() { connector_insert(kind); lid(); }
                     multmatrix(translation(shift)) { body_witness(kind); plug_witness(); } }
}
else if (check == "connector_clear_before_yaw") {
    // The plug is out before the yaw starts; the posed tablet never meets connector hardware.
    assert(member(stage, ["slide", "yaw", "lift"]), str("unknown stage: ", stage));
    intersection() {
        union() { hardware(kind); if (stage != "slide") plug_witness(); }
        if (stage == "slide") hull() { body(); slid(release_travel) body(); }
        else if (stage == "yaw") yawed(fraction * release_yaw) slid(release_travel) body();
        else hull() { released(); lifted(lift_clear) released(); }
    }
}
else if (check == "cable_outlets_open")
    intersection() { downstream_witness(kind); union() { connector_insert(kind); lid(); mount(); } }
else if (check == "device_feature_clearances")
    intersection() { feature_witnesses(); union() { rigid(); connector_insert(kind); connector_cover(); } }
else if (check == "feature_witnesses_present") feature_witnesses();
else assert(false, str("unknown check: ", check));
