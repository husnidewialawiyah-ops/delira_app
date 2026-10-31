import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_dewi/main.dart';

void main() {
  testWidgets('Aplikasi Delira berhasil dijalankan', (WidgetTester tester) async {
    await tester.pumpWidget(const KatalogApp());

    expect(find.text('Delira'), findsOneWidget);
  });
}