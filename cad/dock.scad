// Parametric dashboard tablet dock.
// Tablet frame (unpitched): X occupant-right, Y inward toward the windshield, Z up.
// Occupants are at -Y, so OpenSCAD's Front view is the occupant view.
// The tablet origin is its centre when docked.
include <parameters.scad>

parts = ["reference", "assembly"];
connectors = ["essager", "cd0700"];

function member(x, list) = len([for (v = list) if (v == x) v]) > 0;

module validate() {
    assert(tablet_w > 0 && tablet_t > 0 && tablet_h > 0, "tablet dimensions must be positive");
    assert(corner_r > 0 && 2 * corner_r < min(tablet_w, tablet_h), "corner_r must fit the tablet outline");
    assert(member(part, parts), str("unknown part: ", part));
    assert(member(connector, connectors), str("unknown connector: ", connector));
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

module assembly() {
    tablet_pose(slide_mm, release_yaw_deg, lift_mm) {
        color("dimgray") tablet_reference();
        // Plug marker shows the occupant-right port in Front view.
        color("red") translate([tablet_w / 2 + 6, 0, usb_z]) cube([10, usb_marker[1], usb_marker[0]], center = true);
    }
}

validate();
if (part == "reference") tablet_reference();
else if (part == "assembly") assembly();
