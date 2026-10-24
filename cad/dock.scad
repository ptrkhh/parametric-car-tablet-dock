// Parametric dashboard tablet dock.
// Tablet frame (unpitched): X occupant-right, Y inward toward the windshield, Z up.
// Occupants are at -Y, so OpenSCAD's Front view is the occupant view.
// The tablet origin is its centre when docked.
include <parameters.scad>

parts = ["reference", "assembly", "cradle", "motion_sample", "surrogate", "insert", "cover", "fit_sample"];
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
    assert(insert_clearance > 0 && insert_clearance <= 1, "insert_clearance must be in (0, 1]");
    assert(connector_gap - clearance - insert_clearance >= 0.4,
           "insert wall between tablet and connector body too thin");
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

// Port recess deep enough for the plug shell.
module usb_port() {
    translate([tablet_w / 2, 0, usb_z]) cube([2 * plug_engagement + 2, usb_marker[1], usb_marker[0]], center = true);
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
// and a roof following the top-right corner arc for upward capture. With the connector
// bay they widen and deepen to carry the bay's side rails.
module right_hooks(w, h, bay) {
    x0 = hook_x(w);
    x1 = w / 2 + (bay ? bay_w : wall);
    y0 = front_y() - wall;
    y1 = bay ? bay_y()[1] + mount_t : tablet_t / 2 + back_t;
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

// ---- Connector bay: tablet frame, right of the docked tablet ----
// Both bodies are centred on the port in Y. The bay is sized for the CD0700, the longer body.
// Inserts take the body from the right; the common cover closes that side and its boss
// stops the body against plug insertion. Outlets open to the front so cables lay in.
function bay_x() = [tablet_w / 2 + clearance, tablet_w / 2 + bay_w];
function span(c, r) = [c - r, c + r];
function bay_y() = span(0, cd0700_body[1] / 2 + 1 + insert_wall);
function bolt_z() = cd0700_body[2] / 2 + 1 + m3[0] / 2 + 1.5;
function bay_z() = span(usb_z, bolt_z() + m3[1] / 2 + 1.5);
function body_size(kind) = kind == "cd0700" ? cd0700_body : essager_body;
function body_top(kind) = kind == "cd0700" ? usb_z + cd0700_body[2] / 2 : usb_z + essager_plug_drop;
function body_x() = tablet_w / 2 + connector_gap;
function boss_x() = body_x() + max(cd0700_body[0], essager_body[0]) + insert_clearance;

module box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

// Purchased connector with its plug shell, as seated with the tablet docked (reference only).
module connector_body(kind) {
    b = body_size(kind);
    box([body_x(), body_x() + b[0]], span(0, b[1] / 2), [body_top(kind) - b[2], body_top(kind)]);
    box([tablet_w / 2 - plug_engagement, body_x()], span(0, plug_tip[1] / 2),
        span(usb_z, plug_tip[0] / 2));
}

module bolt_holes() {
    for (s = [-1, 1]) translate([tablet_w / 2 + m3_bolt_x, 0, usb_z + s * bolt_z()])
        rotate([90, 0, 0]) cylinder(d = m3[0], h = 100, center = true);
}

module connector_insert(kind) {
    b = body_size(kind);
    ic = insert_clearance;
    xc = body_x() + b[0] / 2;
    difference() {
        box(bay_x(), bay_y(), bay_z());
        // Exact pocket, a prism to the right face so the body slides in from the right.
        box([body_x() - ic, bay_x()[1] + 1], [-b[1] / 2 - ic, b[1] / 2 + ic],
            [body_top(kind) - b[2] - ic, body_top(kind) + ic]);
        // Common entry channel the cover boss fills.
        box([boss_x(), bay_x()[1] + 1], span(0, cd0700_body[1] / 2 + ic),
            span(usb_z, cd0700_body[2] / 2 + ic));
        // Plug hole through the wall facing the tablet.
        box([bay_x()[0] - 1, body_x()], span(0, plug_tip[1] / 2 + ic), span(usb_z, plug_tip[0] / 2 + ic));
        if (kind == "cd0700") for (top = [true, false]) {
            end = usb_z + (top ? 1 : -1) * cd0700_body[2] / 2;
            box([xc - downstream_plug[0] / 2 - ic, xc + downstream_plug[0] / 2 + ic],
                [bay_y()[0] - 1, downstream_plug[1] / 2 + ic],
                top ? [end - 0.1, bay_z()[1] + 1] : [bay_z()[0] - 1, end + 0.1]);
        } else
            box([xc - essager_relief[0] / 2 - ic, xc + essager_relief[0] / 2 + ic],
                [bay_y()[0] - 1, essager_relief[1] / 2 + ic],
                [bay_z()[0] - 1, body_top(kind) - b[2] + 0.1]);
        bolt_holes();
    }
}

// Common right-side cover: side plate, front flange carrying the bolts, and a boss that
// fills the entry channel to within insert_clearance of the body.
module connector_cover() {
    x1 = bay_x()[1];
    y0 = bay_y()[0] - wall;
    difference() {
        union() {
            box([x1, x1 + wall], [y0, bay_y()[1]], bay_z());
            box([x1 - 7, x1 + wall], [y0, bay_y()[0]], bay_z());
            box([boss_x(), x1 + 0.5], span(0, cd0700_body[1] / 2), span(usb_z, cd0700_body[2] / 2));
        }
        bolt_holes();
    }
}

// Rear mount behind the insert with captive M3 nut pockets, tied to both corner hooks by
// side rails at the outer edge; the space beside the rails stays open for cables.
module connector_mount(h) {
    y = [bay_y()[1], bay_y()[1] + mount_t];
    x1 = bay_x()[1];
    difference() {
        union() {
            box(bay_x(), y, bay_z());
            box([x1 - 5, x1], y, [bay_z()[1] - 1, h / 2 - hook_h + 1]);
            box([x1 - 5, x1], y, [-h / 2 + hook_h - 1, bay_z()[0] + 1]);
        }
        bolt_holes();
        for (s = [-1, 1]) translate([tablet_w / 2 + m3_bolt_x, y[1] - m3[2], usb_z + s * bolt_z()])
            rotate([-90, 0, 0]) cylinder(d = m3[1] / cos(30), h = m3[2] + 1, $fn = 6);
    }
}

module cradle_rigid(w = tablet_w, h = tablet_h, bay = true) {
    left_end(w, h);
    right_hooks(w, h, bay);
    back_frame(w, h);
    bottom_rail(w, h);
    if (bay) connector_mount(h);
}

module cradle(w = tablet_w, h = tablet_h, bay = true) {
    cradle_rigid(w, h, bay);
    detent_bump(w, h);
}

// Right side of the cradle around the bay, including the top hook as the tablet stop,
// for fitting a real tablet edge, insert, cover and connector.
module fit_sample() {
    intersection() {
        cradle();
        box([hook_x(tablet_w) - 2, bay_x()[1] + 1], [-50, 50], [bay_z()[0] - 2, tablet_h / 2 + clearance + wall + 1]);
    }
}

module assembly() {
    color("orange") cradle();
    color("peru") connector_insert(connector);
    color("sienna") connector_cover();
    color("red") connector_body(connector);
    tablet_pose(slide_mm, release_yaw_deg, lift_mm) color("dimgray") tablet_reference();
}

validate();
if (part == "reference") tablet_reference();
else if (part == "assembly") assembly();
else if (part == "cradle") cradle();
else if (part == "motion_sample") cradle(sample_w, sample_h, false);
else if (part == "surrogate") tablet_envelope(sample_w, tablet_t, sample_h);
else if (part == "insert") connector_insert(connector);
else if (part == "cover") connector_cover();
else if (part == "fit_sample") fit_sample();
