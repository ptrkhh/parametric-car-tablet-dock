include <parameters.scad>

module validate() {
    assert(tablet_w > 0 && tablet_h > 0 && tablet_t > 0, "positive tablet dimensions required");
    assert(corner_r > 0 && 2*corner_r < min(tablet_w,tablet_h), "invalid corner radius");
    assert(connector == "essager" || connector == "cd0700", "unknown connector");
    parts=["reference","assembly","cradle","motion_sample","surrogate","insert","cover","fit_sample","mast_outer","mast_inner","pitch_joint","slide_sample","joint_rotor","bridge","foot_yoke","tape_foot"];
    assert(search([part],parts)[0] != [], "unknown part");
    assert(height_mm >= 0 && height_mm <= height_travel && abs(pitch_deg) <= pitch_limit, "adjustment out of range");
    assert(abs(pitch_deg/pitch_step-round(pitch_deg/pitch_step))<0.001,"pitch adjustment uses 5-degree indexes");
    assert(len(foot_pitch)==2 && len(foot_roll)==2,"two foot angle settings required");
    for(a=concat(foot_pitch,foot_roll)) assert(abs(a)<=foot_angle_limit,"foot angle out of range");
    assert(release_travel > plug_engagement + clearance,"release travel must exceed plug engagement");
    assert(clearance>=0 && insert_clearance>=0 && slide_gap>=0,"negative fit clearance");
    assert(camera_half_angle>0 && camera_half_angle<90,"invalid camera view angle");
    assert(base_z+mast_outer_h-(tablet_h/2+bottom_height+height_travel-inner_length)>=25,"insufficient mast overlap");
    assert(slide_mm>=0 && release_yaw_deg>=0 && lift_mm>=0,"negative removal control");
    children();
}

module tablet_envelope(inset=0,width=tablet_w,height=tablet_h,radius=corner_r) {
    rotate([90,0,0]) linear_extrude(height=tablet_t-2*inset,center=true)
        offset(r=radius-inset)
            square([width-2*radius,height-2*radius],center=true);
}

module tablet_pose(slide_mm, release_yaw_deg, lift_mm) {
    translate([-slide_mm,0,lift_mm]) rotate([0,0,-release_yaw_deg]) children();
}

module reference() {
    tablet_pose(slide_mm,release_yaw_deg,lift_mm) {
        color("dimgray") tablet_envelope();
        // Right-side port marker is visual only, not a retention feature.
        color("teal") translate([tablet_w/2,0,usb_z]) cube([2,3,8],center=true);
    }
}

module box(x0,x1,y0,y1,z0,z1) {
    translate([x0,y0,z0]) cube([x1-x0,y1-y0,z1-z0]);
}

module cradle_raw(width=tablet_w,height=tablet_h) {
    r=width/2; h=height/2; front=-tablet_t/2-clearance;
    // Back frame and floor; left pocket is open to the inward yaw sweep.
    // Bottom rail stops at the posts: negative pitch swings it back past the mast.
    for (x=[[-r-18,-0.55*r+5],[0.55*r-5,r+5]]) box(x[0],x[1],back_y,back_y+wall,-h-4,-h+6);
    box(-r-18,r+5,back_y,back_y+wall,h-6,h+4);
    for (x=[-0.55*r,0.55*r]) box(x-5,x+5,back_y,back_y+wall,-h-3,h+3);
    box(-r-18,-r+55,front-3,back_y+wall,-h-4,-h-clearance);
    box(r-20,r+5,front-3,back_y+wall,-h-4,-h-clearance);
    box(-r-18,-r-14,front-3,back_y+wall,-h-3,h+4);
    box(r+clearance,r+5,front-3,back_y+wall,-h-3,h+4);
    // Left front lip: outward capture, plus a front-half roof released by inward yaw.
    box(-r-17,-r+4,front-3,front,-h+10,h+4);
    box(-r-17,-r+min(50,r/2),front-3,-0.5,h+clearance,h+4);
    // Right hooks clear only beyond release_travel-clearance, which validate() keeps above plug_engagement.
    for (z=[-h+10,h-25]) box(r-release_travel+clearance,r+5,front-3,front,z,z+15);
    box(r-release_travel+clearance,r+5,front-3,tablet_t/2+5,h+clearance,h+4);
    // Central contact is on the outward-moving half, not in the left yaw pocket.
    box(0,25,tablet_t/2+clearance,back_y+wall,-10,10);
    box(-0.6*r,0.6*r,back_y,back_y+wall,-10,10);
}

