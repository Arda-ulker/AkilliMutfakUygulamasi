import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/services/data_provider.dart';
import 'package:akilli_mutfak/services/firebase_sync_service.dart';
import 'package:akilli_mutfak/screens/recipe_detail_screen.dart';

class FavorilerScreen extends StatefulWidget {
  const FavorilerScreen({super.key});
  @override
  State<FavorilerScreen> createState() => _FavorilerScreenState();
}

class _FavorilerScreenState extends State<FavorilerScreen> {
  List<Map<String, dynamic>> get _favoriler => DataProvider.instance.favoriler;

  Future<void> _removeFavorite(int index) async {
    final recipe = _favoriler[index];
    final title = recipe['title'] ?? '';

    await FirebaseSyncService.removeFromFavorites(title);
    DataProvider.instance.removeFromFavorilerCache(title);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💔 "$title" favorilerden kaldırıldı'),
          backgroundColor: Colors.grey[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: kBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emir Hocanın Spesyalleri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_favoriler.length} tarif kaydedildi',
                    style: const TextStyle(fontSize: 12, color: kTextGrey),
                  ),
                ],
              ),
            ],
          ),
        ),

        // İçerik
        Expanded(
          child: _favoriler.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _favoriler.length,
                  itemBuilder: (context, index) {
                    final recipe = _favoriler[index];
                    return _buildFavoriteCard(recipe, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Henüz favori tarifin yok',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Beğendiğin tariflerde ❤️ butonuna basarak\nburaya ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextGrey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> recipe, int index) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeData: recipe),
          ),
        );
        // Detay ekranından döndüğünde favori durumunu güncelle
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Resim
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                recipe['image'] ?? '',
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 110,
                  height: 110,
                  color: kLightGreen,
                  child: const Icon(Icons.restaurant, color: kGreen, size: 32),
                ),
              ),
            ),

            // Bilgiler
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'] ?? 'Tarif',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (recipe['description'] != null)
                      Text(
                        recipe['description'],
                        style: const TextStyle(fontSize: 12, color: kTextGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (recipe['duration'] != null) ...[
                          const Icon(Icons.timer_outlined, size: 14, color: kGreen),
                          const SizedBox(width: 4),
                          Text(
                            recipe['duration'],
                            style: const TextStyle(fontSize: 11, color: kTextGrey),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (recipe['difficulty'] != null) ...[
                          const Icon(Icons.signal_cellular_alt, size: 14, color: kGreen),
                          const SizedBox(width: 4),
                          Text(
                            recipe['difficulty'],
                            style: const TextStyle(fontSize: 11, color: kTextGrey),
                          ),
                        ],
                        if (recipe['category'] != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kLightGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              recipe['category'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sil butonu
            GestureDetector(
              onTap: () => _removeFavorite(index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
