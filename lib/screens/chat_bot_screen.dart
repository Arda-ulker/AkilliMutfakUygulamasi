import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'dart:io' show SocketException;
import 'dart:async';
import 'package:akilli_mutfak/services/data_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  final bool askForIngredients; 
  final List<String> categories;
  const ChatScreen({super.key, this.askForIngredients = false, required this.categories});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;

  // Cihaz üzerinden doğrudan Gemini API bağlantısı kurulmuştur (Backend gerekmez).

  @override
  void initState() {
    super.initState();

    if (widget.askForIngredients) {
      messages.add({
        'text': '🍳 Elinizde hangi malzemeler var? Söyleyin, size harika bir tarif çıkarayım!',
        'isAI': true, 
      });
    } else {
      messages.add({
        'text': '👨‍🍳 Merhaba! Ben AI Şef. Bugün mutfakta size nasıl yardımcı olabilirim?',
        'isAI': true,
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final userText = _messageController.text.trim();
    if (userText.isEmpty || _isLoading) return;

    setState(() {
      messages.add({'text': userText, 'isAI': false});
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    setState(() {
      messages.add({'text': '🤔 Düşünüyorum...', 'isAI': true});
    });
    _scrollToBottom();

    try {
      if (!DataProvider.instance.isGeminiReady) {
        throw Exception('AI Şef hazır değil. Lütfen lib/constants/api_keys.dart dosyasına geçerli bir Gemini API anahtarı eklediğinizden emin olun.');
      }

      // Geçmiş mesajları al (Düşünüyorum hariç)
      List<Map<String, dynamic>> historyToSend = messages
          .take(messages.length - 1)
          .where((m) => m['text'] != '🤔 Düşünüyorum...')
          .toList();

      // Gemini için konuşma geçmişini (history) oluştur
      final List<Content> chatHistory = [];
      for (final msg in historyToSend) {
        final text = msg['text'] as String;
        final isAI = msg['isAI'] as bool;
        
        chatHistory.add(
          isAI ? Content.model([TextPart(text)]) : Content.text(text)
        );
      }

      // Gemini chat'ini başlat ve mesajı gönder
      final chat = DataProvider.instance.geminiModel.startChat(history: chatHistory);
      
      // Eğer kullanıcının elindeki malzemeler (widget.categories) varsa, prompt'a ek bir bağlam ekleyebiliriz
      String prompt = userText;
      if (widget.askForIngredients && widget.categories.isNotEmpty && historyToSend.length <= 1) {
        prompt = "Elimdeki malzemeler şunlar: ${widget.categories.join(', ')}. Bu malzemelerle ne yapabilirim? Soruma cevap ver: $userText";
      }

      final response = await chat.sendMessage(Content.text(prompt));
      final responseText = response.text;

      setState(() {
        messages.removeLast(); // "Düşünüyorum..." mesajını kaldır
        messages.add({
          'text': responseText ?? 'Üzgünüm, bir yanıt oluşturamadım. Tekrar deneyin.',
          'isAI': true,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('API Hatası: $e');
      String errorMessage = '❌ Bir hata oluştu: $e';
      
      if (e.toString().contains('API_KEY_INVALID') || e.toString().contains('API key not found')) {
        errorMessage = '❌ Geçersiz API Anahtarı! Lütfen lib/constants/api_keys.dart dosyasındaki Gemini API anahtarınızı kontrol edin.';
      } else if (e is SocketException) {
        errorMessage = '❌ İnternet bağlantısı kurulamadı. Lütfen internetinizi kontrol edin.';
      } else if (e.toString().contains('503') || e.toString().contains('high demand') || e.toString().contains('UNAVAILABLE')) {
        errorMessage = '🤖 Yapay zeka sunucuları şu an çok yoğun. Lütfen 1-2 dakika bekleyip tekrar deneyin.';
      }
      
      setState(() {
        messages.removeLast(); // "Düşünüyorum..." mesajını kaldır
        messages.add({
          'text': errorMessage,
          'isAI': true,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg, 
      appBar: AppBar( 
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: kLightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: kGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text('AI Şef', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isAI = message['isAI'] as bool;
                return Align(
                  alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isAI ? Colors.white : kGreen,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: Radius.circular(isAI ? 0 : 16),
                        bottomRight: Radius.circular(isAI ? 16 : 0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAI 
                            ? Colors.black.withValues(alpha: 0.05) 
                            : Colors.green.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: SelectableText(
                      message['text'],
                      style: TextStyle(
                        color: isAI ? kTextDark : Colors.white, 
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => sendMessage(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Yapay zekaya sorun...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey[100],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : kGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isLoading ? Icons.hourglass_top : Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}