import 'package:flutter/material.dart';
import 'package:akilli_mutfak/screens/splash_screen.dart';
import 'package:akilli_mutfak/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Tüm veri yükleme işlemleri artık SplashScreen'de yapılıyor.
  // DataProvider.initialize() splash'ta çağrılıyor.
  runApp(const AkilliMutfakApp());
}

class AkilliMutfakApp extends StatelessWidget {
  const AkilliMutfakApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akıllı Mutfak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3DBA4E)),
      ),
      home: const SplashScreen(),
    );
  }
}
