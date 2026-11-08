# UNDERWORLD INC.

A 3D, story-driven dealership and underworld simulator for Android, built with Godot 4.3.

## Current playable chapter

- Explore the Westbridge Motors dealership and an expanded city district.
- Third-person character movement with mobile touch controls and a fixed follow camera.
- Enter and drive the starter car; use touch controls to accelerate, reverse and steer.
- Story mission: discover the folder, meet Marcus Vale at the freight yard, retrieve the sealed package, and return to the dealership.
- Career economy: start with $2,450, buy trade-ins for $1,200 and sell them for $1,950.
- Daylight cycle and environmental details including streetlights, trees, parked cars and pedestrians.
- Automatic career save for mission progress, cash, and dealership stock.

## Mobile controls

- D-pad: move on foot.
- RUN: sprint on foot.
- INTERACT: inspect story locations, enter/exit the car, and operate the dealership.
- In the car: ▲ accelerate, ▼ reverse/brake, ◀ ▶ steer.

## Build and validation

Godot 4.3, Compatibility renderer, Android arm64-v8a.

The GitHub Actions workflow:
1. Imports the project.
2. Runs a headless gameplay smoke test.
3. Exports a signed debug APK.
4. Verifies APK signature, package ID, app label, and archive integrity.
5. Uploads the APK as `underworld-inc-android-signed`.

The current target is a complete, stable first playable chapter. Visuals are built from original Godot primitives and are being improved iteratively; this is not yet a finished commercial-quality release.
