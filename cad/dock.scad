// Parametric dashboard tablet dock.
// Tablet frame (unpitched): X occupant-right, Y inward toward the windshield, Z up.
// Occupants are at -Y, so OpenSCAD's Front view is the occupant view.
// The tablet origin is its centre when docked.
include <parameters.scad>

parts = ["reference", "assembly", "cradle", "motion_sample", "surrogate"];
connectors = ["essager", "cd0700"];

function member(x, list) = len([for (v = list) if (v == x) v]) > 0;

module validate() {
    assert(tablet_w > 0 && tablet_t > 0 && tablet_h > 0, "tablet dimensions must be positive");
    assert(corner_r > 0 && 2 * corner_r < min(tablet_w, tablet_h), "corner_r must fit the tablet outline");
    // "none" loads the modules without geometry (tests/geometry_checks.scad).
    assert(part == "none" || member(part, parts), str("unknown part: ", part));
    assert(member(connector, connectors), str("unknown connector: ", connector));
    assert(clearance > 0, "clearance must be positive");
    assert(release_travel > plug_engagement + clearance, "release_travel must exceed plug_engagement + clearance");
    assert(yaw_relief > release_yaw, "yaw_relief must exceed release_yaw");
    assert(0 < detent_preload && detent_preload < detent_rise && detent_rise < corner_r,
           "detent needs 0 < preload < rise < corner_r");
}

// Bare-tablet collision solid: nominal box with rounded outline corners.
// No camera island or edge profile is modelled until measured.
module tablet_envelope(w = tablet_w, t = tablet_t, h = tablet_h, r = corner_r) {
    hull() for (sx = [-1, 1], sz = [-1, 1])
        translate([sx * (w / 2 - r), 0, sz * (h / 2 - r)])
            rotate([90, 0, 0]) cylinder(r = r, h = t, center = true);
}

// Removal sequence: slide left, yaw clockwise from above about the rear contact, lift.
module tablet_pose(slide_mm, release_yaw_deg, lift_mm) {
    translate([0, 0, lift_mm])
        translate(yaw_pivot) rotate([0, 0, -release_yaw_deg]) translate(-yaw_pivot)
            translate([-slide_mm, 0, 0]) children();
}

module usb_port() {
    translate([tablet_w / 2, 0, usb_z]) cube([4, usb_marker[1], usb_marker[0]], center = true);
}

module tablet_reference() {
    difference() {
        tablet_envelope();
        usb_port();
    }
}

// ---- Cradle: tablet frame, docked tablet centred at the origin ----
// Contact faces (floor, rear contact, right stop) sit exactly on the tablet faces;
// faces the tablet must move past (lips, roofs, hooks) keep `clearance`.
function front_y() = -tablet_t / 2 - clearance;                 // rear face of lips and hooks
function stop_x(w) = -w / 2 - release_travel - clearance;        // left wall: stop after release travel
function hook_x(w) = w / 2 - (release_travel - clearance);       // right hooks release beyond this slide
// Detent bump apex: `detent_rise` above the floor, `detent_preload` inside the docked corner arc.
function detent_x(w) = -w / 2 + corner_r
    - sqrt(pow(corner_r - detent_preload, 2) - pow(corner_r - detent_rise, 2));

// Vertical prism the left half sweeps while yawing inward about the rear contact.
module yaw_pocket(w, h) {
    x0 = stop_x(w);
    translate([0, 0, -h / 2]) linear_extrude(h + 50) polygon([
        [0, front_y()], [0, tablet_t / 2], [x0, tablet_t / 2 - x0 * tan(yaw_relief)], [x0, front_y()]]);
}

// Docked tablet outline raised through `clearance`, from the hook faces to the rear contact.
module seat(w, h) {
    d = tablet_t / 2 - front_y();
    translate([0, tablet_t / 2 - d / 2, 0])
        hull() for (z = [0, clearance]) translate([0, 0, z]) tablet_envelope(w, d, h);
}

