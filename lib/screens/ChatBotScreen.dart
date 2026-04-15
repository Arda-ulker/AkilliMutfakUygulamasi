import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart'; 
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

  static const String _apiKey = 'AIzaSyBH-jBycJUxYd5CaoeuAbjEsSAbCWBcrUM';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();

    // Gemini modelini system instruction ile başlat
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(
        '''Sen deneyimli ve yardımsever bir Türk mutfak asistanısın. Adın "AI Şef".
Görevin kullanıcılara yemek tarifleri, mutfak ipuçları ve malzeme önerileri sunmak.
Yanıt verirken şu kurallara uy:
- Her zaman Türkçe yanıt ver
- Kısa ve net ol, gereksiz açıklamalardan kaçın
- Samimi ve teşvik edici bir ton kullan
- Tarif verirken adım adım yönlendirme yap
- Malzeme miktarlarını belirt
- Pişirme sürelerini belirt
- Emoji kullan ama abartma'''
      ),
    );

    // Chat oturumu başlat
    _chat = _model.startChat();

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
      // Malzeme bağlamı varsa prompt'a ekle
      String prompt = userText;
      if (widget.categories.isNotEmpty) {
        prompt = """Kullanıcının elindeki malzemeler: ${widget.categories.join(', ')}
Bunları göz önünde bulundurarak yanıt ver.
Kullanıcı sorusu: "$userText"
Yalnızca mevcut malzemeleri kullanarak öneri sun.""";
      }

      final response = await _chat.sendMessage(Content.text(prompt));
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
      debugPrint('Gemini API Hatası: $e');
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