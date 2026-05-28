import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'recipe_api_service.dart';
import 'package:akilli_mutfak/constants/api_keys.dart';

/// Firebase sync servisi - TheMealDB'den gelen tarifleri Firebase'e yazar
/// ve Gemini ile tamamını Türkçeye çevirir
class FirebaseSyncService {
  static const String _geminiApiKey = ApiKeys.geminiApiKey;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tarifleri TheMealDB'den çekip Firebase'e yaz
  /// Çeşitli kategorilerden tarif çeker
  static Future<void> syncRecipesToFirebase({int perCategory = 3}) async {
    try {
      // Önce Firebase'de zaten veri var mı kontrol et
      final existing = await _firestore.collection('Tarifler').limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint('Firebase\'de zaten tarifler mevcut, sync atlanıyor.');
        return;
      }

      debugPrint('Tarifler sync ediliyor...');

      if (_geminiApiKey.isEmpty || _geminiApiKey.contains('BURAYA_GEMINI_API_ANAHTARINIZI_YAPISTIRIN')) {
        debugPrint('⚠️ FirebaseSyncService: Gemini API anahtarı ayarlanmamış! Sync iptal ediliyor.');
        return;
      }

      // Gemini modelini çeviri için başlat
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );

      // Çeşitli kategorilerden tarif çek
      final categories = ['Chicken', 'Beef', 'Seafood', 'Vegetarian', 'Lamb', 'Pasta', 'Dessert', 'Starter'];
      
      for (final category in categories) {
        try {
          final meals = await RecipeApiService.fetchMealsByCategory(category);
          
          // Her kategoriden belirli sayıda tarif al
          final selectedMeals = meals.take(perCategory).toList();

          for (final mealSummary in selectedMeals) {
            try {
              final mealId = mealSummary['idMeal'];
              if (mealId == null) continue;

              // Detaylı tarif bilgisini çek
              final detail = await RecipeApiService.fetchMealDetail(mealId);
              if (detail == null) continue;

              // Tüm tarifi Türkçeye çevir (tek bir Gemini çağrısıyla)
              final translated = await _translateFullRecipe(model, detail);

              // Zorluk seviyesi tahmin et
              final difficulty = _estimateDifficulty(detail['ingredients'] as List<String>);
              // Süre tahmin et
              final duration = _estimateDuration(detail['instructions'] ?? '');

              // Firebase'e yaz
              await _firestore.collection('Tarifler').add({
                'title': translated['title'],
                'description': translated['description'],
                'image': detail['image'],
                'difficulty': difficulty,
                'duration': duration,
                'category': RecipeApiService.mapToAppCategory(detail['category'] ?? ''),
                'ingredients': translated['ingredients'],
                'instructions': translated['instructions'],
                'area': detail['area'],
                'originalTitle': detail['title'],
                'isFavorite': false,
                'source': 'TheMealDB',
                'mealDbId': mealId,
                'createdAt': FieldValue.serverTimestamp(),
              });

              debugPrint('✅ Tarif eklendi: ${translated['title']}');
              
              // API rate limiting - çok hızlı istek atma
              await Future.delayed(const Duration(milliseconds: 300));
            } catch (e) {
              debugPrint('⚠️ Tarif eklenemedi: $e');
              continue;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Kategori yüklenemedi ($category): $e');
          continue;
        }
      }

      debugPrint('🎉 Tüm tarifler sync edildi!');
    } catch (e) {
      debugPrint('❌ Sync hatası: $e');
    }
  }

