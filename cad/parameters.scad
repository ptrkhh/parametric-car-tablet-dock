// Published bare-device dimensions. Remaining defaults are PROVISIONAL (docs/measurements.md).
tablet_w = 253.8;
tablet_h = 165.3;
tablet_t = 6.3;
tablet_mass_g = 500;
corner_r = 8;
part = "assembly";
connector = "essager";
height_mm = 0;
pitch_deg = 0;
slide_mm = 0;
release_yaw_deg = 0;
lift_mm = 0;
release_travel = 8;
release_angle = 12;
clearance = 0.5;
collision_eps = 0.01;
$fn = 32;
// Provisional mechanism geometry; rigid body support excludes the flexible detent.
back_y = 36;
wall = 4;
plug_engagement = 6;
detent_preload = 1; // cone apex interference with the docked corner arc
detent_rise = 1.5; // apex height above the tablet bottom = tongue deflection while sliding
// Unmeasured feature locations and connector seated transforms: fit samples only.
camera_x = -110;
camera_z = 62;
camera_half_angle = 35;
usb_z = 0;
essager_body = [12.7,6.3,16]; // protrusion, thickness, length along tablet edge
cd0700_body = [12.7,8.9,49.3];
insert_clearance = 0.5;
m3_clear = 3.4;
m3_nut_af = 5.8; // nominal 5.5 AF plus print allowance
m3_nut_depth = 2.7;
// Provisional installed layout; dashboard/occupant measurements still required.
height_travel = 50;
pitch_limit = 15;
pitch_step = 5;
tooth_gap = 0.3; // degrees between mating tooth flanks; tune on the joint coupon
hinge_y = 65;
base_z = 45;
bottom_height = 70;
mast_outer_h = 85;
inner_length = 100;
slide_gap = 0.3;
m5_clear = 5.6;
m5_nut_af = 8.4; // DIN 934 nominal 8 mm plus print allowance
m5_nut_depth = 4.4;
m5_head_d = 8.5;
m5_head_h = 5;
cable_d = 5; // assumed cable diameter; actual plug/strain relief may be larger
// Identical standard feet; these settings change their installation angles only.
// [left,right] degrees: pitch about X (fore/aft slope), roll about Y (side-to-side slope).
foot_pitch = [0,0];
foot_roll = [0,0];
foot_angle_limit = 15;
foot_spacing = 130;
foot_w = 70;
foot_d = 50;
foot_t = 6;
// Provisional downstream plug envelope; measure both real cable ends.
outlet_width = 13; // 12 mm plug witness plus 1 mm total clearance
connector_window_half_h = 60;
