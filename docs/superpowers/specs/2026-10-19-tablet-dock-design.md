# Dashboard tablet dock design

Status: Approved design brief. This records the agreed concept, not a validated mechanical design or authorization to manufacture.

## Purpose and scope

Create a 3D-printed landscape dock for a bare Samsung Galaxy Tab S7 SM-T875. The first installation is on the dashboard top, centrally above the middle air vents of a Mercedes W124. The display should appear to float above the dashboard, with its support and connector concealed from the normal occupant view.

The dock is custom to the tablet and the two owned connector options. The dashboard mounting hardware must be reusable across different cars without dashboard scans, custom contours, or car-specific reprints. Compatibility with most dashboards is a design target, not an established result.

The base uses adhesive tape rather than drilling or fastening into the dashboard. Avoiding dashboard damage is a requirement; neither secure bonding nor damage-free removal is established merely by specifying VHB.

## Agreed requirements

- Landscape tablet, with USB-C on the right as viewed by an occupant looking at the screen.
- Approximately 50 mm of vertical adjustment, locked after setup.
- Preferably 30 degrees of total pitch adjustment, or ±15 degrees around the nominal viewing angle. Pitch changes whether the screen faces more toward the roof or floor.
- Fore/aft positioning comes from base placement before bonding, not an adjustable arm.
- A central mast is preferred, conditional on acceptable vibration performance. Twin tablet supports are a fallback if the mast or cradle twists or flexes excessively.
- The tablet remains mechanically supported and retained by the cradle. USB-C friction may contribute resistance to sliding but is not the sole retention mechanism.
- Automatic detent retention; no separate release-button action.
- Rear camera clearance sufficient for a forward road view at the installed position.
- Both owned connector options use the same cradle and a common cover, with interchangeable locating inserts.
- Initial dimensions target the bare tablet. Case compatibility is deferred to later dimensional changes.

## Coordinate and movement conventions

Left and right are always defined from the occupant's view of the screen. Inward means toward the dashboard/windshield. Outward means toward occupants and the rear of the car.

The removal tilt is rotation about a roughly vertical axis: the left edge moves inward while the right edge swings outward. It is separate from the locked pitch adjustment of the whole dock. It is not a rotation into portrait orientation.

## Assembly

### Standard dashboard base

A low, rigid bridge supports one central mast and two standard tape feet. Each foot can be set to its local dashboard slope in fore/aft and side-to-side directions, then mechanically locked. Feet and bridge are standard parts shared between cars.

Foot adjustment addresses slope. Conformable tape may accommodate minor surface irregularities; it must not be used to bridge substantial gaps. Footprint, spacing, and joint geometry must be developed around sufficient adhesive contact and rigidity. The final foot design must be checked on representative dashboard surfaces before making broad compatibility claims.

If a surface cannot provide adequate contact, evaluate another mounting position or revise the standard base geometry. Do not introduce a custom contoured foot as the default solution. Strong curvature, soft surfaces, and unsuitable finishes can remain compatibility limits. Any position must also not block the driver's view of the road and must avoid airbag covers and deployment paths; check the vehicle's documentation.

### Central mast and pitch joint

Use a broad, ribbed printed mast with a keyed height slide to resist twisting. Preserve structural overlap throughout the 50 mm adjustment travel. A clamp locks height after installation.

Support the pitch joint on both sides. The proposed locking arrangement uses mating teeth and a metal clamping bolt, allowing discrete viewing-angle increments. Fine continuous adjustment is not a requirement. Select tooth geometry and increments during mechanical design, subject to fit and strength checks.

Use metal bolts and captive nuts for structural adjustment clamps. Route wiring behind or within the support, with enough slack for the full height and pitch ranges. Moving joints must not pinch or tension cables.

### Cradle and automatic retention

The cradle supports the tablet on shaped contact surfaces and guides its lateral travel. A left-side retaining lip prevents the left edge from moving outward while docked. A light automatic detent resists unintended leftward sliding while allowing deliberate removal. While docked, the cradle, not gravity or the USB-C plug, must stop the tablet lifting under road shocks. Any upward capture must release through the slide and tilt, so the final removal step remains a free lift.

Removal sequence:

1. Slide the tablet left against the detent until USB-C is fully disconnected.
2. Press the left edge inward; the right edge swings outward.
3. Lift the tablet free.

Installation sequence:

1. Place the tablet into the cradle in the tilted position.
2. Press the right edge inward until the tablet is flat against its guides.
3. Slide right to engage USB-C and the detent.

Guides must prevent connector-damaging tilt while the plug remains engaged. Stops and locating surfaces must establish alignment without forcing the tablet port to correct misalignment. The plug must not act as the tablet's structural support or the sole end stop.

The exact guide, lip, and detent geometry requires a physical mechanism prototype. In particular, prove that the left edge has enough inward clearance and that retention does not obstruct the required lift-out path. The approved motion is an acceptance requirement, not proof that the illustrative geometry works.

