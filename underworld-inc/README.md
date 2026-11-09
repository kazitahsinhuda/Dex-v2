# UNDERWORLD INC.

A 3D, story-driven dealership and underworld simulator for Android, built with Godot 4.3.

## Campaign

- Opening prologue: Alex loses his job, falls behind on rent, receives the inheritance letter, and arrives in Westbridge.
- Chapter 1: investigate the abandoned dealership, meet Marcus Vale, recover the freight-yard package, and escape a police pursuit.
- Dealership career: buy trade-ins for $1,200 and sell for $1,950. Two additional profitable sales unlock the next story chapter.
- Chapter 2: work with mechanic Lena Ortiz, recover the service file from a storage yard, and escape a second police pursuit.
- Chapter 3: confront Marcus, recover the original records-depot ledger, then choose an ending: expose the network with Detective Reed or join Marcus and take control of it.
- Post-campaign free play: continue buying and selling trade-ins and grow the dealership.

## World and controls

- Explore Westbridge on foot in third person.
- Live Westbridge minimap shows the player's position, mission waypoint, and both destinations during the final choice.
- Enter and drive the starter car; accelerate, reverse, and steer with the on-screen D-pad.
- Hold the D-pad buttons to move; hold RUN to sprint.
- INTERACT advances the prologue, talks to characters, collects mission evidence, and operates the dealership/workshop.
- Drag on the open right side of the screen to orbit the camera.
- Device text-to-speech reads story messages when an Android voice is available.
- Career progress, cash, stock, and mission stage save automatically.

## Build and validation

Godot 4.3, Compatibility renderer, Android arm64-v8a.

The GitHub Actions workflow imports the project, runs a headless gameplay smoke test, runs campaign and dealership progression assertions, exports a signed debug APK, and verifies its signature, package ID, app label, and archive integrity.

Visuals currently use original Godot primitives and low-poly geometry. Device runtime, touch behavior, and the quality/availability of installed Android voices still require real-phone validation; a successful CI build does not prove those device behaviors.
