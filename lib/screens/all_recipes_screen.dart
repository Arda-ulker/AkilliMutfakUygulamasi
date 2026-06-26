import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/services/data_provider.dart';
import 'package:akilli_mutfak/screens/recipe_detail_screen.dart';

class AllRecipesScreen extends StatefulWidget {
  final String initialCategory;
  const AllRecipesScreen({super.key, this.initialCategory = 'Tümü'});

  @override
  State<AllRecipesScreen> createState() => _AllRecipesScreenState();
}

class _AllRecipesScreenState extends State<AllRecipesScreen> {
  final _data = DataProvider.instance;
  final List<String> _categories = ['Tümü', 'Zeytinyağlı', 'Hafif', 'Et', 'Tavuk'];
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _categories.indexOf(widget.initialCategory);
    if (_selectedIndex < 0) _selectedIndex = 0;
  }

  List<Map<String, dynamic>> get _filteredRecipes =>
      _data.getTariflerByCategory(_categories[_selectedIndex]);

  @override
  Widget build(BuildContext context) {
    final recipes = _filteredRecipes;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Tüm Tarifler',
          style: TextStyle(color: kTextDark, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        iconTheme: const IconThemeData(color: kTextDark),
      ),
      body: Column(
        children: [
          // Kategori filtreleri
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _selectedIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? kGreen : kBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: sel
                            ? [BoxShadow(color: kGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: Text(
                        _categories[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: sel ? Colors.white : kTextGrey,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Sonuç sayısı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${recipes.length} tarif bulundu',
                  style: const TextStyle(fontSize: 13, color: kTextGrey),
                ),
              ],
            ),
          ),

          // Grid tarif listesi
          Expanded(
            child: recipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          '"${_categories[_selectedIndex]}" kategorisinde tarif yok',
                          style: const TextStyle(fontSize: 14, color: kTextGrey),
                        ),
                        ],
                    ),
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      return _buildGridCard(recipes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> recipe) {
    final isFav = DataProvider.instance.isFavorite(recipe['title'] ?? '');
    final heroTag = 'recipe_all_${recipe['title']}';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 320),
            pageBuilder: (_, animation, secondaryAnimation) =>
                RecipeDetailScreen(recipeData: recipe, heroTag: heroTag),
            transitionsBuilder: (_, animation, secondaryAnimation, child) => FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            ),
          ),
        );
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kGreen.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(
                        recipe['image'] ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: kLightGreen,
                          child: const Center(
                            child: Icon(Icons.restaurant, color: kGreen, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Kategori badge
                  if (recipe['category'] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kGreen.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe['category'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Favori ikonu
                  if (isFav)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                      ),
                    ),
                ],
              ),
            ),

            // Bilgiler
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'] ?? 'Tarif',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (recipe['duration'] != null) ...[
                          const Icon(Icons.timer_outlined, size: 13, color: kGreen),
                          const SizedBox(width: 3),
                          Text(
                            recipe['duration'],
                            style: const TextStyle(fontSize: 11, color: kTextGrey),
                          ),
                        ],
                        if (recipe['difficulty'] != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.signal_cellular_alt, size: 13, color: kGreen),
                          const SizedBox(width: 3),
                          Text(
                            recipe['difficulty'],
                            style: const TextStyle(fontSize: 11, color: kTextGrey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
