# UNDERWORLD INC.

A 3D Android dealership and crime-story simulator.

## Current prototype

- 3D dealership showroom and surrounding city block built from Godot primitives.
- Third-person character movement.
- Touchscreen movement and interaction buttons.
- First story interaction: discover a folder connected to Marcus Vale.
- Enter and drive the first car after completing the desk interaction.
- Keyboard controls are also available for desktop testing.

## Controls

- Arrow buttons / WASD: move.
- INTERACT: inspect the desk, enter or exit the car.
- In the car: up accelerates, down reverses, left/right steer.

## Build

This project uses Godot 4.3 with the Compatibility renderer.

The GitHub Actions workflow in `.github/workflows/underworld-android.yml` exports a debug APK and uploads it as a workflow artifact.

The first build is a prototype. Art, models, sound, more missions, saving, and optimization will be expanded in later builds.


Build workflow uses the Godot CI 4.3 container image and exports from this project directory.
