// Parametric dashboard tablet dock.
// Tablet frame (unpitched): X occupant-right, Y inward toward the windshield, Z up.
// Occupants are at -Y, so OpenSCAD's Front view is the occupant view.
// The tablet origin is its centre when docked.
include <parameters.scad>

parts = ["reference", "assembly", "cradle", "motion_sample", "surrogate", "insert", "cover", "fit_sample",
         "end_cap", "post", "carriage", "pitch_joint", "slide_sample", "bridge", "ballast_lid", "foot_yoke",
         "tape_foot"];
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
    assert(carriage_h >= min_overlap, "carriage_h below min_overlap");
    assert(pivot_z() - fork_drop() >= post_seat(), "post too short for the pivot height");
    assert(pivot[0] - cheek_r >= sleeve_y()[1] + 1, "fork cheeks must clear the carriage sleeve");
    assert(flange_y()[0] + bridge[1] >= foot_y + cheek_x()[1], "bridge plate must reach the foot pivots");
    assert(max([for (a = concat(foot_pitch, foot_roll)) abs(a)]) <= foot_range, "foot angles out of range");
    assert(len(foot_pitch) == 3 && len(foot_roll) == 3, "foot_pitch and foot_roll take [left, right, rear]");
    assert(rear_reach >= pad[1] / 2 + ballast[1] / 2 + ballast_wall + 10, "rear_reach too short: the tray would meet the front pads");
    // One bolt size: under a washer, the tip must pass the 4 mm nut seated on its pocket floor.
    assert(max(2 * sleeve_x(), fork_x()[1] - fork_x()[0], 2 * cheek_x()[1]) <= m5_len - washer5[1] + m5[2] - 4,
           "a clamped joint is too wide for the standard M5 bolt");
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
// bay they widen and deepen to carry the bay's side rails, lose their outer corners to the
// end cap's rounded corners, and have a window each for the end cap's snap tongues.
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
        if (bay) {
            for (z = [h / 2 + clearance + wall, -h / 2 - floor_t]) translate([x1, 0, z]) rotate([0, 45, 0])
                cube([hook_chamfer * sqrt(2), 100, hook_chamfer * sqrt(2)], center = true);
            for (s = [-1, 1]) translate(cap_snap_at(s)) snap_window(y0 - 1, y1 + 1, s);
        }
    }
}

