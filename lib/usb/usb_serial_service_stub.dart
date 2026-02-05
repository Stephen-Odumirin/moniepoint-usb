import 'dart:async';
import 'dart:typed_data';

class UsbSerialService {
  bool get isSupported => false;

  Stream<Uint8List> get input => const Stream.empty();

  List<String> listPorts() => const [];

  Future<void> open({
    required String portName,
    int baudRate = 115200,
    int dataBits = 8,
    int stopBits = 1,
  }) => Future.error(
    UnsupportedError('USB/serial is not supported on this platform.'),
  );

  Future<void> close() async {}

  int write(Uint8List data) =>
      throw UnsupportedError('USB/serial is not supported on this platform.');
}
