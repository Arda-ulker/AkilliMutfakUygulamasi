import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/models/shopping_item.dart';
import 'package:akilli_mutfak/services/data_provider.dart';

class TumUrunlerScreen extends StatefulWidget {
  /// Ürüne tıklandığında çağrılır; ürünü alışveriş listesine ekler.
  final void Function(String name, String source) onAddItem;

  /// ListeScreen'deki mevcut ürün adları — açılışta "zaten listede" göstermek için.
  final Set<String> initialAddedNames;

  const TumUrunlerScreen({
    super.key,
    required this.onAddItem,
    this.initialAddedNames = const {},
  });

  @override
  State<TumUrunlerScreen> createState() => _TumUrunlerScreenState();
}

class _TumUrunlerScreenState extends State<TumUrunlerScreen> {
  final _data = DataProvider.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  bool _isGroupedByAisle = false;

  /// Bu oturumda listeye eklenen ürünler (küçük harf anahtar).
  late final Set<String> _addedToList;

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
    _addedToList = Set<String>.from(widget.initialAddedNames);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Veri ────────────────────────────────────────────────────────────────

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
        if (normalized.isNotEmpty &&
            !seen.contains(normalized.toLowerCase())) {
          seen.add(normalized.toLowerCase());
          ingredients.add({'ingredient': normalized, 'recipe': title});
        }
      }
    }

    if (_searchQuery.isNotEmpty) {
      return ingredients
          .where((item) =>
              item['ingredient']!.toLowerCase().contains(_searchQuery) ||
              item['recipe']!.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return ingredients;
  }

  Map<String, List<Map<String, String>>> _groupByAisle(
      List<Map<String, String>> ingredients) {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (final item in ingredients) {
      grouped
          .putIfAbsent(getAisle(item['ingredient']!), () => [])
          .add(item);
    }
    final Map<String, List<Map<String, String>>> ordered = {};
    for (final aisle in kAisleOrder) {
      if (grouped.containsKey(aisle)) ordered[aisle] = grouped[aisle]!;
    }
    return ordered;
  }

  bool _isAdded(String name) => _addedToList.contains(name.toLowerCase());

  void _handleTap(String name, String recipe) {
    if (_isAdded(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" zaten listenizde'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          backgroundColor: kTextGrey,
        ),
      );
      return;
    }
    widget.onAddItem(name, recipe);
    setState(() => _addedToList.add(name.toLowerCase()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"$name" alışveriş listesine eklendi',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kGreen,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ingredients = _getIngredients();
    final addedCount = _addedToList.length;

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(ingredients.length, addedCount),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCategoryPills(),
          const SizedBox(height: 12),
          Expanded(
            child: ingredients.isEmpty
                ? _buildEmptyState()
                : _isGroupedByAisle
                    ? _buildGroupedList(ingredients)
                    : _buildFlatList(ingredients),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int total, int addedCount) {
    return AppBar(
      backgroundColor: kCardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: kTextDark),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tüm Ürünler',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextDark),
          ),
          Text(
            addedCount == 0
                ? '$total malzeme — eklemek için ürüne dokun'
                : '$addedCount ürün listene eklendi',
            style: const TextStyle(fontSize: 11, color: kTextGrey),
          ),
        ],
      ),
      actions: [
        // Reyona göre toggle
        GestureDetector(
          onTap: () =>
              setState(() => _isGroupedByAisle = !_isGroupedByAisle),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.fromLTRB(0, 10, 14, 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isGroupedByAisle
                  ? kGreen.withValues(alpha: 0.12)
                  : kBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isGroupedByAisle
                    ? kGreen
                    : const Color(0xFFDDDDDD),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store_mall_directory_rounded,
                    size: 14,
                    color: _isGroupedByAisle ? kGreen : kTextGrey),
                const SizedBox(width: 4),
                Text(
                  'Reyon',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isGroupedByAisle ? kGreen : kTextGrey,
                    fontWeight: _isGroupedByAisle
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: kGreen.withValues(alpha: 0.09),
                blurRadius: 10,
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
                  hintStyle: const TextStyle(
                      fontSize: 14, color: Color(0xFFAAAAAA)),
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
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = _selectedCategoryIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? kGreen : kCardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: sel
                        ? kGreen.withValues(alpha: 0.3)
                        : kGreen.withValues(alpha: 0.07),
                    blurRadius: sel ? 10 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                kCategories[i],
                style: TextStyle(
                  fontSize: 12,
                  color: sel ? Colors.white : kTextGrey,
                  fontWeight:
                      sel ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Düz Liste ────────────────────────────────────────────────────────────

  Widget _buildFlatList(List<Map<String, String>> ingredients) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: ingredients.length,
      itemBuilder: (_, i) {
        final item = ingredients[i];
        return _buildIngredientTile(
          item['ingredient']!,
          item['recipe']!,
        );
      },
    );
  }

  // ─── Reyona Göre Gruplu Liste ─────────────────────────────────────────────

  Widget _buildGroupedList(List<Map<String, String>> ingredients) {
    final grouped = _groupByAisle(ingredients);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: grouped.length,
      itemBuilder: (_, sectionIdx) {
        final aisle = grouped.keys.elementAt(sectionIdx);
        final items = grouped[aisle]!;
        final sectionAdded =
            items.where((i) => _isAdded(i['ingredient']!)).length;
        final allDone = sectionAdded == items.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: kGreen.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: !allDone,
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 2),
              childrenPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Text(
                    aisle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: allDone ? kTextGrey : kTextDark,
                      decoration: allDone
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: kTextGrey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: allDone
                          ? kGreen.withValues(alpha: 0.15)
                          : kBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$sectionAdded / ${items.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: allDone ? kGreen : kTextGrey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isLast = i == items.length - 1;
                return Column(
                  children: [
                    const Divider(
                        height: 1, indent: 14, endIndent: 14),
                    _buildIngredientTile(
                      item['ingredient']!,
                      item['recipe']!,
                      isLast: isLast,
                      inGroup: true,
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ─── Ortak Tile ───────────────────────────────────────────────────────────

  Widget _buildIngredientTile(
    String name,
    String recipe, {
    bool isLast = false,
    bool inGroup = false,
  }) {
    final added = _isAdded(name);
    final radius = (inGroup && isLast)
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : (inGroup ? BorderRadius.zero : BorderRadius.circular(14));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin:
          inGroup ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: added
            ? kLightGreen
            : (inGroup ? Colors.transparent : kCardBg),
        borderRadius: radius,
        boxShadow: inGroup
            ? null
            : [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: added ? 0.02 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: () => _handleTap(name, recipe),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: inGroup ? 11 : 13,
            ),
            child: Row(
              children: [
                // Sol ikon: + ekle / ✓ eklendi
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: added
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('check'),
                          color: kGreen,
                          size: 24,
                        )
                      : const Icon(
                          Icons.add_circle_outline_rounded,
                          key: ValueKey('add'),
                          color: Color(0xFFCCCCCC),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                // İsim + kaynak tarif
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: added ? kTextGrey : kTextDark,
                          decoration: added
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: kTextGrey,
                        ),
                      ),
                      Text(
                        recipe,
                        style: TextStyle(
                          fontSize: 11,
                          color: kTextGrey.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Sağ badge
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: added
                      ? Container(
                          key: const ValueKey('badge_added'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Listede',
                            style: TextStyle(
                              fontSize: 10,
                              color: kGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('badge_empty')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              color: kTextGrey.withValues(alpha: 0.4), size: 52),
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
}
