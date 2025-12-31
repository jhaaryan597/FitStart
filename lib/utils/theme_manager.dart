import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Note: This ThemeManager is kept for backward compatibility
// Consider migrating to a ThemeBloc in the future
class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadTheme();
  }

  void _loadTheme() async {
    final Box<dynamic> authBox = await Hive.openBox('fitstart_auth');
    final isDarkMode = authBox.get('isDarkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final Box<dynamic> authBox = await Hive.openBox('fitstart_auth');
    await authBox.put('isDarkMode', isDarkMode);
    notifyListeners();
  }
}
