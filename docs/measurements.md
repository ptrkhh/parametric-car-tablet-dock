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
