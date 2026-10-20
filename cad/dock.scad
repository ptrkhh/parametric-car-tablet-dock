include <parameters.scad>

module validate() {
    assert(tablet_w > 0 && tablet_h > 0 && tablet_t > 0, "positive tablet dimensions required");
    assert(corner_r > 0 && 2*corner_r < min(tablet_w,tablet_h), "invalid corner radius");
    assert(connector == "essager" || connector == "cd0700", "unknown connector");
    assert(part == "reference" || part == "assembly", "unknown part");
    children();
}

module tablet_envelope(inset=0) {
    rotate([90,0,0]) linear_extrude(height=tablet_t-2*inset,center=true)
        offset(r=corner_r-inset)
            square([tablet_w-2*corner_r,tablet_h-2*corner_r],center=true);
}

module tablet_pose(slide_mm, release_yaw_deg, lift_mm) {
    translate([-slide_mm,0,lift_mm]) rotate([0,0,-release_yaw_deg]) children();
}

module reference() {
    color("dimgray") tablet_pose(slide_mm,release_yaw_deg,lift_mm) tablet_envelope();
    // Right-side port marker is visual only, not a retention feature.
    color("teal") translate([tablet_w/2,0,0]) cube([2,3,8],center=true);
}

module assembly() { reference(); }

validate() {
    if (part == "reference") reference();
    if (part == "assembly") assembly();
}