// Roof over the top edge just left of the hooks: upward capture while the plug is still in,
// where the corner arc has slid out from under the hook roof. It has no front overlap, so the
// right end swings out beneath it; the yawed tablet lifts clear in front of it.
function right_roof_x(w) = w / 2 - corner_r - plug_engagement - 2;
module right_roof(w, h) {
    box([right_roof_x(w), hook_x(w) + 1], [front_y(), tablet_t / 2 + clearance], [h / 2 + clearance, h / 2 + clearance + wall]);
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
// Inserts take the body from the right. The common cover pushes on from the front: its side
// plate closes the right side and its boss stops the body against plug insertion. Outlets open
// to the front so cables lay in.
function bay_x() = [tablet_w / 2 + clearance, tablet_w / 2 + bay_w];
function span(c, r) = [c - r, c + r];
function bay_y() = span(0, cd0700_body[1] / 2 + 1 + insert_wall);
function snap_z() = cd0700_body[2] / 2 + snap_end[0];
function bay_z() = span(usb_z, snap_z() + snap_end[1]);
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

// Snap tongue: a flat spring along +Y from y0 that passes through a window and hooks behind the
// far face at y1 with a barb toward dir (Z). It bends in Z, inside the print layers of the cover
// and end cap. The window leaves room on the other side for the barb to pass. Two tongues with
// opposite barbs locate a part within the clearance and cannot both let go without being pressed.
module snap_tongue(y0, y1, dir) mirror([0, 0, dir < 0 ? 1 : 0]) {
    yc = y1 + 0.2;                             // catch face, just behind the far face
    box(span(0, snap[1] / 2), [y0, yc + 3 * snap[2]], span(0, snap[0] / 2));
    hull() {
        box(span(0, snap[1] / 2), [yc, yc + 0.5], [0, snap[0] / 2 + snap[2]]);
        box(span(0, snap[1] / 2), [yc, yc + 3 * snap[2]], [0, snap[0] / 2]);
    }
}
module snap_window(y0, y1, dir) mirror([0, 0, dir < 0 ? 1 : 0])
    box(span(0, snap[1] / 2 + snap[3]), [y0, y1], [-snap[0] / 2 - snap[2] - snap[3], snap[0] / 2 + snap[3]]);
module at_cover_snap(s) translate([tablet_w / 2 + snap_x, 0, usb_z + s * snap_z()]) children();
module cover_windows() for (s = [-1, 1]) at_cover_snap(s) snap_window(-50, 50, s);

module connector_insert(kind) {
    b = body_size(kind);
    ic = insert_clearance;
    xc = body_x() + b[0] / 2;
    difference() {
        box(bay_x(), bay_y(), bay_z());
        // Exact pocket, a prism to the right face so the body slides in from the right.
        box([body_x() - ic, bay_x()[1] + 1], [-b[1] / 2 - ic, b[1] / 2 + ic],
            [body_top(kind) - b[2] - ic, body_top(kind) + ic]);
        // Common entry channel the cover boss fills, open to the front for the boss to enter.
        box([boss_x(), bay_x()[1] + 1], [bay_y()[0] - 1, cd0700_body[1] / 2 + ic],
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
        cover_windows();
    }
}

// Common right-side cover: side plate, front flange, and a boss that fills the entry channel to
// within insert_clearance of the body. Two tongues from the flange pass through the insert and
// the rear mount and hook behind the mount, so the cover holds the insert without screws.
module connector_cover() {
    x1 = bay_x()[1];
    y0 = bay_y()[0] - wall;
    box([x1, x1 + wall], [y0, bay_y()[1]], bay_z());
    box([x1 - 7, x1 + wall], [y0, bay_y()[0]], bay_z());
    box([boss_x(), x1 + 0.5], [bay_y()[0] - 0.5, cd0700_body[1] / 2], span(usb_z, cd0700_body[2] / 2));
    for (s = [-1, 1]) at_cover_snap(s) snap_tongue(y0, bay_y()[1] + mount_t, s);
}

// Rear mount behind the insert with windows for the cover's tongues, tied to both corner hooks by
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
        cover_windows();
    }
}

// ---- Central support ----
// Installed frame: pad plane at Z=0. The post is fixed. The carriage turns about the pivot line
// (X axis through [0, pivot[0], pivot_z()]); the cradle turns with it and slides along it by the
// height setting, in its own pitched Z. So the slide length sits behind the tablet, not under it.
function lift0() = tablet_bottom_z + tablet_h / 2;              // cradle origin Z at zero height and pitch
function pivot_z() = lift0() + pivot[1];                        // installed pivot Z, fixed
function post_seat() = bridge_top + flange[2];                  // flange top
function teeth_k() = sin(pitch_step / 4);                       // 45-degree flanks
function lug_mid() = lug_t / 2 + teeth_k() * teeth_r[1] + 0.4;  // lug tooth mid-plane
function cheek_in() = lug_mid() + teeth_play + teeth_k() * teeth_r[1] + 0.4; // +X cheek inner plane
function fork_x() = [-(lug_t / 2 + teeth_play + cheek_t), cheek_in() + cheek_t];
function fork_drop() = cheek_r + 6;                             // fork bottom below the pivot
function mean(v) = (v[0] + v[1]) / 2;
// Rail head (cradle frame Y), carriage sleeve around it, and the head's Z span: the sleeve stays
// fully on the head from zero to full height; 2 mm spare at each end.
function head_y() = let(y0 = tablet_t / 2 + spine[1] + clearance + sleeve_wall[1] + slide_gap) [y0, y0 + tongue[1]];
function sleeve_y() = [head_y()[0] - slide_gap - sleeve_wall[1], head_y()[1] + slide_gap + sleeve_wall[1]];
function sleeve_x() = tongue[0] / 2 + slide_gap + sleeve_wall[0];
function rail_z() = [pivot[1] - height_travel - carriage_h / 2 - 2, pivot[1] + carriage_h / 2 + 2];
function flange_y() = [pivot[0] - flange_front, pivot[0] - flange_front + flange[1]];

