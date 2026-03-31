# Motion Bridge

Motion Bridge is a mobile remote control application built with Flutter, designed to seamlessly turn your smartphone into an extension of your desktop PC. With an ethereal "invisible interface," it offers low-latency trackpad controls, specialized gestures, and ambient dimming features.

## Features

*   **Low-Latency Trackpad**: High FPS mouse movement transmission using UDP.
*   **Smart Gestures**: One-finger tap for left click, two-finger tap for right click, and two-finger pan for scrolling.
*   **Ambient Dimming**: Adjust your desktop environment or PC brightness right from the controller, syncing with your phone's sensors.
*   **Ethereal UI (Glassmorphism)**: An immersive, bezel-less design with haptic feedback for every meaningful interaction.
*   **UDP Network Discovery**: Automatic network discovery and handshake mechanism to pair mobile and desktop seamlessly.

## Documentation

For more details regarding the design philosophy, frontend architecture, and network protocols, please refer to the `docs/` folder:

*   [Frontend Architecture](docs/frontend.md)
*   [Design & UX Guide](docs/design.md)
*   [Network & Handshake Protocol](docs/PROTOCOL.md)

## Getting Started

To run this Flutter project, ensure you have the Flutter SDK installed and a mobile device or emulator connected.

1. Clone the repository.
2. Run `flutter pub get` to fetch the required dependencies.
3. Run `flutter run` on your target device (Android/iOS).

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.
