import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'home_page.dart';
import 'package:flutter/services.dart';
import '../services/activity_history_service.dart';

class ChatScreen extends StatefulWidget {
  final String? weatherDescription;
  final double? temperature;
  final String? initialQuery;

  const ChatScreen({
    super.key,
    this.weatherDescription,
    this.temperature,
    this.initialQuery,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final Color primaryBlue = Constants.primaryBlue;
  final Color white = Constants.pureWhite;
  final Color black = Constants.darkBlueGrey;

  @override
  void initState() {
    super.initState();
    final query = widget.initialQuery?.trim();
    if (query != null && query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoSend(query));
    }
  }

  Future<void> _autoSend(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _textController.clear();
    _scrollToBottom();

    setState(() => _isLoading = true);

    await _chatService.sendMessage(trimmed);

    await ActivityHistoryService.addActivity(
      action: 'chat',
      description: 'Chat với AI: ${trimmed.substring(0, trimmed.length > 50 ? 50 : trimmed.length)}...',
      metadata: {'message': trimmed},
    );

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _showSessionList() async {
    final sessions = await _chatService.listSessions();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (_, index) {
          final s = sessions[index];
          return ListTile(
            leading: Icon(Icons.chat_bubble_outline, color: white),
            title: Text("Phiên trò chuyện lúc ${s['createdAt']}", style: TextStyle(color: white)),
            onTap: () async {
              Navigator.pop(context);
              await _chatService.switchSession(s['sessionId']);
              setState(() {});
              _scrollToBottom();
            },
          );
        },
      ),
      backgroundColor: const Color(0xFF1E3A8A),
    );
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

  Widget _buildWeatherInfo() {
    if (widget.weatherDescription == null || widget.temperature == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Constants.pureWhite.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud, color: white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Thời tiết: ${widget.weatherDescription}, ${widget.temperature!.toStringAsFixed(1)}°C',
                style: TextStyle(color: white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _chatService.history.length,
        itemBuilder: (context, index) {
          final msg = _chatService.history[index];
          return GestureDetector(
            onDoubleTap: msg.type == MessageType.bot
                ? () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("📋 Đã sao chép phản hồi")),
                    );
                  }
                : null,
            child: Tooltip(
              message: msg.type == MessageType.bot ? "Nhấn đúp để sao chép" : '',
              child: BubbleSpecialThree(
                text: msg.text,
                color: msg.type == MessageType.user ? primaryBlue : Constants.pureWhite,
                tail: true,
                isSender: msg.type == MessageType.user,
                textStyle: TextStyle(
                  color: msg.type == MessageType.user ? white : black,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final isMobileWeb = MediaQuery.of(context).size.width < 500 && kIsWeb;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Constants.pureWhite,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            if (!isMobileWeb)
              Icon(Icons.attach_file, color: Constants.secondaryGrey.withValues(alpha: 0.6), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _autoSend,
                style: TextStyle(color: Constants.darkBlueGrey.withValues(alpha: 0.87)),
                decoration: const InputDecoration(
                  hintText: 'Hỏi bất cứ điều gì về thời trang!',
                  hintStyle: TextStyle(color: Constants.secondaryGrey),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF3B82F6), size: 24),
              onPressed: () => _autoSend(_textController.text),
              splashRadius: 20,
              tooltip: "Gửi",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Constants.pureWhite, size: 24),
            onPressed: () => Navigator.pop(context),
            tooltip: "Quay lại",
          ),
          Expanded(
            child: Text(
              "Trợ lý thời trang",
              style: const TextStyle(
                color: Constants.pureWhite,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Constants.pureWhite, size: 24),
                tooltip: "Xóa cuộc trò chuyện",
                onPressed: () async {
                  await _chatService.deleteCurrentSession();
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.history_edu_outlined, color: Constants.pureWhite, size: 24),
                tooltip: "Lịch sử trò chuyện",
                onPressed: _showSessionList,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B82F6), Color(0xFFE0EAFC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildWeatherInfo(),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator(color: Constants.pureWhite)),
                    ),
                  _buildMessages(),
                  _buildInputBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
