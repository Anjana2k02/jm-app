import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jammer_app/app.dart';
import 'package:jammer_app/controllers/theme_controller.dart';

void main() {
  testWidgets('theme mode option switches the app theme and persists',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await ThemeController.instance.setMode(ThemeMode.light);
    await tester.pumpWidget(const App(isConfigured: false));

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.light);

    await ThemeController.instance.setMode(ThemeMode.dark);
    await tester.pump();
    expect(app().themeMode, ThemeMode.dark);

    await ThemeController.instance.setMode(ThemeMode.system);
    await tester.pump();
    expect(app().themeMode, ThemeMode.system);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'system');
  });

  test('saved theme mode is restored on load', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    await ThemeController.instance.load();
    expect(ThemeController.instance.value, ThemeMode.dark);
  });
}
