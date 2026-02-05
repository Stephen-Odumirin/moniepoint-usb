import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

class UsbSerialService {
  SerialPort? _port;
  StreamController<Uint8List>? _controller;
  StreamSubscription<Uint8List>? _subscription;

  bool get isSupported =>
      Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isAndroid;

  Stream<Uint8List> get input =>
      _controller?.stream ?? const Stream<Uint8List>.empty();

  List<String> listPorts() {
    if (!isSupported) return const [];
    try {
      return SerialPort.availablePorts;
    } catch (_) {
      return const [];
    }
  }

  Future<void> open({
    required String portName,
    int baudRate = 115200,
    int dataBits = 8,
    int stopBits = 1,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'USB/serial supported on Windows/Linux/macOS/Android only.',
      );
    }

    await close();

    late final SerialPort port;
    try {
      port = SerialPort(portName);
    } catch (e) {
      throw StateError(
        'Failed to initialize serial driver. '
        'On macOS/Linux you may need to install libserialport. '
        'Original error: $e',
      );
    }

    if (!port.openReadWrite()) {
      final error = SerialPort.lastError;
      port.dispose();
      throw StateError('Failed to open port $portName (error: $error).');
    }

    port.config = SerialPortConfig()
      ..baudRate = baudRate
      ..bits = dataBits
      ..stopBits = stopBits
      ..parity = SerialPortParity.none;

    _port = port;
    _controller = StreamController<Uint8List>.broadcast();

    final reader = SerialPortReader(port);
    _subscription = reader.stream.listen(
      (data) => _controller?.add(data),
      onError: (Object e, StackTrace st) {
        _controller?.add(Uint8List.fromList(utf8.encode('ERROR: $e\n')));
      },
      cancelOnError: false,
    );
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;

    await _controller?.close();
    _controller = null;

    final port = _port;
    _port = null;
    if (port == null) return;
    if (port.isOpen) port.close();
    port.dispose();
  }

  int write(Uint8List data) {
    final port = _port;
    if (port == null || !port.isOpen) {
      throw StateError('Serial port is not open.');
    }
    return port.write(data);
  }
}
