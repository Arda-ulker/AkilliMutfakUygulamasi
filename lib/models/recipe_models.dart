class Recipemodels {
  final String title, duration, difficulty, imageUrl;
  final String? description, category, area, instructions, originalTitle, mealDbId, source;
  final List<String> ingredients;
  final bool isFavorite;

  const Recipemodels({
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.imageUrl,
    this.description,
    this.category,
    this.area,
    this.instructions,
    this.originalTitle,
    this.mealDbId,
    this.source,
    this.ingredients = const [],
    this.isFavorite = false,
  });

  factory Recipemodels.fromFireStore(Map<String, dynamic> data) {
    return Recipemodels(
      title: data['title'] ?? '',
      duration: data['duration'] ?? '',
      difficulty: data['difficulty'] ?? '',
      imageUrl: data['image'] ?? data['imageUrl'] ?? '',
      description: data['description'],
      category: data['category'],
      area: data['area'],
      instructions: data['instructions'],
      originalTitle: data['originalTitle'],
      mealDbId: data['mealDbId'],
      source: data['source'],
      ingredients: List<String>.from(data['ingredients'] ?? []),
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'duration': duration,
      'difficulty': difficulty,
      'image': imageUrl,
      'description': description,
      'category': category,
      'area': area,
      'instructions': instructions,
      'originalTitle': originalTitle,
      'mealDbId': mealDbId,
      'source': source,
      'ingredients': ingredients,
      'isFavorite': isFavorite,
    };
  }
}

class FeaturedRecipeCardData {
  final String title, subtitle, imageUrl;
  final String? category, mealDbId;
  final List<String> ingredients;
  final bool isAkilliEkleme;

  const FeaturedRecipeCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.category,
    this.mealDbId,
    this.ingredients = const [],
    this.isAkilliEkleme = false,
  });

  factory FeaturedRecipeCardData.fromFireStore(Map<String, dynamic> data) {
    return FeaturedRecipeCardData(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      imageUrl: data['image'] ?? data['imageUrl'] ?? '',
      category: data['category'],
      mealDbId: data['mealDbId'],
      ingredients: List<String>.from(data['ingredients'] ?? []),
      isAkilliEkleme: data['isAddedToFavorites'] ?? data['isAkilliEkleme'] ?? false,
    );
  }
}