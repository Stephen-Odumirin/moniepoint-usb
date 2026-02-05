import 'package:flutter_test/flutter_test.dart';
import 'package:moniepoint_usb/main.dart';

void main() {
  testWidgets('App renders USB terminal screen', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('USB Serial Terminal'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });
}