module feature_clearances(width=tablet_w,height=tablet_h) {
    translate([camera_x,tablet_t/2,camera_z]) rotate([-90,0,0])
        cylinder(h=75,r1=7,r2=7+75*tan(camera_half_angle));
    for (side=[-1,1],z=[-50,50]) translate([side*width/2,0,z])
        cube([22,7,20],center=true);
    translate([-70,0,height/2]) cube([37,7,10],center=true);
    translate([width/2,0,usb_z]) cube([18,12,12],center=true);
    // Relief includes the seated insert and downstream plugs, not just the USB tip.
    box(width/2-0.1,width/2+24,-10,7+collision_eps,
        usb_z-connector_window_half_h,usb_z+connector_window_half_h);
}

module cradle(width=tablet_w,height=tablet_h,device_features=true,radius=corner_r) {
    difference() {
        cradle_raw(width,height);
        if(device_features) feature_clearances(width,height);
        box(-width/2-14,detent_apex(width,height,radius)[0]+4,-4,4,-height/2-5,-height/2); // detent tongue slot
    }
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
    translate([0,0,usb_z]) difference() {
        box(tablet_w/2+0.5,tablet_w/2+22,7,12,-39,39);
        connector_fasteners(true);
    }
}
module connector_insert(kind) {
    r=tablet_w/2; b=kind=="cd0700" ? cd0700_body : essager_body;
    translate([0,0,usb_z]) union() {
    difference() {
        box(r+0.8,r+20,-7,7,-38,38);
        // Open front allows the fitted body and attached cables to drop in.
        box(r+2-insert_clearance,r+2+b[0]+insert_clearance,-10,b[1]/2+insert_clearance,
            -b[2]/2-insert_clearance,b[2]/2+insert_clearance);
        box(r-1,r+3,-2,2,-5,5);
        for(direction=kind=="cd0700" ? [-1,1] : [-1])
            translate([r+8,-1,direction*(b[2]/2+20)]) cube([outlet_width,16,40],center=true);
        connector_fasteners();
    }
    // Front retaining lips; fit by tilting the body under them before closing the cover.
    for (z=[-5,5]) box(r+2+b[0]-1.5,r+20,-b[1]/2-insert_clearance-1,
        -b[1]/2-insert_clearance,z-1.5,z+1.5);
    }
}
module connector_cover() {
    r=tablet_w/2;
    translate([0,0,usb_z]) difference() {
        union() {
            box(r+0.6,r+22,-9,-7,-38,38);
            box(r+20.5,r+22,-9,7,-38,38);
        }
        connector_fasteners();
    }
}

// Floor tongue rooted in the left wall carries a 45-degree cone. Its apex preloads the docked
// lower-left corner up and right; 45-degree faces turn slide, yaw and install contacts downward.
// Keep them sloped: a vertical-sided bump would jam the install sweep sideways.
function detent_apex(width,height,radius) =
    [-width/2+radius-sqrt(pow(radius-detent_preload,2)-pow(radius-detent_rise,2)),-height/2+detent_rise];
module detent(width=tablet_w,height=tablet_h,radius=corner_r) {
    a=detent_apex(width,height,radius); h=height/2; c=a[1]+h+clearance;
    d=[-width/2+radius-a[0],radius-detent_rise];
    assert(detent_preload>0 && detent_preload<detent_rise,"detent apex must touch the corner arc");
    assert(detent_preload>clearance*(d[0]+d[1])/norm(d),"detent must preload the tablet against the cradle stops");
    // shortcut: force-unqualified spring; tune detent_preload and detent_rise on the ABS motion sample.
    box(-width/2-15,a[0]+3,-3,3,-h-2.5,-h-clearance);
    translate([a[0],0,-h-clearance]) cylinder(h=c,r1=c,r2=0,$fn=24);
}

