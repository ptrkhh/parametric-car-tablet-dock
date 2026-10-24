// Parametric dashboard tablet dock.
// Tablet frame (unpitched): X occupant-right, Y inward toward the windshield, Z up.
// Occupants are at -Y, so OpenSCAD's Front view is the occupant view.
// The tablet origin is its centre when docked.
include <parameters.scad>

parts = ["reference", "assembly", "cradle", "motion_sample", "surrogate", "insert", "cover", "fit_sample",
         "mast_outer", "mast_inner", "pitch_joint", "slide_sample", "bridge", "foot_yoke", "tape_foot"];
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
    assert(height_mm >= 0 && height_mm <= height_travel, "height_mm out of range");
    assert(abs(pitch_deg) <= pitch_range, "pitch_deg out of range");
    assert(pitch_deg % pitch_step == 0 && nominal_pitch % pitch_step == 0,
           "pitch_deg must be a multiple of pitch_step");
    assert(slide_overlap() >= min_overlap, "mast slide overlap below min_overlap at full height");
    assert(max([for (a = concat(foot_pitch, foot_roll)) abs(a)]) <= foot_range, "foot angles out of range");
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

// ---- Central support ----
// Installed frame: pad plane at Z=0. The cradle turns about the pivot line (X axis through
// [0, pivot[0], pivot[1]] in the cradle frame), then rises with the height setting.
function lift0() = tablet_bottom_z + tablet_h / 2;              // cradle origin Z at zero height
function pivot_z(hh) = lift0() + pivot[1] + hh;                 // installed pivot Z
function teeth_k() = sin(pitch_step / 4);                       // 45-degree flanks
function lug_mid() = lug_t / 2 + teeth_k() * teeth_r[1] + 0.4;  // lug tooth mid-plane
function cheek_in() = lug_mid() + teeth_play + teeth_k() * teeth_r[1] + 0.4; // +X cheek inner plane
function fork_x() = [-(lug_t / 2 + teeth_play + cheek_t), cheek_in() + cheek_t];
function fork_drop() = cheek_r + 6;                             // fork bottom below the pivot
function sleeve_top() = pivot_z(0) - fork_drop() - 2;
function tongue_len() = pivot_z(0) - (bridge_top + flange[2] + 1);  // 1 mm above the sleeve floor at zero height
function slide_overlap() = sleeve_top() - (pivot_z(height_travel) - tongue_len());
function clamp_z() = sleeve_top() - 10;
function sleeve_xy() = [tongue[0] / 2 + slide_gap + sleeve_wall[0], tongue[1] / 2 + slide_gap + sleeve_wall[1]];

module installed(hh, pp) {
    translate([0, 0, lift0() + hh]) translate([0, pivot[0], pivot[1]]) rotate([-(nominal_pitch + pp), 0, 0])
        translate([0, -pivot[0], -pivot[1]]) children();
}

module along_x(x0, x1, r) translate([x0, 0, 0]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0);
module nut_pocket(x_out, af, depth) // hex pocket entering from the +X face at x_out
    translate([x_out - depth, 0, 0]) rotate([0, 90, 0]) cylinder(d = af / cos(30), h = depth + 1, $fn = 6);

// Ring of 45-degree face teeth about the X axis, every flank through [mid, 0, 0] (Hirth form).
// Material lies on the -X side of the toothed surface, down to x = base; `odd` selects tips.
module face_teeth(mid, base, odd) {
    n = 2 * round(360 / pitch_step);
    k = teeth_k();
    pts = [for (j = [0 : n - 1], p = [0 : 3]) let(
        a = j * 360 / n, r = teeth_r[p % 2],
        x = p < 2 ? mid + ((j % 2 == 1) == odd ? k : -k) * r : base)
        [x, r * cos(a), r * sin(a)]];
    faces = [for (j = [0 : n - 1], f = [0 : 3]) let(i = 4 * j, m = 4 * ((j + 1) % n))
        f == 0 ? [i, m, m + 1, i + 1] : f == 1 ? [i, i + 2, m + 2, m] :
        f == 2 ? [i + 1, m + 1, m + 3, i + 3] : [i + 2, i + 3, m + 3, m + 2]];
    polyhedron(pts, faces);
}

