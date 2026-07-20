import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/app_constants.dart';

void main() {
  testWidgets('AppConstants categories include expected discovery filters',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(AppConstants.categories.first['name'] as String),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(AppConstants.categories.length, greaterThanOrEqualTo(5));
  });
}