module screw_x(x,y,z,length,d=m5_clear) {
    translate([x,y,z]) rotate([0,90,0]) cylinder(d=d,h=length);
}
module nut_x(x,y,z) {
    translate([x,y,z]) rotate([0,90,0]) cylinder(d=m5_nut_af/cos(30),h=m5_nut_depth+1,$fn=6);
}
module mast_bolts() {
    for(x=[-25,25],y=[hinge_y-10,hinge_y+10])
        translate([x,y,base_z-15]) cylinder(d=m5_clear,h=25);
}
module mast_outer() {
    difference() {
        union() {
            box(-19,19,hinge_y-17,hinge_y+17,base_z,base_z+mast_outer_h);
            box(-30,30,hinge_y-22,hinge_y+22,base_z,base_z+6);
            for(side=[-1,1]) hull() {
                translate([side*20,hinge_y,base_z+7]) cube([10,10,2],center=true);
                translate([side*18,hinge_y,base_z+40]) cube([2,10,2],center=true);
            }
            box(-24,24,hinge_y-8,hinge_y+8,base_z+67,base_z+83);
        }
        box(-13-slide_gap,13+slide_gap,hinge_y-11-slide_gap,hinge_y+11+slide_gap,base_z-1,base_z+mast_outer_h+1);
        box(-1,1,hinge_y-18,hinge_y-10,base_z+15,base_z+mast_outer_h+1);
        screw_x(-30,hinge_y,base_z+75,60);
        nut_x(19.5,hinge_y,base_z+75);
        mast_bolts();
    }
}
module radial_teeth(x,phase) {
    // shortcut: fine 5-degree teeth need service resolution and load testing.
    w=pitch_step/2-tooth_gap;
    translate([x,hinge_y,0]) rotate([0,90,0]) linear_extrude(height=1.2)
        for(a=[phase:pitch_step:359]) polygon([
            [12*cos(a),12*sin(a)],[20*cos(a),20*sin(a)],
            [20*cos(a+w),20*sin(a+w)],[12*cos(a+w),12*sin(a+w)]]);
}
module mast_inner() {
    slot_top=base_z+75-(tablet_h/2+bottom_height);
    difference() {
        union() {
            box(-13,13,hinge_y-11,hinge_y+11,-inner_length,-16);
            screw_x(-13,hinge_y,0,26,40);
            radial_teeth(13,0); radial_teeth(-14.2,0);
        }
        box(-7,7,hinge_y-5,hinge_y+5,-inner_length-1,-25);
        hull() { screw_x(-16,hinge_y,slot_top,32); screw_x(-16,hinge_y,slot_top-height_travel,32); }
        screw_x(-20,hinge_y,0,40);
    }
}
module pitch_joint() {
    difference() {
        union() {
            for(side=[-1,1]) {
                x=side==1 ? 14.5 : -22;
                screw_x(x,hinge_y,0,7.5,44);
                box(x,x+7.5,back_y,hinge_y,-9,9);
            }
            box(-22,22,back_y,back_y+4,-9,9);
            radial_teeth(13.5,pitch_step/2); radial_teeth(-14.7,pitch_step/2);
        }
        screw_x(-28,hinge_y,0,56);
        nut_x(17.5,hinge_y,0);
    }
}
module installed_pose() {
    translate([0,hinge_y,tablet_h/2+bottom_height+height_mm])
        rotate([-pitch_deg,0,0]) translate([0,-hinge_y,0]) children();
}
module cable_clip() {
    // Open slot: route already-connected cables behind the cradle.
    difference() {
        union() {
            box(36,50,back_y,back_y+15,-38,-30);
            box(38,48,back_y,back_y+4,-38,0);
        }
        translate([43,back_y+9,-40]) cylinder(d=cable_d+1,h=12);
        box(40,46,back_y+9,back_y+16,-40,-28);
    }
}
module dock_head() {
    color("slategray") { cradle(); connector_mount(); pitch_joint(); cable_clip(); }
    color("darkslategray") connector_insert(connector);
    color("slategray") connector_cover();
    color("orange") detent();
    reference();
}

