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
| `tablet_bottom_z` | -29: the tablet bottom 29 mm below the tape faces at zero height and pitch | Set so the screen-up extreme still reaches `pad_drop` below the tape. The lower limit is vent airflow, unmeasured: measure the W124 centre vents' top edge relative to the tape plane and the tablet's distance in front of them |
| `pad_drop` | 5 | Required depth of the tablet's lowest point below the tape faces at zero height, at every pitch index |
| `nominal_pitch` | 0 (vertical screen) | Occupant eye position unmeasured; must stay a multiple of `pitch_step` |
| `height_travel`, `pitch_range`, `pitch_step` | 50, ±15, 5 | Design brief; 5° step is the plan's initial choice. Height travels along the cradle's own vertical, which tilts with pitch |
| `pivot` | 76 behind the tablet centre plane, 9 above the tablet centre at zero height | Fixed pitch axis on the post. 76 keeps the fork cheeks 1.75 mm behind the carriage sleeve; 9 gives the post a 1.65 mm block between flange and fork |
| Face teeth | 72 teeth (5°) on r = 18–28, 45° flanks, depth 0.8–1.2, pitch 1.6–2.4 | Near FDM resolution; joint coupon decides; a 10° `pitch_step` is the fallback |
| `teeth_play` | 0.2 axial at an index | About ±0.4–0.6° of rotational play before the flanks meet |
| `tongue`, `rail_web` | Rail head 21 × 18 on a 10 mm web from the spine | The carriage's front lips run between the head and the spine. 21 mm makes the sleeve 33.6 mm wide, inside the reach of the M5 × 35 clamp bolt (34.4 mm); `validate()` rejects a wider joint |
| `slide_gap`, `sleeve_wall` | 0.3 per side; 6 (sides, carry the clamp nut), 4 (front lips and back wall) | Slide coupon decides the gap |
| `carriage_h`, `min_overlap` | 60, 25 | The rail head (Z -73 to 41 in the cradle frame) keeps the whole 60 mm sleeve engaged from zero to full height |
| `bridge_top`, `flange`, `flange_front` | 18; 70 × 50 × 5; front edge 14 ahead of the pivot | The post stands on the bridge plate and prints as one piece with it; the flange starts behind the cradle's path at -15° |

At zero height and pitch the tablet spans Z -29 to 136.3 and the pivot is at Z 62.65, so the fork top (Z 94.65) stays 41.65 mm below the tablet's top edge at every height. The tablet's lowest point at zero height is -46.4 at -15°, -29 at 0° and -7.0 at +15°: the pivot sits 76 mm behind the screen, so pitch also moves the bottom edge up and down. `validate()` rejects a pivot too low for the post, for example `tablet_bottom_z` = -40.

### Standard base

No W124 mounting space or dashboard contact has been measured; every value below is a prototype choice.

| Parameter | Value | Note |
|---|---|---|
| `pad`, `pad_r` | 50 (X) × 70 (Y) × 6, 8 corner radius | Flat tape face about 3,445 mm² per pad, 10,335 mm² over three pads before unbonded regions; not an adhesive capacity |
| `pad_offset` | 10 outboard of the pivots | Lets a pad tilted to both limits pass under the bridge arms |
| `foot_spacing`, `foot_y` | 140 between pivot centres (pad centres 160 apart), feet on Y=108 | Pads cover Y=73–143, behind the cradle's path below the tape plane |
| `nose_gap` | 10 | Dashboard-nose allowance: below the tape plane nothing comes within 10 mm of the pads' front edge (Y ≥ 63) at any height, pitch or removal pose. Assumes a level dashboard ahead of the pads |
| `foot_range` | ±15° about X (`foot_pitch`) and about Y (`foot_roll`) per foot | + pitch raises the pad's inward edge; + roll lowers its occupant-right edge |
| `pivot_a_z`, `pivot_b_z` | 19 and 40 above the pad plane | Lower pivot about X, upper about Y |
| `foot_lug`, `foot_gap`, `foot_cheek` | 16, 1, 6 | Each lug sits between cheeks 18 mm apart; the 1 mm gaps take one DIN 125 M5 washer each, twelve in total. Measure the washers and shim; do not squeeze the cheeks inward |
| `bridge` | 70 × 63 × 8 plate from Y=62 to 125, top at `bridge_top` = 18 | Carries the post (one print) and reaches back to the foot arms |
| `rear_reach` | 150 (at least 87.5) | Rear foot and tray centre behind the front feet, at Y=258. The base covers Y=73–300.5, about 230 mm of dashboard top; the dashboard's depth is unmeasured. Kept short because weights cost less than printed length: each 50 mm of tail is about 23 g of solid plastic. A longer tail needs fewer weights and puts less total mass on the tape |
| `tail_w` | 20 | Tail beam on the centre line from the plate to the tray, as tall as the tray (Z=10–32.5). The rear foot is a right foot on the tail's +X side at X=45 (pad X=30–80); the tray is on the -X side (X=-95 to 10) |
| `ballast`, `ballast_wall` | 100 × 80 × 20 inside, 2.5 walls, floor and lid | 160 cm³: roughly 750 g of 5 g steel wheel-weight segments (assumed 19 × 13 × 4 mm, 5 × 6 × 5 of them), or about 1.2 kg of solid steel. Tray and lid are about 63 g of solid plastic; no printed part is meant to act as weight. The tray and tail sit 10 mm above the pad plane |
| `lid_fit` | 1.2 lip foot, 0.3 clearance, 0.6 bump | The lid slides in from the front under lips on the tray's two sides and rear (leaning in about 28°) and clicks behind a 12 mm wide bump on the front rim. The lid can rattle about 0.6 mm up and down unless the weights are packed against it |

