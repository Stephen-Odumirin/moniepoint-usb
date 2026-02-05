import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'usb_serial_service.dart';

class UsbTerminalController extends ChangeNotifier {
  UsbTerminalController({UsbSerialService? service})
    : _service = service ?? UsbSerialService();

  final UsbSerialService _service;
  StreamSubscription<Uint8List>? _inputSub;

  List<String> ports = const [];
  String? selectedPort;

  int baudRate = 115200;
  bool connected = false;
  bool busy = false;
  bool showHex = false;

  String rxLog = '';
  String status = '';

  bool get isSupported => _service.isSupported;

  void setStatus(String message) {
    status = message;
    notifyListeners();
  }

  Future<void> refreshPorts() async {
    ports = _service.listPorts();
    selectedPort ??= ports.isNotEmpty ? ports.first : null;
    notifyListeners();
  }

  Future<void> connect() async {
    final portName = selectedPort;
    if (portName == null || portName.isEmpty) {
      setStatus('Select a port first.');
      return;
    }
    if (busy) return;

    busy = true;
    notifyListeners();
    try {
      await _service.open(portName: portName, baudRate: baudRate);
      await _inputSub?.cancel();
      _inputSub = _service.input.listen(_onData);
      connected = true;
      setStatus('Connected to $portName');
    } catch (e) {
      setStatus('Connect failed: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await _inputSub?.cancel();
      _inputSub = null;
      await _service.close();
      connected = false;
      setStatus('Disconnected');
    } catch (e) {
      setStatus('Disconnect failed: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clearLog() {
    rxLog = '';
    notifyListeners();
  }

  void sendText(String text) {
    if (!connected) {
      setStatus('Not connected.');
      return;
    }
    final data = Uint8List.fromList(utf8.encode(text));
    final written = _service.write(data);
    setStatus('Sent $written bytes');
  }

  void _onData(Uint8List data) {
    final formatted = showHex ? _toHex(data) : _toSafeText(data);
    rxLog += formatted;
    if (!formatted.endsWith('\n')) rxLog += '\n';
    notifyListeners();
  }

  static String _toSafeText(Uint8List data) {
    final s = latin1.decode(data, allowInvalid: true);
    final out = StringBuffer();
    for (final cu in s.codeUnits) {
      if (cu == 0x0a || cu == 0x0d || (cu >= 0x20 && cu <= 0x7e)) {
        out.writeCharCode(cu);
      } else {
        out.write('.');
      }
    }
    return out.toString();
  }

  static String _toHex(Uint8List data) {
    final b = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      final v = data[i];
      b.write(v.toRadixString(16).padLeft(2, '0'));
      if (i != data.length - 1) b.write(' ');
    }
    return b.toString();
  }

  @override
  void dispose() {
    _inputSub?.cancel();
    _service.close();
    super.dispose();
  }
}
