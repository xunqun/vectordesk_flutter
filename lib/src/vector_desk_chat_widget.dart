import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'vector_desk_client.dart';
import 'models.dart';

class VectorDeskChatWidget extends StatefulWidget {
  final String orgId;
  final String? personaId;
  final Color themeColor;
  final FirebaseOptions? firebaseOptions;
  final String? appName;

  const VectorDeskChatWidget({
    super.key,
    required this.orgId,
    this.personaId,
    this.themeColor = Colors.blue,
    this.firebaseOptions,
    this.appName,
  });

  @override
  State<VectorDeskChatWidget> createState() => _VectorDeskChatWidgetState();
}

class _VectorDeskChatWidgetState extends State<VectorDeskChatWidget> {
  late final VectorDeskClient _client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream<List<VectorDeskMessage>>? _messagesStream;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _client = VectorDeskClient(
      orgId: widget.orgId,
      personaId: widget.personaId,
    );
    _initClient();
  }

  Future<void> _initClient() async {
    // In a real app, options might be passed or default used
    await _client.initialize(
        options: widget.firebaseOptions, appName: widget.appName);
    if (mounted) {
      setState(() {
        _initialized = true;
        _messagesStream = _client.chatStream;
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    _client.sendMessage(_controller.text.trim());
    _controller.clear();
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Reverse scroll view
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<VectorDeskMessage>>(
            stream: _messagesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return const Center(child: Text('Start a conversation'));
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true, // Start from bottom
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return _buildMessageBubble(msg);
                },
              );
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(VectorDeskMessage msg) {
    final isUser = msg.sender == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? widget.themeColor : Colors.white70,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: msg.text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
                a: TextStyle(
                  color: isUser ? Colors.white : Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                code: TextStyle(
                  backgroundColor:
                      isUser ? Colors.white24 : Colors.grey.shade300,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: widget.themeColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