### Housing

| Parameter | Value | Note |
|---|---|---|
| `shell_t`, `shell_gap` | 2.5 wall, 0.5 from the parts it hides | The front face sits 13.05 mm in front of the tablet centre plane (9.9 mm proud of the screen), set by the cover flange it covers |
| `shell_r` | 14 corner radius seen from the front, 4 mm edge round | The right hooks lose 9 mm 45° corners (`hook_chamfer`) to fit inside the rounded corners |
| Extent | 311.8 wide (±155.9, symmetric about the tablet), Z -88.65 to 89.15, front face to 33.15 behind the tablet centre plane | Open at the back and underneath |
| `cap_snap` | 15 beyond the tablet's right edge, Z ±74 | Two tongues from the end cap's bosses pass through windows in the right hooks and hook behind them |

### Planning mass and lever arms

Printed masses are solid ABS volumes from the exported STLs at 1.04 g/cm³, an upper bound; real infill weighs less. Hardware is estimated from standard steel fastener sizes. The connector and cable figure is an allowance. Weigh every item before a load test.

| Item | Mass (g) |
|---|---|
| Tablet (nominal) | 500 |
| Cradle, with the housing's left cap and chin | 250 |
| End cap | 39 |
| Insert and cover (CD0700) | 17 |
| Connector and cables (allowance) | 40 |
| Carriage | 67 |
| Bridge with post, tail and tray | 222 |
| Tray lid | 21 |
| Three yokes and three pads | 112 |
| Eight M5 × 35 bolts with nuts and washers | 82 |
| **Total without weights** | **1,350** |
| Weights that cancel the rear foot's pull (default tail, tablet docked) | 494 |
| **Total supported by the tape** | **1,844** |

At height 0 and pitch 0, without weights, the combined centre of mass is about X=6, Y=53, Z=43 in the installed frame: 55 mm toward the occupants from the front feet's pivot line (Y=108) and 20 mm ahead of the front pads' front edge (Y=73). The dock therefore tips forward about the front feet and the rear foot's tape is pulled upward, even at rest. Treating the three feet as point supports:

| `rear_reach` | Pull on the rear foot, tablet docked | Tablet removed | Weights that cancel the docked pull |
|---|---|---|---|
| 100 | 8.1 N (2.3 kPa over the pad) | 2.8 N | 826 g |
| 150 (default) | 4.9 N (1.4 kPa) | 1.3 N | 494 g |
| 200 | 3.2 N (0.9 kPa) | 0.5 N | 322 g |

The tray's centre is level with the rear foot in Y, so weights there act at the full `rear_reach`. With 494 g at the default tail the rear foot carries no static load with the tablet docked and 3.5 N of compression with it removed; the front feet carry 9.9 N and 8.2 N docked. The combined centre of mass is then on the front feet's line, 37 mm above the tape faces. Height and pitch move it: full height at -15° needs about 40 g more, full height at +15° about 70 g less. These masses are solid volumes; the bridge's tail and tray (about 95 g solid) sit behind the front feet, so lighter infill there needs a little more weight, and lighter infill in the cradle a little less. Each 1 g of fore/aft acceleration adds about 0.68 N·m about the tape plane, which the 150 mm base reacts as about 4.5 N more or less on the rear foot. Sustained pull is the critical adhesive case, so the weights are set by the balance check in the README, not from this table; test the bond hot with and without the tablet. These numbers are planning inputs, not a load rating.

### Print service

