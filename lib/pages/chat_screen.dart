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

  // Updated color scheme based on the provided palette
  final Color primaryBlue = const Color(0xFF209CFF);      // Soft blue from palette
  final Color accentGray = const Color(0xFF7D7F85);       // Medium gray from palette
  final Color darkNavy = const Color(0xFF010810);         // Dark navy from palette
  final Color pureWhite = const Color(0xFFFFFFFF);        // Pure white from palette
  final Color softTextGray = const Color(0xFF8B9196);     // Soft gray for secondary text
  final Color lightBackground = const Color(0xFFF8F9FA);   // Very light background

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
      backgroundColor: darkNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: softTextGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Lịch sử trò chuyện",
              style: TextStyle(
                color: pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (_, index) {
                  final s = sessions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.chat_bubble_outline, color: primaryBlue, size: 20),
                      ),
                      title: Text(
                        "Phiên trò chuyện lúc ${s['createdAt']}", 
                        style: TextStyle(color: pureWhite, fontSize: 14, fontWeight: FontWeight.w500)
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _chatService.switchSession(s['sessionId']);
                        setState(() {});
                        _scrollToBottom();
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    // Show weather info even if not provided (for demo purposes)
    final weatherDesc = widget.weatherDescription ?? 'Partly Cloudy';
    final temp = widget.temperature ?? 24.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pureWhite.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pureWhite.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: darkNavy.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pureWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getWeatherIcon(weatherDesc),
                color: pureWhite,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thời tiết hôm nay',
                    style: TextStyle(
                      color: pureWhite.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${temp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          color: pureWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: pureWhite.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          weatherDesc,
                          style: TextStyle(
                            color: pureWhite.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.refresh,
                color: pureWhite.withOpacity(0.6),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('sun') || desc.contains('clear')) {
      return Icons.wb_sunny;
    } else if (desc.contains('cloud')) {
      return Icons.wb_cloudy;
    } else if (desc.contains('rain')) {
      return Icons.grain;
    } else if (desc.contains('storm')) {
      return Icons.flash_on;
    } else if (desc.contains('snow')) {
      return Icons.ac_unit;
    } else if (desc.contains('fog') || desc.contains('mist')) {
      return Icons.blur_on;
    }
    return Icons.wb_cloudy_outlined;
  }

  Widget _buildMessages() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _chatService.history.length,
        itemBuilder: (context, index) {
          final msg = _chatService.history[index];
          final isUser = msg.type == MessageType.user;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentGray.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.assistant, color: accentGray, size: 16),
                  ),
                ],
                Flexible(
                  child: GestureDetector(
                    onDoubleTap: !isUser
                        ? () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("📋 Đã sao chép phản hồi"),
                                backgroundColor: primaryBlue,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser 
                            ? primaryBlue 
                            : pureWhite,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: darkNavy.withOpacity(0.08),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isUser ? pureWhite : darkNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isUser) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_outline, color: primaryBlue, size: 16),
                  ),
                ],
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: darkNavy.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            if (!isMobileWeb)
              Container(
                margin: const EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.attach_file_outlined, 
                  color: softTextGray, 
                  size: 20
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _autoSend,
                style: TextStyle(
                  color: darkNavy, 
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Hỏi bất cứ điều gì về thời trang!',
                  hintStyle: TextStyle(
                    color: softTextGray, 
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: Material(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _autoSend(_textController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.send_rounded, 
                      color: pureWhite, 
                      size: 20
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded, 
                  color: pureWhite, 
                  size: 22
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Trợ lý thời trang",
              style: TextStyle(
                color: pureWhite,
                fontWeight: FontWeight.w400,
                fontSize: 20,
                letterSpacing: 0.3,
                fontFamily: 'BeautiqueDisplay', 
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await _chatService.deleteCurrentSession();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete_outline, 
                      color: pureWhite.withOpacity(0.8), 
                      size: 22
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showSessionList,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.history_outlined, 
                      color: pureWhite.withOpacity(0.8), 
                      size: 22
                    ),
                  ),
                ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryBlue,
              accentGray.withOpacity(0.3),
              lightBackground,
            ],
            stops: const [0.0, 0.6, 1.0],
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: pureWhite.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: pureWhite,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Đang suy nghĩ...",
                                style: TextStyle(
                                  color: pureWhite.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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