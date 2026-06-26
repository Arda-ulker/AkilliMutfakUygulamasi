import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/services/data_provider.dart';
import 'package:akilli_mutfak/services/firebase_sync_service.dart';
import 'package:akilli_mutfak/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _statusText = 'Hazırlanıyor...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    _loadEverything();
  }

  Future<void> _loadEverything() async {
    try {
      // Adım 1: Firebase sync (zaten veri varsa atlar)
      _updateStatus('Tarifler kontrol ediliyor...', 0.1);
      await FirebaseSyncService.syncRecipesToFirebase(perCategory: 3);
      
      _updateStatus('Öne çıkan tarifler kontrol ediliyor...', 0.3);
      await FirebaseSyncService.syncFeaturedRecipes(count: 5);

      // Adım 2: Mevcut kategori verilerini normalize et (İngilizce → Türkçe)
      _updateStatus('Kategoriler düzenleniyor...', 0.5);
      await FirebaseSyncService.normalizeCategories();

      // Adım 3: Tüm verileri hafızaya yükle (DataProvider) - normalize sonrası temiz yükle
      _updateStatus('Veriler yükleniyor...', 0.7);
      DataProvider.instance.resetCache(); // önceki cache'i temizle
      await DataProvider.instance.initialize();

      // Adım 3: Kısa bir bekleme (splash'ın görünmesi için)
      _updateStatus('Hazır! 🍽️', 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      // Ana sayfaya geç
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Splash hata: $e');
      // Hata olsa bile ana sayfaya geç
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  void _updateStatus(String text, double progress) {
    if (mounted) {
      setState(() {
        _statusText = text;
        _progress = progress;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / İkon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: kGreen,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: kGreen.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 48),
              ),

              const SizedBox(height: 28),

              // Uygulama adı
              const Text(
                'Akıllı Mutfak',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Yapay zeka destekli mutfak asistanınız',
                style: TextStyle(fontSize: 14, color: kTextGrey),
              ),

              const SizedBox(height: 48),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: kLightGreen,
                          valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _statusText,
                      style: const TextStyle(fontSize: 13, color: kTextGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
