# Prototype inputs

All values are mm, degrees, or grams. This is a geometric prototype, not fitted manufacturing data.

| Input | Value / status | Source |
|---|---|---|
| Tablet width, height, thickness | 253.8, 165.3, 6.3 | Samsung nominal specification in design brief |
| Tablet mass | 500 g | Samsung nominal specification |
| Corner radius | 8, provisional | Modelling assumption, measure before printing |
| Rail clearance | 0.5, provisional | Fit sample required |
| Release travel | 8, provisional | Must exceed actual USB engagement plus clearance; not the stated protrusion |
| Release yaw | 12°, provisional | Mechanism development choice |
| Camera location/protrusion/FOV | Unmeasured | Tablet and actual recording mode required |
| USB centre and engagement | Unmeasured | Tablet and both actual connectors required |
| Button, speaker, microphone positions | Unmeasured | Tablet measurements required |
| Essager body and strain relief | Unmeasured | Actual cable required |
| CD0700 body | 49.3 × 12.7 × 8.9, nominal | Manufacturer image in spec; verify with actual adapter |
| Cable and attached plug clearances | Unmeasured | Downstream plugs remain outside cover |
| Nominal installed pitch, minimum height | Unmeasured | Occupant sightline, road camera view, and removal envelope |
| ABS grade, shrinkage, usable build volume | Unknown | Obtain from print service |
| Dashboard contact and tape | Unqualified | Same standard feet across cars; no custom contour |

The `collision_eps=0.01` modelling tolerance is not print clearance or a strength allowance.
Base loads include all supported printed hardware, connectors and cables in addition to the tablet, including lever arms.

## Connector/feature prototype assumptions

`cd0700_body=[12.7,8.9,49.3]` is oriented as protrusion/thickness/vertical edge length, pending seated measurements. The [manufacturer page](https://www.cablecreation.com/products/2-in-1-usb-c-to-3-5mm-headphone-audio-adapter) identifies CD0700 and its two functions; its text dimensions differ from the previously reviewed product-image body dimensions, so neither is a measured fit guarantee. The nominal body dimensions must be checked on the user's adapter.

`essager_body=[12.7,6.3,16]` is entirely provisional. Both bodies start 2 mm beyond the tablet edge, with USB at `usb_z=0`. All body corner shapes, plug shoulders, electrical seating depth, and strain reliefs need measurement. The common cover extends 22 mm beyond the edge: the user's 15 mm estimate describes the connector, not the wall thickness needed to conceal it.

Provisional camera centre: X=-110, Z=62, view-cone half-angle 35 degrees. Provisional speaker windows: both side edges at Z=±50; control window: top edge at X=-70. No camera protrusion is included in the bare-body motion envelope yet. Verify the actual camera island, every microphone, button and speaker, then update these references before a full print. Existing openings are design placeholders, not verified feature alignment.

M3 clearance hole 3.4, hex nut pocket 5.8 across flats × 2.7 deep are print allowances for ordinary M3 hardware. Verify the purchased nuts, thread reach, washers and driver access on a coupon.

## Support assumptions and purchased hardware

Nominal tablet bottom is 70 mm above the flat-pad plane at zero pitch and height. This is a modelling starting point, not a measured W124 installation height. The upper pivot is 65 mm behind the tablet centre plane. Outer mast: 85 mm tall from Z=45; inner tongue: 100 mm below its pivot. A 50 mm slide leaves 27.35 mm of overlap at the maximum setting. The slide's 0.3 mm per-side gap needs an ABS coupon.

The proposed M5 socket cap hardware uses nominal 8.5 mm head diameter, 5 mm head height, and 4 mm hex drive; see [Accu's ISO 4762 dimensional example](https://www.accu.co.uk/metric-cap-head-screws/652691-SSC-M5-50-TI5). This is a dimensional reference, not a titanium purchase recommendation. Use ordinary steel/stainless hardware selected with the service. DIN 934 M5 nuts are nominally 8 mm across flats and 4 mm thick; see [manufacturer table](https://www.performancefastenersltd.co.uk/_files/ugd/aa5dc8_659865f859d941c2905d0a253d751077.pdf). Printed pockets are 8.4 AF × 4.4 deep. M5 clearance holes are 5.6 mm. Do not substitute a thicker nut standard without checking.

The cable corridor assumes up to 5 mm cable diameter, a 1 mm diameter allowance in the open clip, and a loose service loop behind the right half of the tablet. Measure bend radius, loop length, strain relief, plug bodies and the available windshield clearance. The free corridor is not a validated routed cable.

## Standard base assumptions

Two identical rounded 70 × 50 × 6 mm flat pads are spaced 130 mm between upper pivots. Each foot has two orthogonal M5 pivots with provisional ±15-degree limits. The nominal 7,000 mm² rectangular tape-area sum is reduced by rounded corners and any unbonded regions; it is not an adhesive capacity. Pad size, spacing and 70 mm nominal tablet-bottom height are unmeasured prototype choices. No W124 mounting-space or other-dashboard contact measurement exists yet.

Use an initial mass budget only for planning: tablet 500 g, cradle/insert/cover 250 g, mast 100 g, bridge/feet 150 g, bolts/nuts/washers 70 g, connector/cables 40 g; total 1,110 g. These are allowances, not measured part masses or a load rating. Replace every allowance with weighed hardware before a load test. The tablet centre is approximately Z=152.65..202.65 at zero pitch; tilted states also change the lever arms. Measure every component's centre relative to the actual tape footprint. Static moments and inertial loads use all supported mass, not 500 g alone.

Each foot pivot has a 16 mm central lug between cheeks spaced 18 mm apart. The two 1 mm side gaps are intentional spaces for measured M5 washers: two per pivot, eight total. [DIN 125 dimensional table](https://www.westfieldfasteners.co.uk/Datasheets/Washer_FormA_M.pdf) gives nominal 5.3 mm ID, 10 mm OD and 1 mm thickness for M5. Actual thickness and print tolerances must be measured and shimmed; the cheeks must not be forced inward to consume the full 2 mm gap. Washer friction, bolt torque and hot creep remain physical tests.
