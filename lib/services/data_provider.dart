import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

/// Uygulama genelinde veri tutan Singleton servis.
/// Splash Screen'de veriler yüklenip burada cache'lenir,
/// böylece ekranlar açıldığında veri anında hazır olur.
class DataProvider {
  // ── Singleton ──
  DataProvider._internal();
  static final DataProvider _instance = DataProvider._internal();
  static DataProvider get instance => _instance;

  // ── Cache ──
  List<Map<String, dynamic>> _tarifler = [];
  List<Map<String, dynamic>> _oneCikanTarifler = [];
  List<Map<String, dynamic>> _favoriler = [];
  bool _isLoaded = false;

  // ── Gemini ──
  static const String _apiKey = 'AIzaSyBH-jBycJUxYd5CaoeuAbjEsSAbCWBcrUM';
  late final GenerativeModel geminiModel;
  bool _geminiReady = false;

  // ── Getters ──
  List<Map<String, dynamic>> get tarifler => _tarifler;
  List<Map<String, dynamic>> get oneCikanTarifler => _oneCikanTarifler;
  List<Map<String, dynamic>> get favoriler => _favoriler;
  bool get isLoaded => _isLoaded;
  bool get isGeminiReady => _geminiReady;

  /// Bir tarifin favorilerde olup olmadığını kontrol et
  bool isFavorite(String title) {
    return _favoriler.any((f) => f['title'] == title);
  }

  /// Kategoriye göre filtrelenmiş tarifler
  List<Map<String, dynamic>> getTariflerByCategory(String category) {
    if (category == 'Tümü') return _tarifler;
    return _tarifler.where((t) => t['category'] == category).toList();
  }

  /// Tüm verileri önceden yükle (Splash Screen'de çağrılır)
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      // 1) Gemini modelini başlat
      _initGemini();

      // 2) Firebase'den verileri çek (tek seferlik)
      await Future.wait([
        _loadTarifler(),
        _loadOneCikanTarifler(),
        _loadFavoriler(),
      ]);

      _isLoaded = true;
      debugPrint('✅ DataProvider: Tüm veriler yüklendi. '
          'Tarifler: ${_tarifler.length}, '
          'Öne Çıkanlar: ${_oneCikanTarifler.length}, '
          'Favoriler: ${_favoriler.length}');
    } catch (e) {
      debugPrint('❌ DataProvider: Veri yükleme hatası: $e');
      _isLoaded = true; // hata olsa bile tekrar denenmesini engellemek için
    }
  }

  /// Gemini modelini önceden başlat
  void _initGemini() {
    try {
      geminiModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        systemInstruction: Content.text(
          '''Sen deneyimli ve yardımsever bir Türk mutfak asistanısın. Adın "AI Şef".
Görevin kullanıcılara yemek tarifleri, mutfak ipuçları ve malzeme önerileri sunmak.
Yanıt verirken şu kurallara uy:
- Her zaman Türkçe yanıt ver
- Kısa ve net ol, gereksiz açıklamalardan kaçın
- Samimi ve teşvik edici bir ton kullan
- Tarif verirken adım adım yönlendirme yap
- Malzeme miktarlarını belirt
- Pişirme sürelerini belirt
- Emoji kullan ama abartma'''
        ),
      );
      _geminiReady = true;
      debugPrint('✅ DataProvider: Gemini model hazır.');
    } catch (e) {
      debugPrint('❌ DataProvider: Gemini başlatma hatası: $e');
    }
  }

  /// Firebase Tarifler koleksiyonunu cache'e yükle
  Future<void> _loadTarifler() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Tarifler')
          .get();
      _tarifler = snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      debugPrint('⚠️ Tarifler yüklenemedi: $e');
    }
  }

  /// Firebase OneCikanTarifler koleksiyonunu cache'e yükle
  Future<void> _loadOneCikanTarifler() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('OneCikanTarifler')
          .get();
      _oneCikanTarifler = snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      debugPrint('⚠️ Öne çıkan tarifler yüklenemedi: $e');
    }
  }

  /// Firebase Favoriler koleksiyonunu cache'e yükle
  Future<void> _loadFavoriler() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Favoriler')
          .get();
      _favoriler = snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      debugPrint('⚠️ Favoriler yüklenemedi: $e');
    }
  }

  /// Verileri yeniden yükle (yenile butonu için)
  Future<void> refresh() async {
    _isLoaded = false;
    _tarifler = [];
    _oneCikanTarifler = [];
    _favoriler = [];
    await Future.wait([
      _loadTarifler(),
      _loadOneCikanTarifler(),
      _loadFavoriler(),
    ]);
    _isLoaded = true;
    debugPrint('🔄 DataProvider: Veriler yenilendi.');
  }

  /// Cache'e yeni bir tarif ekle (Firebase'e yazıldıktan sonra)
  void addToTariflerCache(Map<String, dynamic> recipe) {
    _tarifler.add(recipe);
  }

  /// Cache'e yeni bir öne çıkan tarif ekle
  void addToOneCikanCache(Map<String, dynamic> recipe) {
    _oneCikanTarifler.add(recipe);
  }

  /// Cache'e favori tarif ekle
  void addToFavorilerCache(Map<String, dynamic> recipe) {
    _favoriler.add({...recipe, 'isFavorite': true});
  }

  /// Cache'den favori tarif kaldır
  void removeFromFavorilerCache(String title) {
    _favoriler.removeWhere((f) => f['title'] == title);
  }
}