### Connector inserts and cable routing

Support these owned products:

- Essager 100 W USB-C to USB-C cable with 90-degree connectors. The supplied URL has an older LED-display slug, but its current product data and images identify the double-elbow cable.
- CableCreation CD0700 USB-C adapter with USB-C charging and 3.5 mm audio sockets at opposite ends of its body.

Use a common removable right-side cover with a locating insert for each option. Retain the connector body against insertion/extraction forces while maintaining port alignment. Do not require a new main cradle when switching options.

Conceal the tablet-side connector or adapter body. Downstream charging/audio plugs and cable ends may remain outside the dock. Leave appropriate outlets rather than enclosing those plugs in custom pockets. Accessible cable guides route wiring behind the tablet toward the mast and base. Cables lay into open channels before the cover is installed; large plugs need not pass through narrow tunnels.

Orient the Essager cable downward where its geometry allows. With the splitter body alongside the tablet's right edge, its two sockets face opposite vertical directions. Provide clearance at both ends and keep external leads away from the tablet's removal path. Final routes depend on the actual assembled cables, without assuming their straight or angled plug shapes.

The user's approximately 15 mm protrusion estimate is preliminary. It does not define total housing size, cable clearance, or required unplugging travel.

### Camera clearance and appearance

Keep the rear camera area open and avoid support hardware or cables within the needed field of view. The installed road view depends on dashboard height, windshield geometry, and screen pitch as well as the cradle opening. Check the intended dashcam lens with actual footage.

Keep the mast, bridge, fasteners, and wiring behind the display where practical. The concept image illustrates appearance only. Its small front-view inset incorrectly mirrors connector placement; the written right-side convention governs all design work.

## Reference dimensions and evidence

