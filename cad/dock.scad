include <parameters.scad>

module validate() {
    assert(tablet_w > 0 && tablet_h > 0 && tablet_t > 0, "positive tablet dimensions required");
    assert(corner_r > 0 && 2*corner_r < min(tablet_w,tablet_h), "invalid corner radius");
    assert(connector == "essager" || connector == "cd0700", "unknown connector");
    assert(len(search([part], ["reference","assembly","cradle","motion_sample","surrogate","insert","cover","fit_sample"])) > 0 && search([part], ["reference","assembly","cradle","motion_sample","surrogate","insert","cover","fit_sample"])[0] != [], "unknown part");
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

module cradle_raw() {
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

module feature_clearances() {
    translate([camera_x,tablet_t/2,camera_z]) rotate([-90,0,0])
        cylinder(h=75,r1=7,r2=7+75*tan(camera_half_angle));
    for (side=[-1,1],z=[-50,50]) translate([side*tablet_w/2,0,z])
        cube([22,7,20],center=true);
    translate([-70,0,tablet_h/2]) cube([37,7,10],center=true);
    translate([tablet_w/2,0,usb_z]) cube([18,12,12],center=true);
}

module cradle() {
    difference() { cradle_raw(); feature_clearances(); }
}

// All connector parts stay fixed to the cradle while the tablet translates.
module screw_y(x,y,z,length,d=m3_clear) {
    translate([x,y,z]) rotate([-90,0,0]) cylinder(d=d,h=length);
}
module connector_fasteners(nuts=false) {
    for(z=[-34,34]) {
        screw_y(tablet_w/2+18,-12,z,30);
        if(nuts) translate([tablet_w/2+18,9.5,z]) rotate([-90,0,0])
            cylinder(d=m3_nut_af/cos(30),h=m3_nut_depth+1,$fn=6);
    }
}
module connector_mount() {
    difference() {
        box(tablet_w/2+0.5,tablet_w/2+22,7.5,12,-39,39);
        connector_fasteners(true);
    }
}
module connector_insert(kind) {
    r=tablet_w/2; b=kind=="cd0700" ? cd0700_body : essager_body;
    union() {
    difference() {
        box(r+0.8,r+20,-6.8,7,-38,38);
        // Open front allows the fitted body and attached cables to drop in.
        box(r+2-insert_clearance,r+2+b[0]+insert_clearance,-10,b[1]/2+insert_clearance,
            -b[2]/2-insert_clearance,b[2]/2+insert_clearance);
        box(r-1,r+3,-2,2,usb_z-5,usb_z+5);
        for(direction=kind=="cd0700" ? [-1,1] : [-1])
            translate([r+8,-1,direction*(b[2]/2+20)]) cube([10,16,40],center=true);
        connector_fasteners();
    }
    // Front retaining lips; fit by tilting the body under them before closing the cover.
    for (z=[-5,5]) box(r+2+b[0]-1.5,r+20,-b[1]/2-insert_clearance-1,
        -b[1]/2-insert_clearance,z-1.5,z+1.5);
    }
}
module connector_cover() {
    r=tablet_w/2;
    difference() {
        union() {
            box(r+0.6,r+22,-9,-7,-38,38);
            box(r+20.5,r+22,-9,12,-38,38);
        }
        connector_fasteners();
    }
}

module detent() {
    r=tablet_w/2; h=tablet_h/2;
    // shortcut: this long spring is a force-unqualified prototype; tune on an ABS sample.
    box(-r-2,-r-0.8,-2,2,-h-2,-h+43);
    translate([-r-0.8,0,-h+42]) rotate([90,0,0])
        cylinder(h=4,r=1.05,center=true,$fn=16);
}

module assembly() {
    color("slategray") { cradle(); connector_mount(); }
    color("darkslategray") connector_insert(connector);
    color("slategray") connector_cover();
    color("orange") detent();
    reference();
}

validate() {
    if (part == "reference") reference();
    if (part == "assembly") assembly();
    if (part == "cradle") union() { cradle(); detent(); connector_mount(); }
    if (part == "insert" || part == "fit_sample") connector_insert(connector);
    if (part == "cover") connector_cover();
    if (part == "motion_sample") let(tablet_w=100,tablet_h=60,corner_r=5) union() { cradle(); detent(); }
    if (part == "surrogate") let(tablet_w=100,tablet_h=60,corner_r=5) tablet_envelope();
}
