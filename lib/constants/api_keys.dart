class ApiKeys {
  /// Gemini API anahtarı, `secrets.json` veya `--dart-define` aracılığıyla ortam değişkenlerinden alınır.
  /// API anahtarınızı https://aistudio.google.com/ adresinden alabilirsiniz.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}