module pitched(pp) translate([0, pivot[0], pivot_z()]) rotate([-(nominal_pitch + pp), 0, 0])
    translate([0, -pivot[0], -pivot_z()]) children();
module installed(hh, pp) pitched(pp) translate([0, 0, lift0() + hh]) children();

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

// Carriage lug in the pivot frame: plain -X face, face teeth on +X, web forward to Y = -web.
module pitch_lug(web) {
    difference() {
        union() {
            along_x(-lug_t / 2, lug_t / 2, lug_r);
            face_teeth(lug_mid(), lug_t / 2 - 0.01, false);
            box(span(0, lug_t / 2), [-web, 0], [-20, 20]);
        }
        along_x(-lug_t, lug_t, m5[0] / 2);
    }
}

// Height rail on the cradle spine (cradle frame): keyed head on a web. The head's slot carries the
// clamp bolt and stops the travel; its top is free so the carriage slides on from above; its
// underside slopes into the web for printing floor-down.
module height_rail(h) {
    hy = head_y();
    z = rail_z();
    zf = -h / 2 - floor_t;
    difference() {
        union() {
            box(span(0, rail_web / 2), [tablet_t / 2 + spine[1] - 1, hy[0] + 1], [zf, z[1]]);
            hull() {
                box(span(0, tongue[0] / 2), hy, z);
                box(span(0, tongue[0] / 2), [hy[0], hy[0] + 0.01], [max(z[0] - tongue[1], zf), z[0]]);
            }
        }
        box(span(0, tongue[0]), span(mean(hy), m5[0] / 2), [pivot[1] - height_travel - m5[0] / 2, pivot[1] + m5[0] / 2]);
    }
}

// Open cable clip behind the floor (cradle frame): the cable comes along the floor's back edge,
// turns backward in a 6 mm channel whose lips (4 mm opening) hold a 5 mm cable laid in from
// above, and leaves toward the post beside the carriage.
function clip_x() = sleeve_x() + 9;
module cable_clip() {
    c = cable_d;
    xc = clip_x();
    zc = -tablet_h / 2 + 8;                    // cable underside, level with the route along the floor
    y0 = tablet_t / 2 + spine[1];
    box(span(xc, c / 2 + 2), [y0 - 1, y0 + 13], [-tablet_h / 2 - floor_t, zc - 0.5]);
    for (s = [-1, 1]) {
        box(s > 0 ? [xc + c / 2 + 0.5, xc + c / 2 + 2] : [xc - c / 2 - 2, xc - c / 2 - 0.5], [y0 + 3, y0 + 13], [zc - 1, zc + c + 2]);
        box(s > 0 ? [xc + c / 2 - 0.5, xc + c / 2 + 0.5] : [xc - c / 2 - 0.5, xc - c / 2 + 0.5], [y0 + 3, y0 + 13], [zc + c + 0.5, zc + c + 2]);
    }
}

