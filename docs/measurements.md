# Prototype inputs

All values are mm, degrees or grams. Each value states its source and status. This is geometric prototype input, not fitted manufacturing data. `cad/parameters.scad` is the single source; this file explains where each value comes from.

## Published (manufacturer nominal)

| Input | Value | Source |
|---|---|---|
| SM-T875 width × thickness × height (X, Y, Z) | 253.8 × 6.3 × 165.3 | [Samsung specification](https://www.samsung.com/hk_en/business/tablets/galaxy-tab-s/galaxy-tab-s7-lte-t875-sm-t875nzketgy/) via the design brief |
| SM-T875 mass | 500 g | Same source |

Nominal dimensions are not measured on the user's tablet.

## Measured

None yet. No tablet, connector, dashboard or print-service value has been measured for this model.

## Modelling assumptions (provisional)

| Parameter | Value | Why / what replaces it |
|---|---|---|
| `corner_r` | 8 | Outline corner radius guess; measure the tablet corners |
| `usb_z` | 0 | USB-C assumed at the right edge centre and mid-thickness; measure |
| `usb_marker` | 9 × 3.5 | Visual port marker only, not a fit dimension |
| `yaw_pivot` | [0, 3.15, 0] | Removal yaw turns about the rear contact line behind the tablet centre |

### Cradle retention

| Parameter | Value | Why / what replaces it |
|---|---|---|
| `clearance` | 0.5 | Running clearance at lips, roofs and hooks; motion-sample variants 0.3 / 0.5 / 0.7 |
| `plug_engagement` | 6 | USB-C insertion depth guess; measure with both connectors |
| `release_travel` | 8 | Must exceed `plug_engagement + clearance`; set from the measured engagement, not from the 15 mm protrusion estimate |
| `release_yaw`, `yaw_relief` | 12°, 15° | Mechanism choice; see docs/validation.md |
| `detent_preload`, `detent_rise` | 1, 1.5 | Tune on the motion sample |
| `lip_overlap`, hook overlap | 5, 7.5 | Cover the front bezel; check against the real screen edge |

### Connectors

Both bodies are centred on the port in thickness (Y). Each body face starts `connector_gap` = 2 mm beyond the tablet edge, and the USB-C plug shell (8.4 × 2.6) reaches 6 mm into the port. These seated transforms are guesses: measure the plug shoulder, shell length and seating depth for each connector.

| Parameter | Value | Source / status |
|---|---|---|
| `cd0700_body` | 12.7 (X out from the edge) × 8.9 (Y) × 49.3 (Z, along the edge) | CableCreation dimension image in the design brief (1.94 × 0.50 × 0.35 in); verify on the owned adapter |
| CD0700 sockets | One at each Z end, facing up and down | Design brief |
| `essager_body` | 12.7 × 6.3 × 16, plug centre 4 below its top, cable exits downward | Unmeasured placeholder |
| `downstream_plug` | 12 × 8 × 24, outside the bay | Unmeasured placeholder for the CD0700's charging and audio plugs |
| `essager_relief` | 6 × 6 × 20 below the elbow | Unmeasured placeholder |
| `cable_d` | 5 | Cable diameter allowance |
| `insert_clearance` | 0.5 | Pocket, plug hole, outlets and cover boss; fit variants 0.3 / 0.5 / 0.7 |

The user's ~15 mm protrusion estimate is not used for any dimension.

The insert wall between the tablet edge and the connector body is `connector_gap - clearance - insert_clearance`: 1.0 mm at default (0.8 mm at 0.7). It carries the USB-C extraction load. `validate()` rejects walls under 0.4 mm. Thicken it once the seated transform is measured.

### Device features (placeholders)

None of these positions is measured. They are keep-out references for the geometry checks, not evidence of clearance.

| Parameter | Value |
|---|---|
| `camera` | Rear camera centre X=-110, Z=62 on the back face; view cone half-angle 35° (`camera_half_angle`), 250 mm long |
| `front_camera` | X=0, Z=77 on the front face; same half-angle, 150 mm long |
| `speaker_z`, `speaker_h` | Openings on both side edges at Z=±50, 16 high, 4 mm keep-out outward |
| `control_x` | Keys on the top edge from X=-95 to -45, 10 mm keep-out above |

Microphone openings are not modelled because no position is known.

### Central support

| Parameter | Value | Why / what replaces it |
|---|---|---|
| `tablet_bottom_z` | 70 above the pad plane at zero height and pitch | Modelling start, not a measured W124 height |
| `nominal_pitch` | 0 (vertical screen) | Occupant eye position unmeasured; must stay a multiple of `pitch_step` |
| `height_travel`, `pitch_range`, `pitch_step` | 50, ±15, 5 | Design brief; 5° step is the plan's initial choice |
| `pivot` | 55 behind the tablet centre plane, 10 below the tablet centre | Pitch axis; keeps the cradle bottom 4.8 mm in front of the sleeve at -15° |
| Face teeth | 72 teeth (5°) on r = 18–28, 45° flanks, depth 0.8–1.2, pitch 1.6–2.4 | Near FDM resolution; joint coupon decides; a 10° `pitch_step` is the fallback |
| `teeth_play` | 0.2 axial at an index | About ±0.4–0.6° of rotational play before the flanks meet |
| `tongue`, `slide_gap` | 30 × 18, 0.3 per side | Slide coupon decides the gap |
| `sleeve_wall` | 6 (sides, carry the clamp nut), 4 (front and back) | |
| `min_overlap` | 25 | Retained slide overlap required at full height; the model has 28.65 |
| `bridge_top`, `flange` | 18; 70 × 50 × 5 | Mast seat on the standard bridge (Task 5) |

At zero height the pivot is at Z=142.65. The sleeve runs from Z=18 to 102.65 and the tongue is 118.65 long. `validate()` rejects any configuration whose overlap at full height falls below `min_overlap`, for example `tablet_bottom_z` = 55.

### Standard base

No W124 mounting space or dashboard contact has been measured; every value below is a prototype choice.

| Parameter | Value | Note |
|---|---|---|
| `pad`, `pad_r` | 50 (X) × 70 (Y) × 6, 8 corner radius | Flat tape face about 3,445 mm² per pad, 6,890 mm² total before unbonded regions; not an adhesive capacity |
| `pad_offset` | 10 outboard of the pivots | Lets a pad tilted to both limits pass under the bridge arms |
| `foot_spacing`, `foot_y` | 140 between pivot centres (pad centres 160 apart), feet on Y=45 | Pads cover Y=10–80 |
| `foot_range` | ±15° about X (`foot_pitch`) and about Y (`foot_roll`) per foot | + pitch raises the pad's inward edge; + roll lowers its occupant-right edge |
| `pivot_a_z`, `pivot_b_z` | 19 and 40 above the pad plane | Lower pivot about X, upper about Y |
| `foot_lug`, `foot_gap`, `foot_cheek` | 16, 1, 6 | Each lug sits between cheeks 18 mm apart; the 1 mm gaps take one DIN 125 M5 washer each, eight in total. Measure the washers and shim; do not squeeze the cheeks inward |
| `bridge` | 70 × 54 × 8 plate, top at `bridge_top` = 18 | Carries the mast flange with nuts from below |

### Planning mass and lever arms

Printed masses are solid ABS volumes from the exported STLs at 1.04 g/cm³, an upper bound; real infill weighs less. Hardware is estimated from standard steel fastener sizes. The connector and cable figure is an allowance. Weigh every item before a load test.

| Item | Mass (g) |
|---|---|
| Tablet (nominal) | 500 |
| Cradle | 189 |
| Insert and cover (CD0700) | 17 |
| Connector and cables (allowance) | 40 |
| Mast outer and inner | 160 |
| Bridge | 43 |
| Two yokes and two pads | 74 |
| M5 and M3 bolts, nuts and washers | 83 |
| **Total supported by the tape** | **1,106** |

At height 0 and pitch 0 the combined centre of mass is about X=8.5, Y=19.5, Z=119.6 in the installed frame: 9.5 mm behind the pads' front edge and 120 mm above the tape faces. Each 1 g of fore/aft acceleration gives about 1.3 N·m about the tape plane. Height and pitch move this point; the load test must use the measured masses and the worst setting. These numbers are planning inputs, not a load rating.

### Cable allowance

The keep-outs assume one 5 mm cable (`cable_d`): behind the bay, along the bottom behind the floor, up behind the spine through the clip, a loop beside the pitch joint, and a corridor beside the mast (X=24–46, Y=40–75 in the installed frame) down to the flange. Bend radius, plug-to-cable strain reliefs, loop length and the CD0700's second cable are unmeasured.

### Hardware

| Item | Value | Note |
|---|---|---|
| Insert/cover bolts | 2 × M3 × 25 socket head, ISO 4032 M3 nuts | Stack is 22.1 mm; the bolt ends 2.9 mm behind the rear mount |
| `m3` | 3.4 clearance hole, 5.8 across-flats nut pocket, 2.7 deep | Print allowances for ordinary M3 hardware (nut 5.5 AF × 2.4); verify on a coupon |
| Pitch bolt | M5 × 35 socket head, DIN 934 nut, 1 DIN 125 washer | Head on the -X cheek; nut captive in the +X cheek |
| Height clamp bolt | M5 × 45 socket head, DIN 934 nut, 1 DIN 125 washer | Head on the -X side wall; nut captive in the +X side wall; its tip ends 1.3 mm short of the cable corridor |
| Mast flange bolts | 4 × M5 × 16 socket head, DIN 934 nuts in the bridge underside, 4 washers | The tips end 7 mm above the pad plane; check clearance to a raised dashboard under the bridge |
| Foot pivot bolts | 4 × M5 × 35 socket head, DIN 934 nuts, 4 head washers plus 8 gap washers | Lower bolts: head outboard, nut in the inner cheek. Upper bolts: head at the front, nut in the rear arm |
| `m5` | 5.6 clearance hole, 8.4 across-flats nut pocket, 4.4 deep, head 8.5 × 5 | [ISO 4762 example](https://www.accu.co.uk/metric-cap-head-screws/652691-SSC-M5-50-TI5): 8.5 head, 5 high, 4 mm hex drive. [DIN 934](https://www.performancefastenersltd.co.uk/_files/ugd/aa5dc8_659865f859d941c2905d0a253d751077.pdf): 8 AF × 4. Ordinary steel or stainless hardware |
| `washer5` | 10 OD × 1 | [DIN 125](https://www.westfieldfasteners.co.uk/Datasheets/Washer_FormA_M.pdf) M5: 5.3 ID, 10 OD, 1 thick |

`tablet_envelope()` is the nominal box with rounded outline corners. It has no edge profile, camera island or other protrusion because none is measured. Collision results depend on this envelope.

## Missing inputs

Each item below blocks the dependent fitted export or qualification, not provisional CAD.

- USB-C port centre, depth and plug engagement travel for both connectors.
- Rear camera position, island protrusion and the recording mode's field of view.
- Button, speaker and microphone opening positions and sizes.
- Tablet edge profile and actual corner radius.
- Essager body and strain relief; CD0700 body as owned (manufacturer image gives 49.3 × 12.7 × 8.9 nominal).
- Downstream cable diameters, bend radii and plug bodies.
- Print service usable ABS build volume, filament identity, dimensional capability and achievable clearances.
- Nominal installed screen pitch for the occupants' eye positions.
- Installation envelope above the W124 centre vents: available space, minimum tablet height, driver sightline, airbag and vehicle-function clearance.
