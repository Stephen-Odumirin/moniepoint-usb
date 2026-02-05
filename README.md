# moniepoint_usb

Flutter app for reading/writing data to USB serial devices (e.g. USB→UART adapters, Arduino serial ports) using `flutter_libserialport`.

Based on:
- https://geekyants.com/blog/reading-data-using-usb-in-flutter

## Run

```bash
flutter pub get
flutter run -d windows   # or macos / linux
```

## Using the app

- Pick a port (Windows: `COM3`, macOS: `/dev/tty.*`, Linux: `/dev/ttyUSB0` or `/dev/ttyACM0`)
- Set baud rate
- Connect
- Write text (UTF-8)
- Watch incoming data in the “Received” log

## Troubleshooting

- macOS/Linux: if you see errors about `libserialport` missing, install it (e.g. `brew install libserialport` on macOS).
- Linux permissions: you may need to add your user to the `dialout` group.

## Notes

- iOS/web are not supported by this serial backend.
- Android USB-OTG support varies by device/permissions. If you need robust Android USB-serial, we can add an Android-specific backend (e.g. `usb_serial`).
