import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'vectordesk_client.dart';
import 'models.dart';
import 'localization.dart';

class VectorDeskChatWidget extends StatefulWidget {
  final String orgId;
  final String? personaId;
  final String? greetingMessage;
  final List<String>? quickReplies;
  final Color themeColor;
  final FirebaseOptions? firebaseOptions;
  final String? appName;
  final Brightness? brightness;
  final VectorDeskChatTranslations? translations;

  const VectorDeskChatWidget({
    super.key,
    required this.orgId,
    this.personaId,
    this.greetingMessage,
    this.quickReplies,
    this.themeColor = Colors.blue,
    this.firebaseOptions,
    this.appName,
    this.brightness,
    this.translations,
  });

  @override
  State<VectorDeskChatWidget> createState() => _VectorDeskChatWidgetState();
}

class _VectorDeskChatWidgetState extends State<VectorDeskChatWidget> {
  late final VectorDeskClient _client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<VectorDeskMessage>>? _messagesSubscription;
  bool _isThinking = false;
  bool _initialized = false;
  String? _initError;

  bool get _isDark =>
      (widget.brightness ?? Theme.of(context).brightness) == Brightness.dark;

  VectorDeskChatTranslations get _l10n =>
      widget.translations ?? const VectorDeskChatDefaultTranslations();

  @override
  void initState() {
    super.initState();
    _client = VectorDeskClient(
      orgId: widget.orgId,
      personaId: widget.personaId,
    );
    _initClient();
  }

  @override
  void didUpdateWidget(covariant VectorDeskChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orgId != widget.orgId ||
        oldWidget.personaId != widget.personaId ||
        oldWidget.firebaseOptions != widget.firebaseOptions ||
        oldWidget.appName != widget.appName) {
      _client = VectorDeskClient(
        orgId: widget.orgId,
        personaId: widget.personaId,
      );
      _initClient();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initClient() async {
    if (mounted) {
      setState(() {
        _initError = null;
        _initialized = false;
      });
    }

    try {
      // In a real app, options might be passed or default used
      await _client.initialize(
          options: widget.firebaseOptions, appName: widget.appName);
      if (mounted) {
        setState(() {
          _initialized = true;
          // Cancel previous subscription if any
          _messagesSubscription?.cancel();
          _messagesSubscription = _client.chatStream.listen((messages) {
            if (mounted) {
              setState(() {
                // If we just received messages and the latest one is from the bot, stop thinking
                if (messages.isNotEmpty) {
                  final latestMessage = messages.first;
                  if (latestMessage.sender != 'user') {
                    _isThinking = false;
                  }
                }
              });
            }
          });
        });
      }
    } catch (e, stack) {
      debugPrint('VectorDesk initialization error: $e\n$stack');
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _initialized = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final String messageText = _controller.text.trim();
    _controller.clear();
    // 收合鍵盤
    FocusScope.of(context).unfocus();

    setState(() {
      _isThinking = true;
    });

    try {
      await _client.sendMessage(messageText);
    } catch (e) {
      setState(() {
        _isThinking = false; // Stop thinking on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.sendFailed(e.toString()))),
        );
      }
    }

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
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _l10n.errorMessage(_initError!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry / 重試'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<VectorDeskMessage>>(
            stream: _client.chatStream, // Use _client.chatStream directly
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text(_l10n.errorMessage(snapshot.error.toString())));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true, // Start from bottom
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
        if (_isThinking)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.themeColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_l10n.thinking,
                    style: TextStyle(
                        color: _isDark ? Colors.white54 : Colors.grey[600])),
              ],
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.greetingMessage != null)
            _buildMessageBubble(
              VectorDeskMessage(
                id: 'greeting',
                text: widget.greetingMessage!,
                sender: 'agent',
                createdAt: DateTime.now(),
              ),
            ),
          if (widget.greetingMessage == null)
            _buildMessageBubble(
              VectorDeskMessage(
                id: 'greeting_default',
                text: _l10n.defaultGreeting,
                sender: 'agent',
                createdAt: DateTime.now(),
              ),
            ),
          if (widget.quickReplies != null &&
              widget.quickReplies!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.quickReplies!.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(reply),
                      onPressed: () {
                        _controller.text = reply;
                        _sendMessage();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: widget.themeColor.withValues(alpha: 0.3)),
                      ),
                      backgroundColor: _isDark
                          ? widget.themeColor.withValues(alpha: 0.15)
                          : widget.themeColor.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                          color: _isDark ? Colors.white : widget.themeColor),
                    ),
                  );
                }).toList(),
              ),
            )
          ]
        ],
      ),
    );
  }

  void _openFullscreenImage(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, color: Colors.white);
                    },
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildMessageBubble(VectorDeskMessage msg) {
    final isUser = msg.sender == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? widget.themeColor
              : _isDark
                  ? widget.themeColor.withValues(alpha: 0.15)
                  : widget.themeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: _isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Render image attachments
            ...msg.attachments
                .where((a) =>
                    a.type == 'image' && a.url.isNotEmpty && a.url != '[已過期]')
                .map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () => _openFullscreenImage(context, a.url),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              a.url,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(child: Icon(Icons.error)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    )),
            // Expired image placeholder
            if (msg.attachments.any((a) => a.url == '[已過期]'))
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _l10n.imageExpired,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ),
            if (msg.text.isNotEmpty && msg.text != '[圖片訊息]')
              MarkdownBody(
                data: msg.text,
                selectable: true,
                onTapLink: (text, href, title) async {
                  if (href != null && await canLaunchUrlString(href)) {
                    await launchUrlString(href);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_l10n.linkOpenFailed(href ?? ''))),
                    );
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser
                        ? Colors.white
                        : (_isDark ? Colors.white : Colors.black87),
                    fontSize: 15,
                    height: 1.4,
                  ),
                  a: TextStyle(
                    color: isUser ? Colors.white : widget.themeColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  code: TextStyle(
                    backgroundColor: isUser
                        ? Colors.white24
                        : (_isDark
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1)),
                    color: isUser
                        ? Colors.white
                        : (_isDark ? Colors.white : Colors.black87),
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isUser
                        ? Colors.white24
                        : (_isDark
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              DateFormat('HH:mm').format(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isUser
                    ? Colors.white70
                    : (_isDark ? Colors.white54 : Colors.black54),
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
        color: _isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
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
                maxLength: 2000,
                style: TextStyle(
                  color: _isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: _l10n.inputHint,
                  hintStyle: TextStyle(
                    color: _isDark ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  counterText: "", // Hide the counter
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