// Post: fork round the carriage lug (toothed +X cheek, plain -X cheek) on a ribbed flange. It
// stands on the bridge plate and prints as one piece with it, so no bolts join them.
module post() {
    fx = fork_x();
    fy = flange_y();
    z0 = post_seat();
    zb = pivot_z() - lug_r - 1.5;              // block top, below the lug
    difference() {
        union() {
            translate([0, pivot[0], pivot_z()]) {
                for (x = [[fx[0], fx[0] + cheek_t], [cheek_in(), fx[1]]]) hull() {
                    along_x(x[0], x[1], cheek_r);
                    box(x, span(0, tongue[1] / 2), [-fork_drop(), -fork_drop() + 1]);
                }
                mirror([1, 0, 0]) face_teeth(-(lug_mid() + teeth_play), -cheek_in() - 0.01, true);
            }
            box(fx, span(pivot[0], tongue[1] / 2), [z0 - 0.1, zb]);
            box(span(0, flange[0] / 2), fy, [bridge_top, z0]);
            for (x = [-10, 10], y = [pivot[0] - tongue[1] / 2, pivot[0] + tongue[1] / 2])
                translate([x - 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(4)
                    polygon([[y, z0 - 0.1], [y < pivot[0] ? fy[0] : fy[1], z0 - 0.1], [y, zb]]);
        }
        translate([0, pivot[0], pivot_z()]) {
            along_x(fx[0] - 1, fx[1] + 1, m5[0] / 2);
            nut_pocket(fx[1], m5[1], m5[2]);
        }
    }
}

// Carriage, installed frame at zero pitch: sleeve on the rail head (front lips either side of
// the web), lug behind it on the pitch axis. The cross bolt through the side walls and the
// head's slot squeezes the walls (the front is open at the web) and stops the travel.
module carriage() {
    s = sleeve_x();
    sy = sleeve_y();
    zc = pivot_z();
    difference() {
        union() {
            box(span(0, s), sy, span(zc, carriage_h / 2));
            translate([0, pivot[0], zc]) pitch_lug(pivot[0] - sy[1] + 1);
        }
        box(span(0, tongue[0] / 2 + slide_gap), [head_y()[0] - slide_gap, head_y()[1] + slide_gap], span(zc, carriage_h / 2 + 1));
        box(span(0, rail_web / 2 + clearance), [sy[0] - 1, head_y()[0]], span(zc, carriage_h / 2 + 1));
        translate([0, mean(head_y()), zc]) {
            along_x(-s - 1, s + 1, m5[0] / 2);
            nut_pocket(s, m5[1], m5[2]);
        }
    }
}

// ---- Standard base: bridge and three identical feet, installed frame ----
// A pad's lug turns about X (lower pivot) in a yoke; the yoke turns about Y (upper pivot)
// between two bridge arms. All feet use the same printed parts, the left one turned 180
// degrees. Angles change per car; the pads stay flat standard parts.
// Feet: s = -1 left, +1 right, 0 rear. The rear foot is a right foot moved back by rear_reach
// onto the tail's +X side, so its arms, bolts and tool access are the right foot's.
function arm_reach() = (foot_spacing - bridge[0]) / 2;          // plate or tail edge to the foot pivots
function foot_xf(s) = s == 0 ? tail_w / 2 + arm_reach() : s * foot_spacing / 2;
function foot_yf(s) = s == 0 ? foot_y + rear_reach : foot_y;
// Weight tray, outer box: left of the tail's +X face, centred on the rear foot in Y, on the plate's underside.
function tray_x() = [tail_w / 2 - ballast[0] - 2 * ballast_wall, tail_w / 2];
function tray_y() = span(foot_y + rear_reach, ballast[1] / 2 + ballast_wall);
function tray_z() = [bridge_top - bridge[2], bridge_top - bridge[2] + ballast_wall + ballast[2]];
// Lid: slides in from the front along the tray's rim, under lips on the two sides and the rear,
// and clicks behind a bump on the front rim. `c` is the gap to the lips; k runs up the lid's
// thickness (0 rim, 1 top), so the lips keep a foot on the rim and lean in over the lid's edges.
module lid_solid(c, y0, k0 = 0, k1 = 1) hull() for (k = [k0, k1])
    let(e = lid_fit[0] + k * (ballast_wall - lid_fit[0]) + c, z = tray_z()[1] + k * ballast_wall)
        box([tray_x()[0] + e, tray_x()[1] - e], [y0, tray_y()[1] - e], [z, z + 0.01]);
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

// Plate under the post with a tail back to the weight tray. Two arms
// per foot carry the upper foot pivot; they leave the plate or tray low so tilted pads pass
// beneath them. Everything stands on the plate's underside, so it prints without support there.
module bridge() {
    xb = bridge[0] / 2;
    y0 = flange_y()[0];
    c = cheek_x();
    z0 = bridge_top - bridge[2];
    tx = tray_x();
    ty = tray_y();
    tz = tray_z();
    difference() {
        union() {
            box(span(0, xb), [y0, y0 + bridge[1]], [z0, bridge_top]);
            box(span(0, tail_w / 2), [y0 + bridge[1] - 1, ty[0] + 1], tz);
            box(tx, ty, tz);
            difference() {                         // lips over the lid's side and rear edges
                box(tx, ty, [tz[1] - 0.01, tz[1] + ballast_wall]);
                lid_solid(0, ty[0] - 1, -0.2, 1.2);
            }
            // Detent: the lid rides up the ramp and drops behind its rear face.
            translate([mean(tx), ty[0], tz[1]]) rotate([90, 0, 90]) linear_extrude(12, center = true)
                polygon([[0, -0.5], [1.1, -0.5], [1.1, lid_fit[2]], [0, 0]]);
            for (s = [-1, 1, 0], d = [[c[0], c[1]], [-c[1], -c[0]]])
                let(e = foot_xf(s) - (s < 0 ? -1 : 1) * arm_reach(), ys = [foot_yf(s) + d[0], foot_yf(s) + d[1]]) hull() {
                    box(s < 0 ? [e, e + 2] : [e - 2, e], ys, [z0, bridge_top - 4]);
                    translate([foot_xf(s), 0, pivot_b_z]) along_y(ys[0], ys[1], boss_r());
                }
        }
        for (s = [-1, 1, 0]) translate([foot_xf(s), foot_yf(s), pivot_b_z]) {
            along_y(-c[1] - 1, c[1] + 1, m5[0] / 2);
            rotate([0, 0, 90]) nut_pocket(c[1], m5[1], m5[2]);
        }
        box([tx[0] + ballast_wall, tx[1] - ballast_wall], [ty[0] + ballast_wall, ty[1] - ballast_wall],
            [tz[0] + ballast_wall, tz[1] + 1]);
    }
}

// Flat sliding cover over the tray: bevelled side and rear edges, square front edge behind the bump.
module ballast_lid() lid_solid(lid_fit[1], tray_y()[0] + 1.3);

module foot_yoke_at(s, fr)
    translate([foot_xf(s), foot_yf(s), pivot_b_z]) rotate([0, fr, 0]) translate([0, 0, -pivot_b_z])
        rotate([0, 0, s < 0 ? 180 : 0]) foot_yoke();
module tape_foot_at(s, fp, fr)
    translate([foot_xf(s), foot_yf(s), pivot_b_z]) rotate([0, fr, 0]) translate([0, 0, pivot_a_z - pivot_b_z])
        rotate([fp, 0, 0]) translate([0, 0, -pivot_a_z]) rotate([0, 0, s < 0 ? 180 : 0]) tape_foot();
module foot(s, fp, fr) { foot_yoke_at(s, fr); tape_foot_at(s, fp, fr); }
module base(fp = foot_pitch, fr = foot_roll) {
    bridge();
    ballast_lid();
    for (i = [0, 1, 2]) foot([-1, 1, 0][i], fp[i], fr[i]);
}

// ---- Housing: OEM-style surround on the front and sides; the back stays open ----
// One rounded shell, open at the back and bottom, cut by the tablet window (no front overlap
// beyond the lip and hooks, nothing over the top edge between the corner roofs) and by the lift
// slot behind the left roof. Left of the right hooks it is part of the cradle; the right end
// cap is a separate part that comes off for connector access.
function shell_x() = bay_x()[1] + wall + shell_gap + shell_t;   // half width, set by the cover and mirrored
function shell_y() = [bay_y()[0] - wall - shell_gap - shell_t, tablet_t / 2 + end_depth];
function shell_z() = [-tablet_h / 2 - floor_t, tablet_h / 2 + clearance + wall + shell_gap + shell_t];
function cap_snap_at(s) = [tablet_w / 2 + cap_snap[0], 0, s * cap_snap[1]];

// Box with corners of radius R seen from the front and its front and back edges rounded by r.
module rounded_box(x, y, z, R, r) hull()
    for (px = [x[0] + R, x[1] - R], py = [y[0] + r, y[1] - r], pz = [z[0] + R, z[1] - R])
        translate([px, py, pz]) rotate([90, 0, 0]) rotate_extrude() translate([R - r, 0]) circle(r, $fn = 12);

module housing_shell() {
    w = tablet_w;
    h = tablet_h;
    x = shell_x();
    y = shell_y();
    z = shell_z();
    t = shell_t;
    difference() {
        rounded_box([-x, x], y, z, shell_r[0], shell_r[1]);
        // Inside, run out past the back and below the bottom so both stay open.
        rounded_box([-x + t, x - t], [y[0] + t, y[1] + 10], [z[0] - shell_r[0] - 1, z[1] - t], shell_r[0] - t, shell_r[1] - t);
        box([-w / 2 + lip_overlap, hook_x(w)], [y[0] - 1, y[1] + 1], [-h / 2, h / 2 + clearance]);
        box([-w / 2 + roof_len, right_roof_x(w)], [y[0] - 1, y[1] + 1], [-h / 2, z[1] + 1]);
        box([stop_x(w), -w / 2 + roof_len], [tablet_t / 2 + clearance, y[1] + 1], [h / 2, z[1] + 1]);
    }
}

// The end cap's share of the shell, grown by d.
module cap_region(d) {
    y = span(mean(shell_y()), 50);
    box([hook_x(tablet_w) + d, shell_x() + 1], y, span(0, 100));
    box([right_roof_x(tablet_w) + d, shell_x() + 1], y, [tablet_h / 2, 100]);
}

// Left cap and chin, part of the cradle. Fillers tie the shell to the lip, floor, roof and left wall.
module housing_fixed() {
    w = tablet_w;
    h = tablet_h;
    yi = shell_y()[0] + shell_t;
    zi = shell_z()[1] - shell_t;
    zr = h / 2 + clearance + wall;
    difference() { housing_shell(); cap_region(-shell_gap / 2); }
    box([stop_x(w) - wall, -w / 2 + lip_overlap], [yi - 0.1, front_y() - wall + 0.1], [-h / 2 - floor_t, zr]);
    box([stop_x(w) - wall, hook_x(w) - shell_gap / 2], [yi - 0.1, front_y() - wall + 0.1], [-h / 2 - floor_t, -h / 2]);
    box([stop_x(w) - wall, -w / 2 + roof_len], [yi - 0.1, tablet_t / 2 + clearance], [zr - 0.1, zi + 0.1]);
    box([stop_x(w) - wall, stop_x(w)], [yi - 0.1, shell_y()[1]], [zr - 0.1, zi + 0.1]);
}

// Right end cap: hides the hooks, bay, cover, plugs and cable turn. Two bosses seat on the hook
// fronts; a tongue from each passes through its hook and hooks behind it. Press both barbs
// toward the middle from behind to take the cap off.
module end_cap() {
    yi = shell_y()[0] + shell_t;
    yh = front_y() - wall;
    intersection() { housing_shell(); cap_region(shell_gap / 2); }
    for (s = [-1, 1]) translate(cap_snap_at(s)) {
        box(span(0, 4.5), [yi - 0.5, yh], span(0, 4.5));
        snap_tongue(yi - 0.5, bay_y()[1] + mount_t, s);
    }
}

module cradle_core(w = tablet_w, h = tablet_h, full = true) {
    left_end(w, h);
    right_hooks(w, h, full);
    right_roof(w, h);
    back_frame(w, h);
    bottom_rail(w, h);
    if (full) {
        connector_mount(h);
        height_rail(h);
        cable_clip();
    }
}

module cradle_rigid(w = tablet_w, h = tablet_h, full = true) {
    cradle_core(w, h, full);
    if (full) housing_fixed();
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
        box([hook_x(tablet_w) - 2, bay_x()[1] + 1], [-50, 50], [bay_z()[0], tablet_h / 2 + clearance + wall + 1]);
    }
}

module assembly() {
    installed(height_mm, pitch_deg) {
        color("orange") { cradle_core(); detent_bump(tablet_w, tablet_h); }
        color("#2e2e30") { housing_fixed(); end_cap(); }
        color("peru") connector_insert(connector);
        color("sienna") connector_cover();
        color("red") connector_body(connector);
        tablet_pose(slide_mm, release_yaw_deg, lift_mm) color("dimgray") tablet_reference();
    }
    color("slategray") post();
    pitched(pitch_deg) color("lightslategray") carriage();
    color("darkslategray") base();
}

// Candidate bed orientation: turn, then lift the lowest face to Z=0. Agree with the print service.
module on_bed(rot, lift) translate([0, 0, lift]) rotate(rot) children();
front_down = [90, 0, 0];      // -Y face on the bed
right_down = [0, 90, 0];      // +X face on the bed
left_down = [0, -90, 0];      // -X face on the bed

validate();
if (part == "reference") tablet_reference();
else if (part == "assembly") assembly();
// Floor down: rear contacts, insert seat and lug teeth print as walls; the detent tongue
// overhangs its slot, which is open to the bed so its support comes out from below. The
// roofs over the tablet need support.
else if (part == "cradle") on_bed([0, 0, 0], tablet_h / 2 + floor_t) cradle();
else if (part == "motion_sample") on_bed([0, 0, 0], sample_h / 2 + floor_t) cradle(sample_w, sample_h, false);
else if (part == "fit_sample") on_bed([0, 0, 0], -bay_z()[0]) fit_sample();
else if (part == "surrogate") on_bed(front_down, tablet_t / 2) tablet_envelope(sample_w, tablet_t, sample_h);
// Entry side down: pocket, plug hole and outlets print as vertical shafts and slots.
else if (part == "insert") on_bed(right_down, bay_x()[1]) connector_insert(connector);
else if (part == "cover") on_bed(right_down, bay_x()[1] + wall) connector_cover();
// Outer side down: front, top and the cover-side wall print as walls; the rounded edges at the
// bed and the boss tops need light support.
else if (part == "end_cap") on_bed(right_down, shell_x()) end_cap();
// The post alone is a trial piece for the pitch joint; the dock's post prints with the bridge.
else if (part == "post") on_bed([0, 0, 0], -bridge_top) post();
// Upright: slide faces and toothed lug face print as walls; the lug disc below its web needs support.
else if (part == "carriage") on_bed([0, 0, 0], max(carriage_h / 2, lug_r) - pivot_z()) carriage();
// Lug coupon with its toothed face up.
else if (part == "pitch_joint") on_bed(left_down, lug_t / 2) pitch_lug(pivot[0] - sleeve_y()[1] + 1);
// Rail coupon: the cradle's spine, web and rail head over the slot, for the carriage to slide on.
else if (part == "slide_sample") on_bed([0, 0, 0], 90 - rail_z()[1])
    intersection() { cradle_core(); box(span(0, tongue[0] / 2 + 1), [0, 50], [rail_z()[1] - 90, rail_z()[1]]); }
else if (part == "bridge") on_bed([0, 0, 0], bridge[2] - bridge_top) { bridge(); post(); }
else if (part == "ballast_lid") on_bed([0, 0, 0], -tray_z()[1]) ballast_lid();
else if (part == "foot_yoke") on_bed(front_down, boss_r()) foot_yoke();
else if (part == "tape_foot") tape_foot();
