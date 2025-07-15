import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    Key? key,
    this.weatherDescription,
    this.temperature,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

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

    // Thêm activity history cho chat
    await ActivityHistoryService.addActivity(
      action: 'chat',
      description: 'Chat với AI: ${trimmed.substring(0, trimmed.length > 50 ? 50 : trimmed.length)}...',
      metadata: {
        'message': trimmed,
      },
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
          title: Text("Phiên trò chuyện lúc ${s['createdAt']}"),
          onTap: () async {
            Navigator.pop(context); // Đóng bottom sheet
            await _chatService.switchSession(s['sessionId']);
            setState(() {});
            _scrollToBottom();
          },
        );
      },
    ),
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
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.wb_cloudy, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Thời tiết: ${widget.weatherDescription}, ${widget.temperature!.toStringAsFixed(1)}°C',
                style: const TextStyle(color: Colors.white),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              message: msg.type == MessageType.bot ? "Nhấn giữ để sao chép" : '',
              child: BubbleSpecialThree(
                text: msg.text,
                color: msg.type == MessageType.user ? Colors.white24 : Colors.white,
                tail: true,
                isSender: msg.type == MessageType.user,
                textStyle: TextStyle(
                  color: msg.type == MessageType.user ? Colors.white : Colors.black87,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            if (!isMobileWeb)
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.grey),
                onPressed: () {},
              ),
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _autoSend,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _autoSend(_textController.text),
              color: const Color(0xFF2A6AC9),
              splashRadius: 24,
              tooltip: "Gửi",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                "Trợ lý thời trang",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: "Xoá cuộc trò chuyện hiện tại",
            onPressed: () async {
              await _chatService.deleteCurrentSession();
              setState(() {}); // Làm mới giao diện
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "Xem lịch sử trò chuyện",
            onPressed: _showSessionList,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E6F),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
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
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                _buildMessages(),
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}