// Left wall (slide stop), lip (outward capture) and roof (upward capture).
// The roof is short enough that the yawed left end lifts behind it.
module left_end(w, h) {
    x0 = stop_x(w);
    y0 = front_y() - wall;
    z0 = -h / 2 - floor_t;
    z1 = h / 2 + clearance + wall;
    translate([x0 - wall, y0, z0]) cube([wall, tablet_t / 2 + end_depth - y0, z1 - z0]);
    translate([x0 - wall, y0, z0]) cube([-w / 2 + lip_overlap - x0 + wall, wall, z1 - z0]);
    translate([x0 - wall, y0, h / 2 + clearance]) cube([-w / 2 + roof_len - x0 + wall, tablet_t / 2 + clearance - y0, wall]);
}

// Corner hooks: right stop, front overlap that blocks yaw until the slide passes hook_x,
// and a roof following the top-right corner arc for upward capture.
module right_hooks(w, h) {
    x0 = hook_x(w);
    x1 = w / 2 + wall;
    y0 = front_y() - wall;
    y1 = tablet_t / 2 + back_t;
    difference() {
        for (top = [true, false]) {
            z0 = top ? h / 2 - hook_h : -h / 2 - floor_t;
            z1 = top ? h / 2 + clearance + wall : -h / 2 + hook_h;
            translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);
        }
        seat(w, h);
    }
}

// Central rear contact (the yaw pivot) and the top-right rear rail, cut by the yaw pocket.
module back_frame(w, h) {
    difference() {
        union() {
            translate([-spine[0] / 2, tablet_t / 2, -h / 2 - floor_t]) cube([spine[0], spine[1], h + floor_t]);
            // Rail stays below the tablet top edge, hidden from the occupant view.
            translate([0, tablet_t / 2, h / 2 - rail_h]) cube([w / 2 + wall, back_t, rail_h]);
        }
        yaw_pocket(w, h);
    }
}

// Floor tongue rooted toward the centre; its free end carries the detent bump.
function tongue_x(w) = detent_x(w) - detent_rise - 1;

module bottom_rail(w, h) {
    x0 = stop_x(w) - wall;
    y0 = front_y() - wall;
    difference() {
        translate([x0, y0, -h / 2 - floor_t]) cube([w / 2 + wall - x0, tablet_t / 2 + spine[1] - y0, floor_t]);
        translate([tongue_x(w) - detent_gap, -detent_tongue[1] / 2 - detent_gap, -h / 2 - floor_t - 1])
            cube([detent_tongue[0] + detent_gap, detent_tongue[1] + 2 * detent_gap, floor_t + 2]);
    }
    translate([tongue_x(w), -detent_tongue[1] / 2, -h / 2 - detent_tongue[2]])
        cube([detent_tongue[0] + 1, detent_tongue[1], detent_tongue[2]]);
}

// Compliant region: the 45-degree bump deflects the tongue down during removal and
// installation. Rigid collision checks exclude it; its force is a physical test.
module detent_bump(w, h) {
    xb = detent_x(w);
    s = detent_rise + 0.2;
    translate([0, detent_tongue[1] / 2, -h / 2]) rotate([90, 0, 0])
        linear_extrude(detent_tongue[1]) polygon([[xb - s, -0.2], [xb, detent_rise], [xb + s, -0.2]]);
}

module cradle_rigid(w = tablet_w, h = tablet_h) {
    left_end(w, h);
    right_hooks(w, h);
    back_frame(w, h);
    bottom_rail(w, h);
}

module cradle(w = tablet_w, h = tablet_h) {
    cradle_rigid(w, h);
    detent_bump(w, h);
}

module assembly() {
    color("orange") cradle();
    tablet_pose(slide_mm, release_yaw_deg, lift_mm) {
        color("dimgray") tablet_reference();
        // Plug marker shows the occupant-right port in Front view.
        color("red") translate([tablet_w / 2 + 6, 0, usb_z]) cube([10, usb_marker[1], usb_marker[0]], center = true);
    }
}

validate();
if (part == "reference") tablet_reference();
else if (part == "assembly") assembly();
else if (part == "cradle") cradle();
else if (part == "motion_sample") cradle(sample_w, sample_h);
else if (part == "surrogate") tablet_envelope(sample_w, tablet_t, sample_h);
