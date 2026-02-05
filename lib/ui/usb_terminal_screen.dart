import 'package:flutter/material.dart';

import '../usb/usb_terminal_controller.dart';

class UsbTerminalScreen extends StatefulWidget {
  const UsbTerminalScreen({super.key});

  @override
  State<UsbTerminalScreen> createState() => _UsbTerminalScreenState();
}

class _UsbTerminalScreenState extends State<UsbTerminalScreen> {
  late final UsbTerminalController controller;
  final baudController = TextEditingController(text: '115200');
  final txController = TextEditingController(text: 'Hello from Flutter\n');

  @override
  void initState() {
    super.initState();
    controller = UsbTerminalController()..refreshPorts();
    controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    controller.dispose();
    baudController.dispose();
    txController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = controller.busy;
    final supported = controller.isSupported;
    final connected = controller.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Serial Terminal'),
        actions: [
          IconButton(
            onPressed: busy ? null : controller.refreshPorts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh ports',
          ),
          IconButton(
            onPressed: controller.rxLog.isEmpty ? null : controller.clearLog,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!supported)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'USB/serial is supported on Windows/Linux/macOS/Android in this sample.\n'
                  'If no ports show up, ensure your device presents a serial interface and permissions are available.',
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(controller.selectedPort ?? ''),
                  initialValue: controller.selectedPort,
                  items: controller.ports
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: busy
                      ? null
                      : (value) {
                          setState(() {
                            controller.selectedPort = value;
                          });
                        },
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: TextFormField(
                  controller: baudController,
                  enabled: !busy && !connected,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Baud',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v.trim());
                    if (parsed != null) controller.baudRate = parsed;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: busy || connected
                      ? null
                      : () async {
                          final parsed = int.tryParse(
                            baudController.text.trim(),
                          );
                          if (parsed != null) controller.baudRate = parsed;
                          await controller.connect();
                        },
                  child: const Text('Connect'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy || !connected
                      ? null
                      : () => controller.disconnect(),
                  child: const Text('Disconnect'),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('HEX'),
                selected: controller.showHex,
                onSelected: (busy || !connected)
                    ? null
                    : (v) {
                        setState(() {
                          controller.showHex = v;
                        });
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            controller.status,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: txController,
            enabled: connected && !busy,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Send',
              border: OutlineInputBorder(),
              helperText: 'Sent as UTF-8 bytes.',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: connected && !busy
                ? () => controller.sendText(txController.text)
                : null,
            icon: const Icon(Icons.send),
            label: const Text('Write'),
          ),
          const SizedBox(height: 20),
          const Text('Received'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              controller.rxLog.isEmpty ? '(no data yet)' : controller.rxLog,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

//https://github.com/SahilSharma2710/flutter_libserial_port_example.git