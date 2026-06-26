import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:akilli_mutfak/constants/api_keys.dart';

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
  /// Case-insensitive + İngilizce + kısmi eşleşme destekler
  List<Map<String, dynamic>> getTariflerByCategory(String category) {
    if (category == 'Tümü') return _tarifler;

    // Her Türkçe kategoriye karşılık gelen anahtar kelimeler
    const keywords = {
      'Et':           ['et', 'beef', 'lamb','goat', 'meat'],
      'Tavuk':        ['tavuk', 'chicken', 'poultry'],
      'Hafif':        ['hafif', 'seafood', 'side', 'starter', 'breakfast', 'dessert', 'pasta', 'miscellaneous', 'light'],
      'Zeytinyağlı':  ['zeytinyag', 'vegetarian', 'vegan', 'veggie', 'olive'],
    };

    final keys = keywords[category] ?? [category.toLowerCase()];

    return _tarifler.where((t) {
      final cat = (t['category'] ?? '').toString().toLowerCase().trim();
      if (cat.isEmpty) return false;
      // Tam eşleşme veya anahtar kelime içerme
      return keys.any((k) => cat == k || cat.contains(k) || k.contains(cat));
    }).toList();
  }

  /// Cache'i sıfırla (normalize sonrası temiz yüklemek için)
  void resetCache() {
    _isLoaded = false;
    _tarifler = [];
    _oneCikanTarifler = [];
    _favoriler = [];
    debugPrint('🔄 DataProvider: Cache sıfırlandı.');
  }

  /// Tüm verileri önceden yükle (Splash Screen'de çağrılır)
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      // 1) Gemini modelini başlat
      await _initGemini();

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
  Future<void> _initGemini() async {
    try {
      final apiKey = await ApiKeys.geminiApiKey;
      if (apiKey.isEmpty) {
        _geminiReady = false;
        debugPrint('⚠️ DataProvider: Gemini API anahtarı ayarlanmamış.');
        return;
      }
      geminiModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
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
      _geminiReady = false;
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

      // DEBUG: Firebase'den gelen kategori değerlerini göster
      final cats = _tarifler.map((t) => '"${t['category']}"').toSet().toList();
      debugPrint('🗂️ DataProvider: Yüklenen kategoriler → $cats');
      debugPrint('🗂️ DataProvider: Toplam ${_tarifler.length} tarif yüklendi.');
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
