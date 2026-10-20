include <../cad/parameters.scad>
use <../cad/dock.scad>
// Spatial fixtures added alongside the mechanism they exercise.
check = "slide_then_yaw_then_lift_clearance";
probe_slide = 0;

// Independent reference transform; does not call production tablet_pose().
module at_pose(s=0,a=0,l=0) {
    translate([-s,0,l]) multmatrix([
        [cos(a),sin(a),0,0],[-sin(a),cos(a),0,0],[0,0,1,0],[0,0,0,1]
    ]) tablet_envelope(collision_eps);
}
module motion() {
    hull() { at_pose(); at_pose(release_travel); }
    for (a=[0:release_angle/24:release_angle]) at_pose(release_travel,a);
    hull() { at_pose(release_travel,release_angle); at_pose(release_travel,release_angle,tablet_h+10); }
}
// Distribute intersections over the sweep to avoid unioning 25 overlapping tablets.
// This conservative box contains every tested tablet pose; clip obstacles first.
module path_region() {
    d=tablet_w/2*sin(release_angle)+tablet_t+1;
    intersection() {
        children();
        translate([-tablet_w/2-release_travel-1,-d,-tablet_h/2-1])
            cube([tablet_w+release_travel+2,2*d,2*tablet_h+12]);
    }
}
module path_hits() {
    intersection() { path_region() children(); hull() { at_pose(); at_pose(release_travel); } }
    for (a=[0:release_angle/24:release_angle]) intersection() { path_region() children(); at_pose(release_travel,a); }
    intersection() { path_region() children(); hull() { at_pose(release_travel,release_angle); at_pose(release_travel,release_angle,tablet_h+10); } }
}
if (check == "slide_then_yaw_then_lift_clearance") path_hits() cradle();
if (check == "connected_yaw_is_blocked") intersection() { cradle(); at_pose(probe_slide,1); }
if (check == "docked_lift_is_blocked") intersection() { cradle(); at_pose(0,0,2); }
if (check == "docked_left_edge_outward_is_blocked") intersection() { cradle(); at_pose(0,-1); }

module connector_hardware() { connector_insert(connector); connector_cover(); connector_mount(); }
if (check == "both_insert_interfaces_match") difference() {
    connector_insert(connector);
    translate([tablet_w/2, -8, -39]) cube([23,22,78]);
}
if (check == "connector_clear_before_yaw") {
    path_hits() connector_hardware();
    for(a=[0:0.5:release_angle]) intersection() {
        at_pose(release_travel,a);
        translate([tablet_w/2-plug_engagement,-1.5,-4.5]) cube([plug_engagement+2,3,9]);
    }
}
if (check == "cable_outlets_open") intersection() {
    connector_hardware();
    for (direction=connector=="cd0700" ? [-1,1] : [-1])
        translate([tablet_w/2+8,0,direction*38]) cube([8,7,24],center=true);
}
if (check == "device_feature_clearances") intersection() {
    union() { cradle(); connector_hardware(); }
    union() {
        translate([camera_x,tablet_t/2,camera_z]) rotate([-90,0,0])
            cylinder(h=70,r1=6,r2=6+70*tan(camera_half_angle),$fn=32);
        for (side=[-1,1],z=[-50,50]) translate([side*tablet_w/2,0,z]) cube([20,6,18],center=true);
        translate([-70,0,tablet_h/2]) cube([35,6,8],center=true);
    }
}

module support_global() {
    mast_outer();
    translate([0,0,tablet_h/2+70+height_mm]) mast_inner();
}
// Independent inverse transform puts the stationary mast in tablet coordinates.
module support_in_tablet() {
    translate([0,65,0]) rotate([pitch_deg,0,0])
        translate([0,-65,-tablet_h/2-70-height_mm]) support_global();
}
if (check == "slide_overlap_at_max_height") {
    assert(130-(tablet_h/2+70+50-100)>=25,"retained overlap less than 25 mm");
    intersection() {
        translate([0,0,tablet_h/2+70+50]) mast_inner();
        translate([-30,40,45]) cube([60,50,85]);
    }
}
if (check == "support_and_cable_clearance_at_extremes") {
    path_hits() { support_in_tablet(); pitch_joint(); cable_clip(); }
    intersection() {
        support_global();
        translate([32,45,65]) cube([24,60,180]);
    }
}
if (check == "pitch_mating_clearance") intersection() {
    mast_inner();
    translate([0,65,0]) rotate([-pitch_deg,0,0]) translate([0,-65,0]) pitch_joint();
}

module fixture_foot(i) {
    a=foot_pitch[i]; b=foot_roll[i];
    translate([i==0 ? -65 : 65,65,33])
        multmatrix([[cos(a),0,sin(a),0],[0,1,0,0],[-sin(a),0,cos(a),0],[0,0,0,1]])
        translate([0,0,-15])
        multmatrix([[1,0,0,0],[0,cos(b),-sin(b),0],[0,sin(b),cos(b),0],[0,0,0,1]])
        translate([0,0,-18]) children();
}
if (check == "two_axis_foot_adjustment") for(i=[0,1]) {
    difference() {
        fixture_foot(i) translate([0,0,0.01]) linear_extrude(height=0.1)
            offset(r=3.5) square([62,42],center=true);
        foot_assembly_pose(i) foot_roll_pose(i) tape_foot();
    }
    intersection() {
        foot_assembly_pose(i) foot_roll_pose(i) tape_foot();
        fixture_foot(i) translate([-50,-40,-80]) cube([100,80,79.99]);
    }
    intersection() {
        foot_assembly_pose(i) foot_roll_pose(i) tape_foot();
        union() { foot_assembly_pose(i) foot_yoke(); bridge(); }
    }
    intersection() { foot_assembly_pose(i) foot_yoke(); bridge(); }
}
if (check == "foot_clamps_have_tool_access") intersection() {
    base_assembly();
    union() {
        for(i=[0,1]) {
            foot_assembly_pose(i) translate([-50,0,18]) rotate([0,90,0]) cylinder(d=6,h=25);
            translate([i==0?-65:65,10,33]) rotate([-90,0,0]) cylinder(d=6,h=30);
        }
    }
}
if (check == "base_clears_removal_envelope") path_hits()
    translate([0,65,0]) rotate([pitch_deg,0,0]) translate([0,-65,-tablet_h/2-70-height_mm]) base_assembly();
if (check == "curved_surface_has_gap") difference() {
    // An edge patch avoids the zero-area tangent line at the centre.
    translate([15,-20,-0.1]) cube([15,40,0.1]);
    translate([0,-40,-250]) rotate([-90,0,0]) cylinder(r=250,h=80,$fn=128);
}
