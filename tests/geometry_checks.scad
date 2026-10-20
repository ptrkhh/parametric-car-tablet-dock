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
module path_hits() {
    intersection() { children(); hull() { at_pose(); at_pose(release_travel); } }
    for (a=[0:release_angle/24:release_angle]) intersection() { children(); at_pose(release_travel,a); }
    intersection() { children(); hull() { at_pose(release_travel,release_angle); at_pose(release_travel,release_angle,tablet_h+10); } }
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
