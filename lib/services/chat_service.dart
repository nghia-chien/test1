import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/constants.dart';
import '../models/chat_message.dart';

class ChatService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: Constants.apiKey,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<ChatMessage> _history = [];
  String sessionId;

  ChatService() : sessionId = _generateSessionIdStatic() {
    _createSessionDoc();
  }

  // ======================
  // Session Management
  // ======================
  static String _generateSessionIdStatic() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  String _generateSessionId() => _generateSessionIdStatic();

  Future<void> _createSessionDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('chats')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> switchSession(String newSessionId) async {
    sessionId = newSessionId;
    _history.clear();
    await loadHistory();
  }

  Future<List<Map<String, dynamic>>> listSessions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('chats')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'sessionId': doc.id,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

Future<void> deleteCurrentSession() async {
  final user = _auth.currentUser;
  if (user == null) return;

  final sessionToDelete = sessionId;

  final batch = _firestore.batch();
  final sessionRef = _firestore
      .collection('chats')
      .doc(user.uid)
      .collection('sessions')
      .doc(sessionToDelete);

  // Xóa tất cả messages
  final messagesRef = sessionRef.collection('messages');
  final messagesSnapshot = await messagesRef.get();
  for (var doc in messagesSnapshot.docs) {
    batch.delete(doc.reference);
  }

  // Xóa session
  batch.delete(sessionRef);
  await batch.commit();

  // Tìm phiên rỗng khác còn lại
  final sessions = await listSessions();
  for (final s in sessions) {
    final messages = await _firestore
        .collection('chats')
        .doc(user.uid)
        .collection('sessions')
        .doc(s['sessionId'])
        .collection('messages')
        .limit(1)
        .get();
    if (messages.docs.isEmpty) {
      sessionId = s['sessionId'];
      _history.clear();
      return;
    }
  }

  // Nếu không có phiên rỗng -> tạo phiên mới
  sessionId = _generateSessionId();
  _history.clear();
  await _createSessionDoc();
}

  // ======================
  // Chat Messaging
  // ======================
  List<ChatMessage> get history => List.unmodifiable(_history);

  Future<String> sendMessage(String input) async {
    try {
      final userMsg = ChatMessage(text: input, type: MessageType.user);
      _history.add(userMsg);
      await _saveMessage(userMsg);

      final response = await _model.generateContent([Content.text(input)]);
      final reply = response.text ?? 'Xin lỗi, tôi không thể phản hồi.';

      final botMsg = ChatMessage(text: reply, type: MessageType.bot);
      _history.add(botMsg);
      await _saveMessage(botMsg);

      return reply;
    } catch (e) {
      final errMsg = ChatMessage(text: 'Lỗi: $e', type: MessageType.bot);
      _history.add(errMsg);
      await _saveMessage(errMsg);
      return errMsg.text;
    }
  }

  Future<void> _saveMessage(ChatMessage msg) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('chats')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .add(msg.toMap());
  }

  Future<void> loadHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('chats')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    final messages = snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()))
        .toList();

    _history
      ..clear()
      ..addAll(messages);
  }
}
