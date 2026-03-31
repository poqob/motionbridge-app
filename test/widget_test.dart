import 'package:flutter_test/flutter_test.dart';
import 'package:motion_bridge/main.dart';

void main() {
  testWidgets('App loads test', (WidgetTester tester) async {
    await tester.pumpWidget(const MotionBridgeApp());
    expect(find.text('Trackpad View (WIP)'), findsNothing);
  });
}
