import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/services/data_provider.dart';

class ListeScreen extends StatefulWidget {
  const ListeScreen({super.key});

  @override
  State<ListeScreen> createState() => _ListeScreenState();
}

class _ListeScreenState extends State<ListeScreen> {
  final _data = DataProvider.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  // Seçili (checked) malzemeleri tutan set
  final Set<String> _checkedItems = {};

  final List<String> kCategories = [
    'Tümü',
    'Zeytinyağlı',
    'Hafif',
    'Et',
    'Tavuk',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Seçili kategoriye göre tüm tariflerdeki malzemeleri çıkar
  /// Her malzemeyi hangi tariften geldiğiyle birlikte döndürür
  List<Map<String, String>> _getIngredients() {
    final selectedCategory = kCategories[_selectedCategoryIndex];
    final recipes = selectedCategory == 'Tümü'
        ? _data.tarifler
        : _data.tarifler
            .where((t) => t['category'] == selectedCategory)
            .toList();

    final List<Map<String, String>> ingredients = [];
    final Set<String> seen = {};

    for (final recipe in recipes) {
      final title = recipe['title']?.toString() ?? '';
      final ingList = List<String>.from(recipe['ingredients'] ?? []);
      for (final ing in ingList) {
        final normalized = ing.trim();
        if (normalized.isNotEmpty && !seen.contains(normalized.toLowerCase())) {
          seen.add(normalized.toLowerCase());
          ingredients.add({
            'ingredient': normalized,
            'recipe': title,
          });
        }
      }
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      return ingredients
          .where((item) =>
              item['ingredient']!.toLowerCase().contains(_searchQuery) ||
              item['recipe']!.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return ingredients;
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = _getIngredients();
    final checkedCount =
        ingredients.where((i) => _checkedItems.contains(i['ingredient'])).length;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            _buildHeader(ingredients.length, checkedCount),
            const SizedBox(height: 14),
            // ─── Search Bar ───
            _buildSearchBar(),
            const SizedBox(height: 16),
            // ─── Kategori Butonları ───
            _buildCategoryPills(),
            const SizedBox(height: 16),
            // ─── Malzeme Listesi ───
            Expanded(
              child: ingredients.isEmpty
                  ? _buildEmptyState()
                  : _buildIngredientList(ingredients),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalCount, int checkedCount) {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alışveriş Listem',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$checkedCount / $totalCount malzeme seçildi',
                  style: const TextStyle(fontSize: 12, color: kTextGrey),
                ),
              ],
            ),
          ),
          if (_checkedItems.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() => _checkedItems.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Tüm seçimler temizlendi'),
                    backgroundColor: Colors.grey,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Temizle',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Malzeme veya tarif adı ara...',
                  hintStyle:
                      const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: const Icon(Icons.close,
                              color: Color(0xFFAAAAAA), size: 18),
                        )
                      : null,
                  suffixIconConstraints:
                      const BoxConstraints(maxHeight: 20, maxWidth: 24),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = _selectedCategoryIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? kGreen : kCardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: sel
                        ? kGreen.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: sel ? 10 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                kCategories[i],
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              color: kTextGrey.withOpacity(0.4), size: 52),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? '"${_searchController.text}" için malzeme bulunamadı'
                : 'Bu kategoride malzeme yok',
            style: const TextStyle(fontSize: 14, color: kTextGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList(List<Map<String, String>> ingredients) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: ingredients.length,
      itemBuilder: (context, i) {
        final item = ingredients[i];
        final ingredient = item['ingredient']!;
        final recipeName = item['recipe']!;
        final isChecked = _checkedItems.contains(ingredient);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isChecked ? kLightGreen : kCardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isChecked ? 0.02 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (isChecked) {
                    _checkedItems.remove(ingredient);
                  } else {
                    _checkedItems.add(ingredient);
                  }
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isChecked ? kGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isChecked ? kGreen : const Color(0xFFCCCCCC),
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Malzeme bilgisi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ingredient,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isChecked
                                  ? kTextGrey
                                  : kTextDark,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: kTextGrey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recipeName,
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextGrey.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Sağdaki ikon
                    Icon(
                      isChecked
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isChecked ? kGreen : const Color(0xFFDDDDDD),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
