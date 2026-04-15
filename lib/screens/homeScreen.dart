import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/screens/ChatBotScreen.dart';
import 'package:akilli_mutfak/screens/recipeDetailScreen.dart';
import 'package:akilli_mutfak/screens/favoriler_screen.dart';
import 'package:akilli_mutfak/screens/all_recipes_screen.dart';
import 'package:akilli_mutfak/screens/liste_screen.dart';
import 'package:akilli_mutfak/services/data_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
    int _selectedNav = 0;
    int _selectedCategoryIndex = 0;
    final List<String> categories = [];
    final TextEditingController _searchController = TextEditingController();
    String _searchQuery = '';

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
    final List<String> kCategories = ['Tümü', 'Zeytinyağlı', 'Hafif', 'Et', 'Tavuk'];

    // DataProvider'dan cache'lenmiş verilere erişim
    final _data = DataProvider.instance;

    List<Widget>get _pages => [
      _buildHomeContent(),
      const Center(child: Text('Keşfet Sayfası')),
      ChatScreen(categories:  categories),
      const FavorilerScreen(),
      const ListeScreen(),
    ]; 

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: kBg,
            bottomNavigationBar:  _buildBottomNav(),
            body:SafeArea(
                child:_pages[_selectedNav],
            )
        );
    }

    Widget _buildHomeContent(){
      return Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildSearchBar(),
          Expanded(child: _searchQuery.isEmpty
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    _buildPreviousRecipesSection(),
                    const SizedBox(height: 20),
                    _buildFeaturedRecipesSection(),
                  ],
                ),
              )
            : _buildSearchResults(),
          )
        ],
      );  
    }

    Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded,        Icons.home_outlined,          'Ana Sayfa'),
      (Icons.explore_rounded,     Icons.explore_outlined,       'Keşfet'),
      (Icons.smart_toy_rounded,   Icons.smart_toy_outlined,     'AI Mutfak'),
      (Icons.favorite_rounded,    Icons.favorite_border_rounded,'Favoriler'),
      (Icons.list_alt_rounded,    Icons.list_alt_outlined,      'Liste'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = _selectedNav == i;
              final isCenterBtn = i == 2;
              if (isCenterBtn) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedNav = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: kGreen.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                );
              }
              return GestureDetector(
                onTap: () => setState(() => _selectedNav = i),
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? items[i].$1 : items[i].$2,
                        color: isSelected ? kGreen : kTextGrey,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$3,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? kGreen : kTextGrey,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

    Widget _buildHeader(){
      return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Akıllı Mutfak',
               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
               Text('Bugün ne pişirelim?', style: TextStyle(fontSize: 12, color: kTextGrey)),
            ],
          ),        
          const Spacer(),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDDDDDD),
            child: const Icon(Icons.person, color: Colors.grey),
          )
        ],        
      ),
    );
  }

  Widget _buildSearchBar(){
   return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:Container(
        height: 48,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color:  Color(0xFFAAAAAA), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tarif, malzeme veya kategori ara',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: const Icon(Icons.close, color: Color(0xFFAAAAAA), size: 18),
                      )
                    : null,
                  suffixIconConstraints: const BoxConstraints(maxHeight: 20, maxWidth: 24),
                  ),
                ),
              ),
              _searchBtn(Icons.mic),
              _searchBtn(Icons.tune, right: 6),
            ],
          ),
        )
      );
    }

    /// ─── Arama Sonuçları ───
    Widget _buildSearchResults() {
      // Tüm tarifleri birleştir (tarifler + öne çıkanlar)
      final allRecipes = <Map<String, dynamic>>[
        ..._data.tarifler,
        ..._data.oneCikanTarifler,
      ];

      // Arama filtresi: title, category, subtitle alanlarında arama
      final results = allRecipes.where((recipe) {
        final title = (recipe['title'] ?? '').toString().toLowerCase();
        final category = (recipe['category'] ?? '').toString().toLowerCase();
        final subtitle = (recipe['subtitle'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery) ||
               category.contains(_searchQuery) ||
               subtitle.contains(_searchQuery);
      }).toList();

      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, color: kTextGrey.withOpacity(0.5), size: 48),
              const SizedBox(height: 12),
              Text(
                '"${_searchController.text}" için sonuç bulunamadı',
                style: const TextStyle(fontSize: 14, color: kTextGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: results.length,
        itemBuilder: (context, i) {
          final recipe = results[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipeData: recipe),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      recipe['image'] ?? '',
                      width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: kLightGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant, color: kGreen, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['title'] ?? 'Tarif',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (recipe['category'] != null) recipe['category'],
                            if (recipe['duration'] != null) recipe['duration'],
                            if (recipe['difficulty'] != null) recipe['difficulty'],
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: kTextGrey, size: 22),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget _searchBtn(IconData icon, {double right = 0}){
      return Container(
        margin: EdgeInsets.fromLTRB(4,6, right, 6),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          
          borderRadius: BorderRadius.circular(9),  
        ),
      );
    }

    Widget _buildCategorySection(){
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Nasıl Bir Yemek Yapalım?', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color:kTextDark,letterSpacing: -0.2)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel= _selectedCategoryIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kGreen : kCardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow:[
                          BoxShadow(
                            color: sel ? kGreen.withOpacity(0.3) : Colors.black.withOpacity(0.05), 
                            blurRadius: sel ? 10 : 4, 
                            offset: const Offset(0, 3)
                          )
                        ]
                      ),
                      child: Text(
                        kCategories[i], 
                        style: TextStyle(fontSize: 13, 
                        color: sel ? Colors.white : kTextGrey,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal
                        )),
                    ),
                  );
                },
              ),
            )
          ],
        );
    }
    Widget _buildPreviousRecipesSection(){
        final selectedCategory = kCategories[_selectedCategoryIndex];
        final recipes = _data.getTariflerByCategory(selectedCategory);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:const EdgeInsets.symmetric(horizontal:16),
              child:Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tarifler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllRecipesScreen(
                            initialCategory: kCategories[_selectedCategoryIndex],
                          ),
                        ),
                      );
                    },
                    child: const Text('Tümünü Gör',
                      style: TextStyle(fontSize: 13, color: kGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 165,
              child: recipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, color: kTextGrey, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          selectedCategory == 'Tümü'
                            ? 'Henüz tarif yok.\nYenilemek için ↻ butonuna basın.'
                            : '"$selectedCategory" kategorisinde tarif bulunamadı.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: kTextGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recipes.length,
                    itemBuilder: (context, i){
                      final recipeData = recipes[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(recipeData: recipeData),
                            ),
                          );
                        },
                        child: _buildRecipeCard(recipeData),
                      );
                    }
                  ),
            )
          ],
        );
      }

  Widget _buildRecipeCard(Map<String, dynamic> recipeData) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  recipeData['image'] ?? 'https://via.placeholder.com/150', 
                  height: 95, width: 140, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 95, width: 140, color: const Color(0xFFEEEEEE),
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              ),
              if (recipeData['isFavorite'] == true) 
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite, color: Colors.red, size: 14),
                  ),
                ),
              // Kategori badge
              if (recipeData['category'] != null)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipeData['category'],
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child:Text(recipeData['title'] ?? 'Tarif Adı',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,color:kTextDark), 
            maxLines: 1, overflow: TextOverflow.ellipsis)
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8,2, 8, 0),
            child:Text('${recipeData['duration'] ?? ''} ${recipeData['difficulty'] != null ? '• ${recipeData['difficulty']}' : ''}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400,color:kTextGrey), 
            maxLines: 1, overflow: TextOverflow.ellipsis,
            )
          )
        ],
      ),
    );
  }

    /// ─── Öne Çıkan Tarifler (CACHE'den okuyor, StreamBuilder YOK) ───
    Widget _buildFeaturedRecipesSection(){
        final featured = _data.oneCikanTarifler;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Öne Çıkan Tarifler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            featured.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Henüz öne çıkan tarif yok.', 
                      style: TextStyle(color: kTextGrey)),
                  ),
                )
              : Column(
                  children: featured.map((data) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(recipeData: data),
                          ),
                        );
                      },
                      child: _buildFeaturedCard(data),
                    );
                  }).toList(),
                ),
          ],
        );
      }

    Widget _buildFeaturedCard(Map<String, dynamic> recipeData){
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: double.infinity,
            height: 160,
            child: Stack(
              fit:StackFit.expand,
              children: [
                Image.network(
                  recipeData['image'] ?? 'https://via.placeholder.com/300x120', 
                  width: double.infinity, height: 120, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity, height: 120, color: const Color(0xFFEEEEEE),
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
                Container(
                  decoration:BoxDecoration(
                    gradient:LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.72),
                      ],
                      stops: const [0.3, 1.0],
                    ), 
                  )  
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 60,
                  child:Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if(recipeData['isAddedToFavorites'] == true)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kGreen, 
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Akıllı Ekleme",
                            style: TextStyle(color: Colors.white, fontSize: 10,fontWeight: FontWeight.bold,letterSpacing: 0.5),
                          ),
                        ),
                      Text(
                        recipeData['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2)
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recipeData['subtitle'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  ),
                  Positioned(
                    right: 12,
                    bottom:12, 
                    child:Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bookmark_border, color: Colors.white, size: 18),
                    ) 
                  ) 
              ],
            ),
          ),
        ),
      );
    }
}    