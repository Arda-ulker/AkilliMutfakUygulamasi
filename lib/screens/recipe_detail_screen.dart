import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/services/firebase_sync_service.dart';
import 'package:akilli_mutfak/services/data_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;
  const RecipeDetailScreen({super.key, required this.recipeData});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    // Cache'den favori durumunu kontrol et
    _isFavorite = DataProvider.instance.isFavorite(widget.recipeData['title'] ?? '');
  }

  Future<void> _toggleFavorite() async {
    final title = widget.recipeData['title'] ?? '';

    if (_isFavorite) {
      // Favoriden kaldır
      await FirebaseSyncService.removeFromFavorites(title);
      DataProvider.instance.removeFromFavorilerCache(title);
      setState(() => _isFavorite = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💔 Favorilerden kaldırıldı'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Favoriye ekle
      await FirebaseSyncService.addToFavorites(widget.recipeData);
      DataProvider.instance.addToFavorilerCache(widget.recipeData);
      setState(() => _isFavorite = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❤️ Favorilere eklendi!'),
            backgroundColor: kGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = List<String>.from(widget.recipeData['ingredients'] ?? []);

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // Üst resim ve başlık
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: kGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Favori butonu
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipeData['title'] ?? 'Tarif',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.recipeData['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: kLightGreen,
                      child: const Icon(Icons.restaurant, size: 60, color: kGreen),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgi kartları
                  Row(
                    children: [
                      _infoChip(Icons.timer, widget.recipeData['duration'] ?? '—'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.signal_cellular_alt, widget.recipeData['difficulty'] ?? '—'),
                      const SizedBox(width: 8),
                      if (widget.recipeData['category'] != null)
                        _infoChip(Icons.category, widget.recipeData['category']),
                    ],
                  ),

                  if (widget.recipeData['description'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.recipeData['description'],
                      style: const TextStyle(fontSize: 14, color: kTextGrey, height: 1.5),
                    ),
                  ],

                  // Malzemeler
                  if (ingredients.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      '🧂 Malzemeler',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: ingredients.map((ing) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: kGreen, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ing,
                                  style: const TextStyle(fontSize: 14, color: kTextDark),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],

                  // Yapılışı
                  if (widget.recipeData['instructions'] != null && 
                      widget.recipeData['instructions'].toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      '👨‍🍳 Yapılışı',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.recipeData['instructions'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextDark,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kLightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kGreen, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}