// Cradle-side lug on a web from the spine: plain -X face, face teeth on +X (cradle frame).
module pitch_joint() {
    translate([0, pivot[0], pivot[1]]) difference() {
        union() {
            along_x(-lug_t / 2, lug_t / 2, lug_r);
            face_teeth(lug_mid(), lug_t / 2 - 0.01, false);
            box(span(0, lug_t / 2), [tablet_t / 2 + spine[1] - 1 - pivot[0], 0], [-20, 20]);
        }
        along_x(-lug_t, lug_t, m5[0] / 2);
    }
}

// Open cable clip beside the fork; 1 mm lips hold a 5 mm cable laid in from +X (cradle frame).
module cable_clip() {
    z = [pivot[1] - 14, pivot[1] - 6];
    y0 = tablet_t / 2 + spine[1] - 1;
    box([9, 27], [y0, 17], z);
    box([18, 20], [17, 23], z);
    box([18, 27], [23, 25], z);
    box([26, 27], [17, 18], z);
    box([26, 27], [22, 23], z);
}

// Inner mast: fork around the lug (toothed +X cheek, plain -X cheek) on a keyed tongue. The
// tongue slot carries the clamp bolt and stops travel at 0 and height_travel.
module mast_inner(hh = height_mm) {
    fx = fork_x();
    c = clamp_z() - pivot_z(0);
    translate([0, pivot[0], pivot_z(hh)]) difference() {
        union() {
            for (x = [[fx[0], fx[0] + cheek_t], [cheek_in(), fx[1]]]) hull() {
                along_x(x[0], x[1], cheek_r);
                box(x, span(0, tongue[1] / 2), [-fork_drop(), -fork_drop() + 1]);
            }
            box(fx, span(0, tongue[1] / 2), [-fork_drop(), -lug_r - 1.5]);
            box(span(0, tongue[0] / 2), span(0, tongue[1] / 2), [-tongue_len(), -fork_drop() + 1]);
            mirror([1, 0, 0]) face_teeth(-(lug_mid() + teeth_play), -cheek_in() - 0.01, true);
        }
        along_x(fx[0] - 1, fx[1] + 1, m5[0] / 2);
        nut_pocket(fx[1], m5[1], m5[2]);
        box(span(0, tongue[0]), span(0, m5[0] / 2), [c - height_travel - m5[0] / 2, c + m5[0] / 2]);
    }
}

// Outer mast: ribbed sleeve on a bolted flange. The back wall is split above the cross bolt
// so tightening it squeezes the side walls onto the tongue.
module mast_outer() {
    s = sleeve_xy();
    z0 = bridge_top + flange[2];
    difference() {
        union() {
            box(span(0, s[0]), span(pivot[0], s[1]), [bridge_top, sleeve_top()]);
            box(span(0, flange[0] / 2), span(pivot[0], flange[1] / 2), [bridge_top, z0]);
            for (x = [-10, 10], y = [pivot[0] - s[1], pivot[0] + s[1]]) {
                y1 = y < pivot[0] ? pivot[0] - flange[1] / 2 : pivot[0] + flange[1] / 2;
                translate([x - 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(4)
                    polygon([[y, z0 - 0.1], [y1, z0 - 0.1], [y, z0 + 15]]);
            }
        }
        box(span(0, tongue[0] / 2 + slide_gap), span(pivot[0], tongue[1] / 2 + slide_gap), [z0, sleeve_top() + 1]);
        box([-1.5, 1.5], [pivot[0], pivot[0] + s[1] + 1], [clamp_z() - 15, sleeve_top() + 1]);
        translate([0, pivot[0], clamp_z()]) {
            along_x(-s[0] - 1, s[0] + 1, m5[0] / 2);
            nut_pocket(s[0], m5[1], m5[2]);
        }
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (flange[0] / 2 - 7), pivot[0] + sy * (flange[1] / 2 - 7), bridge_top - 1])
                cylinder(d = m5[0], h = flange[2] + 2);
    }
}

