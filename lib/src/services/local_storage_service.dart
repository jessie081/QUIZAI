import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import '../models/quiz_model.dart';

class LocalStorageService {
  static const String _savedQuizzesKey = 'saved_quizzes_v2';
  static const String _currentPdfKey = 'current_pdf_v1';
  static const String _conversationKeyPrefix = 'conversation_v1_';

  Future<void> saveQuiz(QuizModel quiz) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadQuizzes();
    final updated = <QuizModel>[
      quiz,
      ...current.where((item) => item.id != quiz.id),
    ];

    await prefs.setStringList(
      _savedQuizzesKey,
      updated.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<List<QuizModel>> loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_savedQuizzesKey) ?? const <String>[];

    return rawItems
        .map((item) => QuizModel.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deleteQuiz(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadQuizzes();
    final updated = current.where((quiz) => quiz.id != quizId).toList();
    await prefs.setStringList(
      _savedQuizzesKey,
      updated.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> clearQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedQuizzesKey);
  }

  Future<void> saveCurrentDocument(PdfDocumentModel document) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentPdfKey, jsonEncode(document.toJson()));
  }

  Future<PdfDocumentModel?> loadCurrentDocument() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentPdfKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return PdfDocumentModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCurrentDocument() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentPdfKey);
  }

  Future<void> saveConversation(
    String key,
    List<ChatMessageModel> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_conversationKeyPrefix$key',
      jsonEncode(messages.map((message) => message.toJson()).toList()),
    );
  }

  Future<List<ChatMessageModel>> loadConversation(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_conversationKeyPrefix$key');
    if (raw == null || raw.isEmpty) {
      return const <ChatMessageModel>[];
    }

    try {
      final decoded = List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List<dynamic>).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      return decoded.map(ChatMessageModel.fromJson).toList();
    } catch (_) {
      return const <ChatMessageModel>[];
    }
  }

  Future<void> clearConversation(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_conversationKeyPrefix$key');
  }
}