`build_volume` is `[0, 0, 0]`: the service has not supplied its usable ABS volume, so `test_declared_build_volume` is skipped and part fit is unverified. The cradle needs about 306 × 51 mm of bed and 178 mm of height in its candidate floor-down orientation, the bridge with its post and tail about 173 × 257 mm and 85 mm of height, and the end cap about 178 × 46 mm; every other part fits a 115 × 95 mm footprint. Enter the volume once known and rerun the suite; split the cradle only if it then fails.

### Cable allowance

The keep-outs assume one 5 mm cable (`cable_d`): behind the bay, along the bottom behind the floor, backward through the clip beside the carriage (cradle frame), and a corridor beside the post (X=24–46, Y=66–96 in the installed frame) down to the flange. The loop between the clip and the corridor hangs free and is not modelled; their distance varies from about 28 to 65 mm over the height and pitch range. Bend radius, plug-to-cable strain reliefs, loop length and the CD0700's second cable are unmeasured.

### Hardware

| Item | Value | Note |
|---|---|---|
| Bolts | 8 × M5 × 35 socket head (ISO 4762), 8 DIN 934 nuts, 20 DIN 125 washers | The only purchased screws (`m5_len`). One washer under each head, twelve in the foot-pivot gaps. Under its washer the tip reaches 34 mm; `validate()` rejects any clamped joint wider than 34.4 mm, where the tip would stop short of the 4 mm nut on its pocket floor |
| Pitch bolt | 1 | Fork 30.4 mm wide; head on the -X cheek; nut captive in the +X cheek |
| Height clamp bolt | 1 | Through the carriage side walls (33.6 mm) and the rail head's slot at the pivot height; head on -X, nut captive on +X |
| Foot pivot bolts | 6, with 12 gap washers | Joints 30 mm wide. Lower bolts: head outboard, nut in the inner cheek. Upper bolts: head at the front, nut in the rear arm |
| `m5` | 5.6 clearance hole, 8.4 across-flats nut pocket, 4.4 deep, head 8.5 × 5 | [ISO 4762 example](https://www.accu.co.uk/metric-cap-head-screws/652691-SSC-M5-50-TI5): 8.5 head, 5 high, 4 mm hex drive. [DIN 934](https://www.performancefastenersltd.co.uk/_files/ugd/aa5dc8_659865f859d941c2905d0a253d751077.pdf): 8 AF × 4. Ordinary steel or stainless hardware |
| `washer5` | 10 OD × 1 | [DIN 125](https://www.westfieldfasteners.co.uk/Datasheets/Washer_FormA_M.pdf) M5: 5.3 ID, 10 OD, 1 thick |

### Joints without screws

Bolts stay only where a joint is set and then locked, because a lock needs constant clamping force and plastic under constant stress relaxes in a hot car. The other joints hold by shape and carry no stress once assembled.

| Joint | How it holds | Note |
|---|---|---|
| Post to bridge | One print | Was four M5 × 16 bolts. `post` still exports alone as a trial piece for the pitch joint |
| Cover and insert to the rear mount | Two tongues from the cover's flange pass through windows in the insert and the mount and hook behind the mount | Was two M3 bolts. The tongues take the plug's push in shear. The insert's entry channel is open to the front so the cover and its boss push straight back |
| End cap to the hooks | Two tongues from the cap's bosses pass through windows in the right hooks and hook behind them | Was two M3 screws, whose nuts pulled against the hooks, not the cap, so the cap was not held against a forward pull |
| Tray lid | Slides under lips, clicks behind a bump (`lid_fit`) | Was two M3 screws |
| `snap` | Tongue 1.8 thick (Z) × 5 wide (X), 1.1 barb, 0.3 window clearance | Catch 0.8 mm deep, 0.2 mm behind the far face. The two tongues of a part have opposite barbs, so the part is located within the clearance and both must be pressed toward the middle to release it. Free length about 19 mm: fitting bends a tongue 1.1 mm, about 0.8 % strain and 2 N by beam formulas for a 2 GPa material; unmeasured for the print |
| `snap_x`, `snap_end` | Cover tongues 19 beyond the tablet edge; centres 4.2 beyond the CD0700 body ends; bay ends 4.4 beyond the centres | Same bay size as before (Z ±33.25) |

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
- Usable depth of the dashboard top behind its front edge, and its shape under the tail and tray; these set `rear_reach`.
- The weights to be used (piece size, mass and packing) and the weighed dock, which replace the planning figures for the tray.
- Top edge of the W124 centre vents' airflow relative to the tape plane, and the dashboard nose profile ahead of the pads; these set `tablet_bottom_z` and `nose_gap`.
