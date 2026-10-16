import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStoreProvider = Provider<LocalStore>((_) => LocalStore());

/// JSON persistence on-device (SharedPreferences).
/// Used by the standalone (no-backend) mode so profile, plans and tracking
/// data survive app restarts. Non-sensitive keys only.
class LocalStore {
  Future<Map<String, dynamic>?> readJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// Storage keys.
abstract final class StoreKeys {
  static const devAccounts = 'dev_accounts';
  static const devSession = 'dev_session';
  static const profile = 'local_profile';
  static const plan = 'local_plan';
  static const glucose = 'glucose_readings';
  static const hba1c = 'hba1c_results';
  static const weight = 'weight_records';
  static const water = 'water_logs';
}
