include <parameters.scad>

module validate() {
    assert(tablet_w > 0 && tablet_h > 0 && tablet_t > 0, "positive tablet dimensions required");
    assert(corner_r > 0 && 2*corner_r < min(tablet_w,tablet_h), "invalid corner radius");
    assert(connector == "essager" || connector == "cd0700", "unknown connector");
    assert(len(search([part], ["reference","assembly","cradle","motion_sample","surrogate"])) > 0 && search([part], ["reference","assembly","cradle","motion_sample","surrogate"])[0] != [], "unknown part");
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

module box(x0,x1,y0,y1,z0,z1) {
    translate([x0,y0,z0]) cube([x1-x0,y1-y0,z1-z0]);
}

module cradle() {
    r=tablet_w/2; h=tablet_h/2; front=-tablet_t/2-clearance;
    // Back frame and floor; left pocket is open to the inward yaw sweep.
    box(-r-18,r+5,back_y,back_y+wall,-h-4,-h+6);
    box(-r-18,r+5,back_y,back_y+wall,h-6,h+4);
    for (x=[-0.55*r,0.55*r]) box(x-5,x+5,back_y,back_y+wall,-h-3,h+3);
    box(-r-18,-r+55,front-3,back_y+wall,-h-4,-h-clearance);
    box(r-20,r+5,front-3,back_y+wall,-h-4,-h-clearance);
    box(-r-18,-r-14,front-3,back_y+wall,-h-3,h+4);
    box(r+clearance,r+5,front-3,back_y+wall,-h-3,h+4);
    // Left front lip: outward capture, plus a front-half roof released by inward yaw.
    box(-r-17,-r+4,front-3,front,-h+10,h+4);
    box(-r-17,-r+min(50,r/2),front-3,-0.5,h+clearance,h+4);
    // Right hooks clear only after full leftward translation.
    for (z=[-h+10,h-25]) box(r-release_travel+1,r+5,front-3,front,z,z+15);
    box(r-release_travel+1,r+5,front-3,tablet_t/2+5,h+clearance,h+4);
    // Central contact is on the outward-moving half, not in the left yaw pocket.
    box(0,25,tablet_t/2+clearance,back_y+wall,-10,10);
    box(-0.6*r,0.6*r,back_y,back_y+wall,-10,10);
}

module detent() {
    r=tablet_w/2; h=tablet_h/2;
    // shortcut: this long spring is a force-unqualified prototype; tune on an ABS sample.
    box(-r-2,-r-0.8,-2,2,-h-2,-h+43);
    translate([-r-0.8,0,-h+42]) rotate([90,0,0])
        cylinder(h=4,r=1.05,center=true,$fn=16);
}

module assembly() {
    color("slategray") cradle();
    color("orange") detent();
    reference();
}

validate() {
    if (part == "reference") reference();
    if (part == "assembly") assembly();
    if (part == "cradle") union() { cradle(); detent(); }
    if (part == "motion_sample") let(tablet_w=100,tablet_h=60,corner_r=5) union() { cradle(); detent(); }
    if (part == "surrogate") let(tablet_w=100,tablet_h=60,corner_r=5) tablet_envelope();
}
