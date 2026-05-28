import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});
  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}
class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  bool _isFeatured = false; 
  bool _isLoading = false;  
  Future<void> _saveRecipeToFirebase() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('recipes').add({
        'title': _titleController.text.trim(),
        'duration': _durationController.text.trim(),
        'difficulty': _difficultyController.text.trim(),
        'imageUrl': _imageController.text.trim().isEmpty 
            ? 'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=300' // Boşsa varsayılan resim
            : _imageController.text.trim(),
        'isFavorite': false,
        'isAkilliEkleme': _isFeatured,
        'subtitle': _isFeatured ? 'Yeni Tarif' : '',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Hata oluştu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yeni Tarif Ekle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Geri butonu rengi
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _titleController, label: 'Yemek Adı (Örn: Sütlaç)'),
            const SizedBox(height: 12),
            _buildTextField(controller: _durationController, label: 'Süre (Örn: 45 dk)'),
            const SizedBox(height: 12),
            _buildTextField(controller: _difficultyController, label: 'Zorluk (Örn: Kolay)'),
            const SizedBox(height: 12),
            _buildTextField(controller: _imageController, label: 'Resim URL (İnternetten link kopya)'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Öne Çıkanlara Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
              activeThumbColor: Colors.green,
              value: _isFeatured,
              onChanged: (val) => setState(() => _isFeatured = val),
            ),
            
            const SizedBox(height: 24),
            
            // Kaydet Butonu
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecipeToFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Tarifi Buluta Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Tasarımı temiz tutmak için kendi TextField widget'ımızı oluşturduk
  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}