module tape_foot() {
    difference() {
        union() {
            linear_extrude(height=foot_t) offset(r=4) square([foot_w-8,foot_d-8],center=true);
            box(-8,8,-6,6,foot_t,18);
            screw_x(-8,0,18,16,16);
        }
        screw_x(-10,0,18,20);
    }
}
module foot_yoke() {
    difference() {
        union() {
            for(x=[-18,9]) screw_x(x,0,18,9,20);
            box(-18,18,-5,5,26.5,29);
            intersection() { screw_y(0,-8,33,16,18); box(-10,10,-9,9,26.5,43); }
        }
        screw_x(-22,0,18,44);
        nut_x(13.5,0,18);
        screw_y(0,-12,33,24,m5_clear);
    }
}
module bridge() {
    difference() {
        union() {
            box(-foot_spacing/2-12,foot_spacing/2+12,hinge_y-18,hinge_y+18,39,base_z);
            for(x=[-25,25],y=[hinge_y-10,hinge_y+10])
                translate([x,y,34]) cylinder(d=14,h=base_z-34);
            // Side ribs resist bending between the two feet.
            for(y=[hinge_y-18,hinge_y+14]) box(-foot_spacing/2,foot_spacing/2,y,y+4,35,base_z);
            for(x=[-foot_spacing/2,foot_spacing/2],y=[hinge_y-18,hinge_y+9])
                screw_y(x,y,33,9,20);
        }
        mast_bolts();
        for(x=[-25,25],y=[hinge_y-10,hinge_y+10])
            translate([x,y,33.5]) cylinder(d=m5_nut_af/cos(30),h=m5_nut_depth+0.5,$fn=6);
        for(x=[-foot_spacing/2,foot_spacing/2]) {
            screw_y(x,hinge_y-8.5,33,17,19);
            screw_y(x,hinge_y-23,33,46,m5_clear);
            translate([x,hinge_y+13.5,33]) rotate([-90,0,0])
                cylinder(d=m5_nut_af/cos(30),h=m5_nut_depth+1,$fn=6);
        }
    }
}
module foot_assembly_pose(i) {
    translate([(i==0?-1:1)*foot_spacing/2,hinge_y,33]) rotate([0,foot_roll[i],0])
        translate([0,0,-33]) children();
}
module foot_pitch_pose(i) {
    translate([0,0,18]) rotate([foot_pitch[i],0,0]) translate([0,0,-18]) children();
}
module base_assembly() {
    bridge();
    for(i=[0,1]) foot_assembly_pose(i) {
        foot_yoke(); foot_pitch_pose(i) tape_foot();
    }
}

module assembly() {
    color("slategray") base_assembly();
    installed_pose() dock_head();
    color("slategray") mast_outer();
    color("dimgray") translate([0,0,tablet_h/2+bottom_height+height_mm]) mast_inner();
}

// Candidate bed orientations only; the service still selects supports and layer loading.
validate() {
    if (part == "reference") reference();
    if (part == "assembly") assembly();
    if (part == "cradle") translate([0,0,hinge_y+22]) rotate([-90,0,0])
        union() { cradle(); detent(); connector_mount(); pitch_joint(); cable_clip(); }
    if (part == "insert" || part == "fit_sample") translate([-tablet_w/2-11,0,7]) rotate([-90,0,0]) connector_insert(connector);
    if (part == "cover") translate([-tablet_w/2-11,0,9]) rotate([90,0,0]) connector_cover();
    if (part == "bridge") translate([0,hinge_y,base_z]) rotate([180,0,0]) bridge();
    if (part == "foot_yoke") translate([0,0,18]) rotate([0,90,0]) foot_yoke();
    if (part == "tape_foot") tape_foot();
    if (part == "mast_outer") translate([0,-hinge_y,-base_z]) mast_outer();
    if (part == "mast_inner") translate([0,-hinge_y,14.2]) rotate([0,90,0]) mast_inner();
    if (part == "pitch_joint") translate([0,-hinge_y,22]) rotate([0,90,0]) pitch_joint();
    if (part == "slide_sample") translate([0,-hinge_y,-base_z-45])
        intersection() { mast_outer(); box(-35,35,35,95,base_z+45,base_z+mast_outer_h); }
    if (part == "joint_rotor") translate([0,-hinge_y,14.2]) rotate([0,90,0])
        intersection() { mast_inner(); box(-25,25,40,90,-22,22); }
    if (part == "motion_sample") translate([0,0,back_y+wall]) rotate([-90,0,0])
        union() { cradle(100,60,false); detent(100,60); }
    if (part == "surrogate") translate([0,0,tablet_t/2]) rotate([90,0,0]) tablet_envelope(0,100,60);
}
