// Single source for dock dimensions. Units: mm, degrees, grams.
// PROVISIONAL = modelling choice still to be measured or fit-tested; see docs/measurements.md.

// ---- Public controls (override with -D) ----
part = "assembly";      // see `parts` in dock.scad
connector = "essager";  // "essager" or "cd0700"
height_mm = 0;          // locked height travel
pitch_deg = 0;          // locked pitch relative to the nominal installed angle
slide_mm = 0;           // removal step 1: leftward travel, >= 0
release_yaw_deg = 0;    // removal step 2: left edge inward / right edge outward, >= 0
lift_mm = 0;            // removal step 3: upward lift, >= 0

// ---- Samsung Galaxy Tab S7 SM-T875, published nominal ----
tablet_w = 253.8;       // X, landscape width
tablet_t = 6.3;         // Y, thickness
tablet_h = 165.3;       // Z, landscape height
tablet_mass = 500;      // g

// ---- Tablet features (unmeasured) ----
corner_r = 8;           // PROVISIONAL outline corner radius
usb_z = 0;              // PROVISIONAL USB-C centre height from tablet centre, on the right edge
usb_marker = [9, 3.5];  // visual port marker (Z, Y), not a fit dimension

// Removal yaw turns about the rear contact line behind the tablet centre.
yaw_pivot = [0, tablet_t / 2, 0];

$fn = 32;
