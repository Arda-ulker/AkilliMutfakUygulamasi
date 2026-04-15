import 'dart:convert';
import 'package:http/http.dart' as http;

/// TheMealDB API servisi - ücretsiz tarif veritabanı
class RecipeApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  /// Tüm kategorileri getir
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categories.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['categories'] ?? []);
    }
    throw Exception('Kategoriler yüklenemedi: ${response.statusCode}');
  }

  /// Kategoriye göre yemekleri getir (özet bilgi)
  static Future<List<Map<String, dynamic>>> fetchMealsByCategory(String category) async {
    final response = await http.get(Uri.parse('$_baseUrl/filter.php?c=$category'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['meals'] ?? []);
    }
    throw Exception('Yemekler yüklenemedi: ${response.statusCode}');
  }

  /// ID ile detaylı tarif getir
  static Future<Map<String, dynamic>?> fetchMealDetail(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/lookup.php?i=$id'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final meals = data['meals'] as List?;
      if (meals != null && meals.isNotEmpty) {
        return _parseMealDetail(meals[0]);
      }
    }
    return null;
  }

  /// Rastgele yemek getir
  static Future<Map<String, dynamic>?> fetchRandomMeal() async {
    final response = await http.get(Uri.parse('$_baseUrl/random.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final meals = data['meals'] as List?;
      if (meals != null && meals.isNotEmpty) {
        return _parseMealDetail(meals[0]);
      }
    }
    return null;
  }

  /// Birden fazla rastgele yemek getir
  static Future<List<Map<String, dynamic>>> fetchRandomMeals(int count) async {
    List<Map<String, dynamic>> meals = [];
    Set<String> seenIds = {};

    for (int i = 0; i < count + 5; i++) {
      // Fazla deneme yapmak için count+5
      if (meals.length >= count) break;
      try {
        final meal = await fetchRandomMeal();
        if (meal != null && !seenIds.contains(meal['idMeal'])) {
          seenIds.add(meal['idMeal']);
          meals.add(meal);
        }
      } catch (_) {
        continue;
      }
    }
    return meals;
  }

  /// İsme göre yemek ara
  static Future<List<Map<String, dynamic>>> searchMeals(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/search.php?s=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final meals = data['meals'] as List?;
      if (meals != null) {
        return meals.map((m) => _parseMealDetail(m)).toList();
      }
    }
    return [];
  }

  /// Bölgeye göre yemek getir (Turkish, Italian, vb.)
  static Future<List<Map<String, dynamic>>> fetchMealsByArea(String area) async {
    final response = await http.get(Uri.parse('$_baseUrl/filter.php?a=$area'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['meals'] ?? []);
    }
    return [];
  }

  /// Malzemeye göre yemek getir
  static Future<List<Map<String, dynamic>>> fetchMealsByIngredient(String ingredient) async {
    final response = await http.get(Uri.parse('$_baseUrl/filter.php?i=$ingredient'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['meals'] ?? []);
    }
    return [];
  }

  /// TheMealDB raw verisini uygulama formatına dönüştür
  static Map<String, dynamic> _parseMealDetail(Map<String, dynamic> raw) {
    // Malzemeleri ve ölçüleri topla
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = raw['strIngredient$i']?.toString().trim() ?? '';
      final measure = raw['strMeasure$i']?.toString().trim() ?? '';
      if (ingredient.isNotEmpty) {
        ingredients.add(measure.isNotEmpty ? '$measure $ingredient' : ingredient);
      }
    }

    return {
      'idMeal': raw['idMeal'] ?? '',
      'title': raw['strMeal'] ?? '',
      'category': raw['strCategory'] ?? '',
      'area': raw['strArea'] ?? '',
      'instructions': raw['strInstructions'] ?? '',
      'image': raw['strMealThumb'] ?? '',
      'tags': raw['strTags'] ?? '',
      'youtube': raw['strYoutube'] ?? '',
      'ingredients': ingredients,
      'source': raw['strSource'] ?? '',
    };
  }

  /// Kategori mapping: TheMealDB → Uygulama kategorileri
  static String mapToAppCategory(String mealCategory) {
    final mapping = {
      'Beef': 'Et',
      'Lamb': 'Et',
      'Pork': 'Et',
      'Goat': 'Et',
      'Chicken': 'Tavuk',
      'Seafood': 'Hafif',
      'Vegetarian': 'Zeytinyağlı',
      'Vegan': 'Zeytinyağlı',
      'Side': 'Hafif',
      'Starter': 'Hafif',
      'Breakfast': 'Hafif',
      'Dessert': 'Hafif',
      'Pasta': 'Hafif',
      'Miscellaneous': 'Hafif',
    };
    return mapping[mealCategory] ?? 'Hafif';
  }
}