// ---- Standard base: bridge and two identical feet, installed frame ----
// A pad's lug turns about X (lower pivot) in a yoke; the yoke turns about Y (upper pivot)
// between two bridge arms. Both feet use the same printed parts, the left one turned 180
// degrees. Angles change per car; the pads stay flat standard parts.
function foot_xf(s) = s * foot_spacing / 2;
function boss_r() = foot_lug / 2;                               // material round each foot bolt
function cheek_x() = [boss_r() + foot_gap, boss_r() + foot_gap + foot_cheek];

module along_y(y0, y1, r) translate([0, y0, 0]) rotate([-90, 0, 0]) cylinder(r = r, h = y1 - y0);

// Pad frame: pivots above the origin on the pad plane, inner side toward -X.
module tape_foot() {
    difference() {
        union() {
            translate([pad_offset, 0, 0]) linear_extrude(pad[2])
                offset(r = pad_r) square([pad[0] - 2 * pad_r, pad[1] - 2 * pad_r], center = true);
            hull() {
                box(span(0, boss_r()), span(0, boss_r()), [pad[2] - 0.01, pad[2] + 1]);
                translate([0, 0, pivot_a_z]) along_x(-boss_r(), boss_r(), boss_r());
            }
        }
        translate([0, 0, pivot_a_z]) along_x(-boss_r() - 1, boss_r() + 1, m5[0] / 2);
    }
}

// Pad frame: two cheeks round the pad lug (nut captive in the inner cheek) under a cross
// block that is the lug of the upper pivot.
module foot_yoke() {
    c = cheek_x();
    difference() {
        union() {
            for (x = [c, [-c[1], -c[0]]]) hull() {
                translate([0, 0, pivot_a_z]) along_x(x[0], x[1], boss_r());
                box(x, span(0, boss_r()), [pivot_b_z - boss_r(), pivot_b_z - boss_r() + 1]);
            }
            box(span(0, c[1]), span(0, boss_r()), span(pivot_b_z, boss_r()));
        }
        translate([0, 0, pivot_a_z]) {
            along_x(-c[1] - 1, c[1] + 1, m5[0] / 2);
            rotate([0, 0, 180]) nut_pocket(c[1], m5[1], m5[2]);
        }
        translate([0, 0, pivot_b_z]) along_y(-boss_r() - 1, boss_r() + 1, m5[0] / 2);
    }
}

// Plate under the mast flange (nuts from below) with two arms per side carrying the upper
// foot pivot; the arms leave the plate low so tilted pads pass beneath them.
module bridge() {
    xb = bridge[0] / 2;
    y0 = pivot[0] - bridge[1] / 2;
    c = cheek_x();
    difference() {
        union() {
            box(span(0, xb), [y0, y0 + bridge[1]], [bridge_top - bridge[2], bridge_top]);
            for (s = [-1, 1], ys = [[foot_y + c[0], foot_y + c[1]], [foot_y - c[1], foot_y - c[0]]]) hull() {
                box(s > 0 ? [xb - 2, xb] : [-xb, -xb + 2], ys, [bridge_top - bridge[2], bridge_top - 4]);
                translate([foot_xf(s), 0, pivot_b_z]) along_y(ys[0], ys[1], boss_r());
            }
        }
        for (s = [-1, 1]) translate([foot_xf(s), foot_y, pivot_b_z]) {
            along_y(-c[1] - 1, c[1] + 1, m5[0] / 2);
            rotate([0, 0, 90]) nut_pocket(c[1], m5[1], m5[2]);
        }
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (flange[0] / 2 - 7), pivot[0] + sy * (flange[1] / 2 - 7), 0]) {
                cylinder(d = m5[0], h = bridge_top + 1);
                translate([0, 0, bridge_top - bridge[2] - 1]) cylinder(d = m5[1] / cos(30), h = m5[2] + 1, $fn = 6);
            }
    }
}

