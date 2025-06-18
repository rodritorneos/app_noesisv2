import 'package:flutter/material.dart';
import '../services/user_session_service.dart';
import '../services/visits_service.dart';
import '../services/api_service.dart';

class ProfileViewModel with ChangeNotifier {
  final UserSessionService _sessionService = UserSessionService();

  String _nivel = "Intermedio";
  int _puntajeObtenido = 0;
  int _puntajeTotal = 20;
  String _claseMasRecurrida = "Ninguna clase visitada aún";
  bool _isLoadingMostVisited = false;
  bool _isLoadingScore = false;

  String? get username => _sessionService.currentUsername;
  String? get userEmail => _sessionService.currentUserEmail;
  String get nivel => _nivel;
  int get puntajeObtenido => _puntajeObtenido;
  int get puntajeTotal => _puntajeTotal;
  String get claseMasRecurrida => _claseMasRecurrida;
  bool get isLoggedIn => _sessionService.isLoggedIn;
  bool get isLoadingMostVisited => _isLoadingMostVisited;
  bool get isLoadingScore => _isLoadingScore;

  Future<void> loadProfileData() async {
    if (!isLoggedIn) return;
    await _loadMostVisitedClass();
    await loadBestScore();
    notifyListeners();
  }

  Future<void> _loadMostVisitedClass() async {
    if (!isLoggedIn || userEmail == null) return;
    _isLoadingMostVisited = true;
    notifyListeners();

    try {
      final mostVisitedId = await VisitsService.getMostVisitedClass(userEmail!);
      if (mostVisitedId != null) {
        _claseMasRecurrida = _getClassNameFromId(mostVisitedId);
      } else {
        _claseMasRecurrida = "Ninguna clase visitada aún";
      }
    } catch (e) {
      print('Error loading most visited class: $e');
      _claseMasRecurrida = "Error al cargar datos";
    } finally {
      _isLoadingMostVisited = false;
      notifyListeners();
    }
  }

  Future<void> loadBestScore() async {
    if (!isLoggedIn || userEmail == null) return;
    _isLoadingScore = true;
    notifyListeners();

    try {
      final response = await ApiService.getBestScore(userEmail!);
      if (response['success']) {
        _puntajeObtenido = response['data']['puntaje_obtenido'] ?? 0;
        _puntajeTotal = response['data']['puntaje_total'] ?? 20;
        _nivel = response['data']['nivel'] ?? "Básico";
      }
    } catch (e) {
      print('Error loading best score: $e');
    } finally {
      _isLoadingScore = false;
      notifyListeners();
    }
  }

  Future<bool> updateBestScore(int correctAnswers, int totalQuestions) async {
    if (!isLoggedIn || userEmail == null) return false;

    try {
      int claseCod = _getClassCodeFromName(_claseMasRecurrida);
      String newLevel = await ApiService.predecirNivel(
        puntajeObtenido: correctAnswers,
        puntajeTotal: totalQuestions,
        claseMasRecurridaCod: claseCod,
      );

      final response = await ApiService.updateBestScore(
        userEmail!,
        correctAnswers,
        totalQuestions,
        newLevel,
      );

      if (response['success']) {
        final isNewBest = response['data']?['is_new_best'] ?? false;
        if (isNewBest || response['data']?['is_new_best'] == null) {
          _puntajeObtenido = correctAnswers;
          _puntajeTotal = totalQuestions;
          _nivel = newLevel;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('Error updating best score: $e');
    }

    return false;
  }

  String _getClassNameFromId(String classId) {
    switch (classId) {
      case 'verb_to_be':
        return 'Verb to be';
      case 'future_perfect':
        return 'Future Perfect';
      case 'present_simple':
        return 'Present Simple';
      case 'verb_can':
        return 'The Verb Can';
      default:
        return 'Clase desconocida';
    }
  }

  int _getClassCodeFromName(String className) {
    switch (className) {
      case 'Verb to be':
        return 0;
      case 'Present Simple':
        return 1;
      case 'The Verb Can':
        return 2;
      case 'Future Perfect':
        return 3;
      default:
        return 0;
    }
  }

  void updateProfileData({
    String? nivel,
    int? puntajeObtenido,
    int? puntajeTotal,
    String? claseMasRecurrida,
  }) {
    if (nivel != null) _nivel = nivel;
    if (puntajeObtenido != null) _puntajeObtenido = puntajeObtenido;
    if (puntajeTotal != null) _puntajeTotal = puntajeTotal;
    if (claseMasRecurrida != null) _claseMasRecurrida = claseMasRecurrida;
    notifyListeners();
  }

  void logout() {
    _sessionService.logout();
    notifyListeners();
  }
}