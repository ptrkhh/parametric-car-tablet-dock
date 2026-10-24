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