  /// Öne çıkan tarifleri yükle (rastgele seçilen tarifler)
  static Future<void> syncFeaturedRecipes({int count = 5}) async {
    try {
      final existing = await _firestore.collection('OneCikanTarifler').limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint('Öne çıkan tarifler zaten mevcut.');
        return;
      }

      if (_geminiApiKey.isEmpty || _geminiApiKey.contains('BURAYA_GEMINI_API_ANAHTARINIZI_YAPISTIRIN')) {
        debugPrint('⚠️ FirebaseSyncService: Gemini API anahtarı ayarlanmamış! Öne çıkan tarif sync iptal ediliyor.');
        return;
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );

      final meals = await RecipeApiService.fetchRandomMeals(count);

      for (final meal in meals) {
        try {
          final translated = await _translateFullRecipe(model, meal);

          await _firestore.collection('OneCikanTarifler').add({
            'title': translated['title'],
            'subtitle': translated['description'],
            'image': meal['image'],
            'category': RecipeApiService.mapToAppCategory(meal['category'] ?? ''),
            'ingredients': translated['ingredients'],
            'instructions': translated['instructions'],
            'originalTitle': meal['title'],
            'isAddedToFavorites': false,
            'source': 'TheMealDB',
            'mealDbId': meal['idMeal'],
            'createdAt': FieldValue.serverTimestamp(),
          });

          debugPrint('⭐ Öne çıkan tarif eklendi: ${translated['title']}');
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('⚠️ Öne çıkan tarif eklenemedi: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('❌ Öne çıkan tarifler sync hatası: $e');
    }
  }

  /// Gemini ile tüm tarifi tek seferde Türkçeye çevir
  /// Başlık, açıklama, malzemeler ve yapılış hepsi çevrilir
  static Future<Map<String, dynamic>> _translateFullRecipe(
    GenerativeModel model, 
    Map<String, dynamic> meal,
  ) async {
    try {
      final ingredients = meal['ingredients'] as List<String>? ?? [];
      final ingredientsList = ingredients.map((e) => '- $e').join('\n');

      final prompt = '''Aşağıdaki yemek tarifini tamamen Türkçeye çevir.
Yanıtını tam olarak şu formatta ver, başka hiçbir şey ekleme:

BASLIK: [Türkçe yemek adı]
ACIKLAMA: [10-15 kelimelik çekici Türkçe açıklama]
MALZEMELER:
- [malzeme 1]
- [malzeme 2]
...
YAPILIS:
[Türkçe yapılış adımları]

---
Yemek adı: ${meal['title']}
Bölge: ${meal['area']}
Kategori: ${meal['category']}

Malzemeler:
$ingredientsList

Yapılış:
${meal['instructions']}''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Yanıtı parse et
      return _parseTranslationResponse(text, meal);
    } catch (e) {
      debugPrint('Tam çeviri hatası: $e');
      // Çeviri başarısız olursa orijinal veriyi döndür
      return {
        'title': meal['title'] ?? '',
        'description': '${meal['area'] ?? 'Dünya'} mutfağından lezzetli bir tarif',
        'ingredients': meal['ingredients'] ?? [],
        'instructions': meal['instructions'] ?? '',
      };
    }
  }

  /// Gemini yanıtını parse et
  static Map<String, dynamic> _parseTranslationResponse(
    String response, 
    Map<String, dynamic> originalMeal,
  ) {
    String title = originalMeal['title'] ?? '';
    String description = '${originalMeal['area'] ?? 'Dünya'} mutfağından lezzetli bir tarif';
    List<String> ingredients = List<String>.from(originalMeal['ingredients'] ?? []);
    String instructions = originalMeal['instructions'] ?? '';

    try {
      // BASLIK
      final titleMatch = RegExp(r'BASLIK:\s*(.+)', caseSensitive: false).firstMatch(response);
      if (titleMatch != null) {
        title = titleMatch.group(1)!.trim();
      }

      // ACIKLAMA
      final descMatch = RegExp(r'ACIKLAMA:\s*(.+)', caseSensitive: false).firstMatch(response);
      if (descMatch != null) {
        description = descMatch.group(1)!.trim();
      }

      // MALZEMELER
      final ingStart = response.indexOf(RegExp(r'MALZEMELER:', caseSensitive: false));
      final yapilisStart = response.indexOf(RegExp(r'YAPILIS:', caseSensitive: false));

      if (ingStart != -1 && yapilisStart != -1) {
        final ingSection = response.substring(ingStart, yapilisStart);
        final ingLines = ingSection
            .split('\n')
            .where((line) => line.trim().startsWith('-'))
            .map((line) => line.trim().substring(1).trim())
            .where((line) => line.isNotEmpty)
            .toList();
        if (ingLines.isNotEmpty) {
          ingredients = ingLines;
        }
      }

      // YAPILIS
      if (yapilisStart != -1) {
        final yapilisSection = response.substring(yapilisStart + 'YAPILIS:'.length).trim();
        if (yapilisSection.isNotEmpty) {
          instructions = yapilisSection;
        }
      }
    } catch (e) {
      debugPrint('Parse hatası: $e');
    }

    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
    };
  }

  /// Malzeme sayısına göre zorluk tahmin et
  static String _estimateDifficulty(List<String> ingredients) {
    if (ingredients.length <= 5) return 'Kolay';
    if (ingredients.length <= 10) return 'Orta';
    return 'Zor';
  }

  /// Talimat uzunluğuna göre süre tahmin et
  static String _estimateDuration(String instructions) {
    final wordCount = instructions.split(' ').length;
    if (wordCount < 80) return '20 dk';
    if (wordCount < 150) return '35 dk';
    if (wordCount < 250) return '50 dk';
    return '60+ dk';
  }

  /// Firebase'deki tüm tarifleri temizle (yeniden sync için)
  static Future<void> clearAllRecipes() async {
    final batch = _firestore.batch();
    
    final tarifler = await _firestore.collection('Tarifler').get();
    for (final doc in tarifler.docs) {
      batch.delete(doc.reference);
    }

    final oneCikan = await _firestore.collection('OneCikanTarifler').get();
    for (final doc in oneCikan.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    debugPrint('🗑️ Tüm tarifler temizlendi.');
  }

  /// Belirli bir tarifi Favoriler koleksiyonuna ekle (kullanıcı beğendiğinde)
  static Future<void> addToFavorites(Map<String, dynamic> recipeData) async {
    // Aynı tarif zaten favorilerde mi kontrol et
    final existing = await _firestore
        .collection('Favoriler')
        .where('title', isEqualTo: recipeData['title'])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      debugPrint('⚠️ Bu tarif zaten favorilerde: ${recipeData['title']}');
      return;
    }

    await _firestore.collection('Favoriler').add({
      ...recipeData,
      'isFavorite': true,
      'addedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('❤️ Tarif favorilere eklendi: ${recipeData['title']}');
  }

  /// Favorilerden tarif kaldır
  static Future<void> removeFromFavorites(String title) async {
    final docs = await _firestore
        .collection('Favoriler')
        .where('title', isEqualTo: title)
        .get();
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
    debugPrint('💔 Tarif favorilerden kaldırıldı: $title');
  }
}
