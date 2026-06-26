import 'dart:convert';
import 'package:flutter/services.dart';

class ApiKeys {
  /// Gemini API anahtarı — önce --dart-define-from-file'dan dener,
  /// bulamazsa secrets.json asset'inden okur.
  static const String _fromEnv = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static String? _cached;

  /// API key'i döner. İlk çağrıda secrets.json'dan yüklenir (gerekirse).
  static Future<String> get geminiApiKey async {
    if (_cached != null) return _cached!;

    // 1) --dart-define-from-file ile geldi mi?
    if (_fromEnv.isNotEmpty) {
      _cached = _fromEnv;
      return _cached!;
    }

    // 2) Asset'ten oku (fallback)
    try {
      final jsonStr = await rootBundle.loadString('secrets.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _cached = data['GEMINI_API_KEY'] as String? ?? '';
    } catch (e) {
      _cached = '';
    }
    return _cached!;
  }

  /// Synchronous getter — sadece --dart-define-from-file çalışıyorsa doğru değer döner.
  /// Yoksa cache'e bakılır (eğer daha önce async yüklendi ise).
  static String get geminiApiKeySync => _cached ?? _fromEnv;
}