- Samsung's nominal bare-tablet envelope is 253.8 × 165.3 × 6.3 mm, and the SM-T875 weighs 500 g. Measure camera position and protrusion, port location, speaker and microphone openings, edge profiles, and control clearances separately. [Samsung specifications](https://www.samsung.com/hk_en/business/tablets/galaxy-tab-s/galaxy-tab-s7-lte-t875-sm-t875nzketgy/)
- CableCreation's dimension image specifies a body approximately 49.3 × 12.7 × 8.9 mm, converted from 1.94 × 0.50 × 0.35 inches. It is thicker than the tablet. These are reference dimensions, not fitted-pocket tolerances. [Dimension image](https://cdn.shopify.com/s/files/1/0592/1521/6811/products/usbcto3.5mmaudio_4.jpg?v=1664431874)
- [CableCreation product](https://www.cablecreation.com/products/2-in-1-usb-c-to-3-5mm-headphone-audio-adapter)
- [Essager product](https://www.essager3c.com/products/essager-100w-usb-c-to-c-fast-charging-phone-laptop-cable-with-led-power-display-%E5%89%AF%E6%9C%AC-1)
- [Local concept image](../../../tablet-dock-concepts.png)

## Manufacturing approach

A third-party service offers PLA, PETG, and ABS; its printer and build volume are not yet known. ABS is the proposed final-part material among those options, subject to the actual filament specification and print quality. PLA is limited to indoor fit prototypes. PETG is an alternative for mechanism prototypes; it is not prequalified for the final dashboard installation.

Before ordering, obtain the service's usable ABS build volume, filament identity, dimensional capability, and recommendations for controlling warping. Confirm part orientation and joints around printed-layer strength. Do not assume the full cradle fits their printer or select arbitrary splits before obtaining the available volume.

First print small connector-fit, slide, detent, and joint samples. Final parts require heat and load testing; material choice alone does not establish hot-car durability. [ABS guidance](https://help.prusa3d.com/article/abs_2058)

## Required evidence before final manufacturing

1. **Tablet and connectors:** actual dimensions, plug alignment, insertion/extraction travel, cable diameters, and clearance around assembled connectors. Check audio and charging operation with the actual tablet and power source.
2. **Installation envelope:** available space above the W124 center vents, minimum tablet height, nominal screen pitch for the occupants' eye positions, the driver's forward view at the chosen height and pitch, full tilt/removal clearance, camera view, and access to nearby vehicle functions. These checks inform placement and standard-part design, not a custom dashboard contour.
3. **Standard base:** representative dashboard contact checks across slopes and curvatures; locked joints must not rock. Insufficient contact is a failed fit, not permission to fill gaps with extra tape.
4. **Cradle prototype:** repeatable installation/removal in the specified sequence, no forced port misalignment, no unintended tilt or lift while connected, and usable detent force.
5. **Structural testing:** tablet-equivalent load at full height and pitch extremes, followed by vibration and warm-condition tests. Check cracks, creep, loosened joints, adjustment drift, detent release, and adhesive lifting. Begin retention testing with a dummy mass before using the tablet on-road.
6. **Road-use checks:** no unintended release or unplugging, no rattling or sustained screen wobble after bumps, and acceptable recorded road footage. Evaluate screen movement and camera footage separately. If the central support fails, identify whether the mast, cradle, base joint, adhesive, or dashboard is moving before choosing twin supports.
7. **Adhesive qualification:** select tape for the actual surface and loading, verify full contact, and test bonding/removal compatibility on a suitable representative surface. Preserve the no-damage requirement; do not silently add abrasion or permanent surface treatment. [3M design guide](https://multimedia.3m.com/mws/media/1400379O/3m-vhb-tape-design-guide.pdf)

## Deferred scope

No adjustable articulated arm, powered mechanism, separate release button, case-specific cradle, custom dashboard scan, or car-specific printed foot. Do not add these to resolve an unknown without revisiting the agreed scope.

## Review boundary

This document consolidates the agreed concept and identifies the evidence needed to turn it into printable geometry. It does not claim completed CAD, universal dashboard compatibility, damage-free adhesive removal, or qualified thermal/vibration performance. Crash retention is not designed or tested; in a collision the tablet or dock may detach and strike occupants. After user review of this written spec, prepare an implementation plan that starts with the unresolved geometry and small fit/mechanism prototypes.

## Revision 2026-11-19: low placement and OEM-style housing

The user added three requirements after reviewing the first CAD candidate:

1. At the lowest height setting the tablet's bottom edge must sit below the tape faces of the feet, so the screen is as low as vent airflow allows and blocks as little of the road ahead as possible.
2. The tablet must sit further toward the occupants so that, at the lowest height and especially at -15° pitch, it does not run into the feet or the dashboard under them.
3. The dock needs an external housing that looks OEM: smooth edges, mechanisms hidden from the front and sides. What is behind the tablet may stay visible.

Consequences for the concept:

- The first candidate's telescoping mast put the pitch axis about 143 mm above the tape faces at zero height, because the collapsed slide (50 mm travel plus overlap) sat under the fork. With the tablet's bottom below the tape, the fork would have stood about 26 mm above the tablet's top edge, in the occupant view. The height slide therefore moves behind the tablet: a short fixed post carries the pitch fork, the pitch carriage carries a sleeve, and a keyed rail on the cradle spine slides in that sleeve. The support is still one central member, keyed against twist, clamped by one metal bolt and supported on both sides of the pitch joint.
- Height travel now runs along the cradle's own vertical, which tilts with pitch (at ±15° the 50 mm travel is 48.3 mm vertical and 12.9 mm fore/aft).
- The base stands behind the cradle's swept envelope. Below the tape plane nothing may come closer than a dashboard-nose allowance to the pads' front edge.
- The housing is a rounded surround on the front and sides with an open back. It cannot cover the front of the screen beyond the existing lip and hooks, or the top edge between the corner roofs, without blocking the slide, tilt and lift removal path. The tablet's top edge therefore stays exposed. The right end cap comes off for connector access.

These are design decisions to be checked with the same physical evidence listed above, not qualification.

## Revision 2026-11-20: rear foot and weights

With the screen hanging ahead of the front feet, the dock's centre of mass lies in front of its tape footprint, so the tape was pulled upward permanently. The user chose a third foot and/or ballast, and ruled out bracing against the windshield or fixing to car-specific points (speaker grilles, vents): the dock is meant to fit any car, and some dashboards are very deep.

- A tail behind the bridge carries a third standard foot toward the windshield and a lidded weight tray beside it. The tail length is a parameter because dashboard depth varies.
- Weights in the tray cancel the pull on the rear foot's tape; the amount is set by a balance check with the real parts, not by calculation.
- Weights added after printing cost less than printed length or printed mass. The default tail is therefore short, the tray is sized for more weight, and no printed part is meant to act as weight.
- Without weights the dock still works as a three-footed base, with a smaller constant pull on the rear tape.
- The base now follows the dashboard's slope from front to rear. The screen angle is corrected with the pitch index.

## Revision 2026-11-20: one bolt size, no other screws

The user asked for fewer hardware variants, then for no screws wherever the plastic's own springiness can do the job.

- Metal bolts stay on structural adjustment clamps (height, pitch, foot pivots), as this brief already requires. A clamp needs constant force, and plastic under constant stress relaxes in a hot car.
- All eight clamp bolts are the same M5 × 35. The rail head narrowed from 30 to 21 mm so the height clamp takes it.
- Joints that are never adjusted have no screws: the post prints as part of the bridge; the connector cover and the end cap clip on with printed tongues that are relaxed once seated; the tray lid slides under lips.
- Not done: screw-free feet (plain pins would work once all three pads are bonded, but a debonded pad would then let the base fold) and tool-free height and pitch locks. Both change how the dock behaves and need the user's decision.
