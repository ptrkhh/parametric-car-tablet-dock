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

module rigid() cradle_rigid(w, h);

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
else assert(false, str("unknown check: ", check));