module foot_yoke_at(s, fr)
    translate([foot_xf(s), foot_y, pivot_b_z]) rotate([0, fr, 0]) translate([0, 0, -pivot_b_z])
        rotate([0, 0, s > 0 ? 0 : 180]) foot_yoke();
module tape_foot_at(s, fp, fr)
    translate([foot_xf(s), foot_y, pivot_b_z]) rotate([0, fr, 0]) translate([0, 0, pivot_a_z - pivot_b_z])
        rotate([fp, 0, 0]) translate([0, 0, -pivot_a_z]) rotate([0, 0, s > 0 ? 0 : 180]) tape_foot();
module foot(s, fp, fr) { foot_yoke_at(s, fr); tape_foot_at(s, fp, fr); }
module base(fp = foot_pitch, fr = foot_roll) {
    bridge();
    for (i = [0, 1]) foot(2 * i - 1, fp[i], fr[i]);
}

module cradle_rigid(w = tablet_w, h = tablet_h, full = true) {
    left_end(w, h);
    right_hooks(w, h, full);
    back_frame(w, h);
    bottom_rail(w, h);
    if (full) {
        connector_mount(h);
        pitch_joint();
        cable_clip();
    }
}

module cradle(w = tablet_w, h = tablet_h, full = true) {
    cradle_rigid(w, h, full);
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
    installed(height_mm, pitch_deg) {
        color("orange") cradle();
        color("peru") connector_insert(connector);
        color("sienna") connector_cover();
        color("red") connector_body(connector);
        tablet_pose(slide_mm, release_yaw_deg, lift_mm) color("dimgray") tablet_reference();
    }
    color("slategray") mast_outer();
    color("lightslategray") mast_inner(height_mm);
    color("darkslategray") base();
}

// Candidate bed orientation: turn, then lift the lowest face to Z=0. Agree with the print service.
module on_bed(rot, lift) translate([0, 0, lift]) rotate(rot) children();
front_down = [90, 0, 0];      // cradle family and yoke: their -Y face on the bed
right_down = [0, 90, 0];      // +X face on the bed
left_down = [0, -90, 0];      // -X face on the bed

validate();
if (part == "reference") tablet_reference();
else if (part == "assembly") assembly();
// Lip, hook and floor fronts on the bed; roofs and lug teeth print as walls.
else if (part == "cradle") on_bed(front_down, wall - front_y()) cradle();
else if (part == "motion_sample") on_bed(front_down, wall - front_y()) cradle(sample_w, sample_h, false);
else if (part == "fit_sample") on_bed(front_down, wall - front_y()) fit_sample();
else if (part == "surrogate") on_bed(front_down, tablet_t / 2) tablet_envelope(sample_w, tablet_t, sample_h);
// Entry side down: pocket, plug hole and outlets print as vertical shafts and slots.
else if (part == "insert") on_bed(right_down, bay_x()[1]) connector_insert(connector);
else if (part == "cover") on_bed(right_down, bay_x()[1] + wall) connector_cover();
else if (part == "mast_outer") on_bed([0, 0, 0], -bridge_top) mast_outer();
// Toothed faces up: the +X cheek of the inner mast, the +X face of the lug coupon.
else if (part == "mast_inner") on_bed(right_down, fork_x()[1]) mast_inner(0);
else if (part == "pitch_joint") on_bed(left_down, lug_t / 2) pitch_joint();
else if (part == "slide_sample") on_bed([0, 0, 0], 30 - clamp_z())
    intersection() { mast_outer(); box([-50, 50], [0, 100], [clamp_z() - 30, sleeve_top() + 1]); }
else if (part == "bridge") on_bed([0, 0, 0], bridge[2] - bridge_top) bridge();
else if (part == "foot_yoke") on_bed(front_down, boss_r()) foot_yoke();
else if (part == "tape_foot") tape_foot();
