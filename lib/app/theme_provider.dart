import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends StateNotifier<String> {
  final _storage = const FlutterSecureStorage();
  ThemeNotifier() : super('system');

  Future<void> load() async {
    try {
      final mode = await _storage.read(key: 'themeMode');
      if (mode != null) state = mode;
    } catch (_) {}
  }

  Future<void> setThemeMode(String mode) async {
    state = mode;
    try { await _storage.write(key: 'themeMode', value: mode); } catch (_) {}
  }

  ThemeMode get themeMode {
    switch (state) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, String>((ref) => ThemeNotifier());
