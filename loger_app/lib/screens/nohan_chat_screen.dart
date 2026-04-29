import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';
import 'property_detail_screen.dart';

class NohanChatScreen extends StatefulWidget {
  const NohanChatScreen({super.key});

  @override
  State<NohanChatScreen> createState() => _NohanChatScreenState();
}

class _NohanChatScreenState extends State<NohanChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': 'Bonjour ! Je suis Nohan, votre assistant intelligent. Comment puis-je vous aider dans votre recherche immobilière aujourd\'hui ?'
    }
  ];
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final response = await _apiService.chatWithNohan(text, _messages.map((m) => {
      'role': m['role'] == 'assistant' ? 'model' : 'user',
      'parts': [{'text': m['content']}]
    }).toList());

    setState(() {
      _isTyping = false;
      if (response != null && response['response'] != null) {
        _messages.add({'role': 'assistant', 'content': response['response']});
      } else {
        _messages.add({'role': 'assistant', 'content': 'Désolé, je rencontre une petite difficulté technique. Réessayez dans un instant.'});
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF5C42F).withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.psychology_outlined, color: Color(0xFF0B4629), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Nohan AI', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildBubble(msg);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FadeIn(child: const Text('Nohan réfléchit...', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    bool isAi = msg['role'] == 'assistant';
    String content = msg['content'];
    
    // Parse property cards if present
    List<Widget> children = [];
    
    if (isAi) {
      final regExp = RegExp(r'\[PROPERTY_CARD:(.*?)\]');
      final matches = regExp.allMatches(content);
      
      if (matches.isNotEmpty) {
        // Text before cards
        String textPart = content.split('[PROPERTY_CARD:').first.trim();
        if (textPart.isNotEmpty) {
          children.add(_buildTextBubble(textPart, isAi));
        }
        
        // The cards
        for (final match in matches) {
          try {
            final jsonStr = match.group(1)?.replaceAll('&quot;', '"');
            if (jsonStr != null) {
              final cardData = json.decode(jsonStr);
              children.add(_buildPropertyCard(cardData));
            }
          } catch (e) {
            debugPrint('Error parsing property card: $e');
          }
        }
      } else {
        children.add(_buildTextBubble(content, isAi));
      }
    } else {
      children.add(_buildTextBubble(content, isAi));
    }

    return Column(
      crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: children,
    );
  }

  Widget _buildTextBubble(String text, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: FadeInUp(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: isAi ? const Color(0xFFF1F5F9) : const Color(0xFF0B4629),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isAi ? 0 : 20),
              bottomRight: Radius.circular(isAi ? 20 : 0),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isAi ? Colors.black87 : Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> data) {
    return FadeInRight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 10),
        width: MediaQuery.of(context).size.width * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                data['image'] ?? '',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, height: 140, child: const Icon(Icons.image_not_supported)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${data['price']} F', style: const TextStyle(color: Color(0xFF0B4629), fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final propertyId = data['id'];
                        if (propertyId != null) {
                          // Afficher un loader
                          showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFDAA520))));
                          final p = await _apiService.fetchProperty(propertyId.toString());
                          if (mounted) Navigator.pop(context); // Fermer loader
                          
                          if (p != null && mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (c) => PropertyDetailScreen(property: p)));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4629),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Voir le bien', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Posez votre question...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFDAA520), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
