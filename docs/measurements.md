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
