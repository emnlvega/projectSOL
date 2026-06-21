import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:projectsol/models/daily_saving.dart';

class HistoryProvider extends ChangeNotifier {
  List<DailySaving> _history = [];

  List<DailySaving> get history => _history;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('history');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data) as List<dynamic>;
      _history = list.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return DailySaving.fromJson(map);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> list = _history.map((h) => h.toJson()).toList();
    await prefs.setString('history', jsonEncode(list));
  }

  void addDailySaving(double amount, double potential, double temperature) {
    final today = DateTime.now();
    // Verificar si ya existe un registro para hoy
    final existing = _history.indexWhere(
      (h) => h.date.year == today.year && h.date.month == today.month && h.date.day == today.day,
    );
    if (existing != -1) {
      _history[existing] = DailySaving(
        date: today,
        amount: amount,
        potential: potential,
        temperature: temperature,
      );
    } else {
      _history.add(DailySaving(
        date: today,
        amount: amount,
        potential: potential,
        temperature: temperature,
      ));
      // Mantener solo los últimos 30 días
      if (_history.length > 30) {
        _history.removeAt(0);
      }
    }
    _saveHistory();
    notifyListeners();
  }

  double get totalSavingLast7Days {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return _history
        .where((h) => h.date.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, h) => sum + h.amount);
  }

  double get averageSavingLast7Days {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final last7 = _history.where((h) => h.date.isAfter(sevenDaysAgo)).toList();
    if (last7.isEmpty) return 0;
    return last7.fold(0.0, (sum, h) => sum + h.amount) / last7.length;
  }

  double get todayPotentialComparison {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final todayData = _history.firstWhere(
      (h) => h.date.year == now.year && h.date.month == now.month && h.date.day == now.day,
      orElse: () => DailySaving(date: now, amount: 0, potential: 0, temperature: 0),
    );
    final yesterdayData = _history.firstWhere(
      (h) => h.date.year == yesterday.year && h.date.month == yesterday.month && h.date.day == yesterday.day,
      orElse: () => DailySaving(date: yesterday, amount: 0, potential: 0, temperature: 0),
    );
    if (yesterdayData.potential == 0) return 0;
    return ((todayData.potential - yesterdayData.potential) / yesterdayData.potential) * 100;
  }

  List<DailySaving> getLast7Days() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    return _history.where((h) => h.date.isAfter(sevenDaysAgo)).toList();
  }
}