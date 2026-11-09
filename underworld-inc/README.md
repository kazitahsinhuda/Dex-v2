# UNDERWORLD INC.

A 3D, story-driven dealership and underworld simulator for Android, built with Godot 4.3.

## Campaign

- Opening prologue moves through the office, Alex's apartment, and the bus stop. A solicitor's voicemail points him to his father's old dealership; the inheritance letter is not revealed until after Alex completes his first repaired-car sale.
- Chapter 1: investigate the abandoned dealership, meet Marcus Vale, recover the freight-yard package, and escape a police pursuit.
- First dealership job: buy a neglected hatchback for $1,200, pay $250 for repairs, and sell it for $1,950. Only after this first sale does Alex find the solicitor's letter and learn why his missing father matters. Later trade-ins use the same buy/repair/sell loop; two more profitable sales unlock the next story chapter.
- Chapter 2: work with mechanic Lena Ortiz, recover the service file from a storage yard, and escape a second police pursuit.
- Chapter 3: confront Marcus, recover the original records-depot ledger, then choose an ending: expose the network with Detective Reed or join Marcus and take control of it.
- Post-campaign free play: continue buying and selling trade-ins and grow the dealership.

## World and controls

- Explore Westbridge on foot in third person.
- Live Westbridge minimap shows the player's position, mission waypoint, and both destinations during the final choice.
- Parked street cars are enterable and drivable; tap INTERACT beside a car to enter and again to exit.
- The player is a layered streetwear character with rounded hoodie, denim, limbs, shoes, hair, and face details; the collision capsule is aligned to ground level instead of leaving Alex hovering above it.
- The world now includes authored 1024px seamless SVG texture tiles for grass, asphalt, concrete, fabric, denim, wood, metal, and plaster, plus generated normal detail. Streets have pavements, kerbs, lane markings, drains, and asphalt repairs; buildings have window grids, frames, ledges, entrances, and sign bands.
- Vehicle bodies use rounded panels, curved glass, mirrors, wheel rims, lamps, and metallic paint.
- Saves from earlier prototype builds are migrated once to a fresh story start so the new prologue is not skipped; current-version campaign saves are preserved.
- Enter and drive the starter car; acceleration builds gradually, reverse is slower, coasting has rolling resistance, and steering depends on actual road speed.
- Hold the D-pad buttons to move; hold RUN to sprint.
- INTERACT advances the prologue, talks to characters, collects mission evidence, and operates the dealership/workshop.
- Drag on the open right side of the screen to orbit the camera.
- Device text-to-speech reads story messages when an Android voice is available.
- Career progress, cash, stock, and mission stage save automatically.

## Build and validation

Godot 4.3, Compatibility renderer, Android arm64-v8a.

The GitHub Actions workflow imports the project, runs a headless gameplay smoke test, runs campaign and dealership progression assertions, exports a signed debug APK, and verifies its signature, package ID, app label, and archive integrity.

The world still uses a stylised low-poly layout rather than a photorealistic imported 3D city, but the player and surface materials are no longer the original box-and-flat-color placeholders. Device runtime, touch behavior, and the quality/availability of installed Android voices still require real-phone validation; a successful CI build does not prove those device behaviors.
