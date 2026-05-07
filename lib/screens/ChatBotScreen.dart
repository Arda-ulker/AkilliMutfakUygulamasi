import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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

  // Backend URL (10.0.2.2 is for Android Emulator, 127.0.0.1 for iOS/Desktop)
  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/chat';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/chat';
    return 'http://127.0.0.1:8000/chat';
  }

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
      // Arkauca (Backend) gönderilecek veriyi hazırla
      // Son soruyu göndereceğiz, geçmiş olarak da öncekileri
      List<Map<String, dynamic>> historyToSend = messages
          .take(messages.length - 1) // Son eklenen 'text': userText hariç hepsi
          .where((m) => m['text'] != '🤔 Düşünüyorum...')
          .toList();

      final requestBody = {
        'message': userText,
        'ingredients': widget.categories,
        'history': historyToSend.map((m) => {
          'text': m['text'],
          'isAI': m['isAI']
        }).toList(),
      };

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = data['response'];

        setState(() {
          messages.removeLast(); // "Düşünüyorum..." mesajını kaldır
          messages.add({
            'text': responseText ?? 'Üzgünüm, bir yanıt oluşturamadım. Tekrar deneyin.',
            'isAI': true,
          });
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Hatası: $e');
      setState(() {
        messages.removeLast(); // "Düşünüyorum..." mesajını kaldır
        messages.add({
          'text': '❌ Bir hata oluştu: ${e.toString().length > 200 ? '${e.toString().substring(0, 200)}...' : e.toString()}',
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
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: kGreen),
            SizedBox(width: 8),
            Text('AI Şef', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
                            ? Colors.black.withOpacity(0.05) 
                            : Colors.green.withOpacity(0.15),
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
                  color: Colors.black.withOpacity(0.05),
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