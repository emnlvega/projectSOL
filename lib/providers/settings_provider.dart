import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:projectsol/models/user_settings.dart';

class SettingsProvider extends ChangeNotifier {
  UserSettings _settings = UserSettings();
  List<Appliance> _appliances = [];

  UserSettings get settings => _settings;
  List<Appliance> get appliances => _appliances;

  double get totalWatts {
    double total = 0;
    for (var a in _appliances) {
      if (a.selected) total += a.watts;
    }
    return total;
  }

  double get estimatedTotalGeneration {
    // Capacidad total en kW * horas de sol promedio (5) * eficiencia
    return _settings.panelCapacity * 5 * 0.8;
  }

  SettingsProvider() {
    _loadSettings();
    _loadAppliances();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_settings');
    if (data != null) {
      final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
      _settings = UserSettings.fromJson(map);
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_settings', jsonEncode(_settings.toJson()));
  }

  void updateLocation(String location) {
    _settings.customLocation = location;
    _saveSettings();
    notifyListeners();
  }

  void updatePanelSettings(double capacity, int count, double angle) {
    _settings.panelCapacity = capacity;
    _settings.panelCount = count;
    _settings.panelAngle = angle;
    _saveSettings();
    notifyListeners();
  }

  // Métodos de appliances (ya existentes)
  Future<void> _loadAppliances() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('appliances');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data) as List<dynamic>;
      _appliances = list.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return Appliance.fromJson(map);
      }).toList();
    } else {
      _appliances = [
        Appliance(name: 'Lavadora', watts: 1500),
        Appliance(name: 'Secadora', watts: 2000),
        Appliance(name: 'Coche EV', watts: 7000),
        Appliance(name: 'Horno', watts: 3000),
      ];
    }
    notifyListeners();
  }

  Future<void> _saveAppliances() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> list = _appliances.map((a) => a.toJson()).toList();
    await prefs.setString('appliances', jsonEncode(list));
  }

  void addAppliance(String name, int watts) {
    _appliances.add(Appliance(name: name, watts: watts));
    _saveAppliances();
    notifyListeners();
  }

  void removeAppliance(int index) {
    _appliances.removeAt(index);
    _saveAppliances();
    notifyListeners();
  }

  void toggleAppliance(int index) {
    _appliances[index].selected = !_appliances[index].selected;
    _saveAppliances();
    notifyListeners();
  }

  void updateAppliance(int index, String name, int watts) {
    _appliances[index].name = name;
    _appliances[index].watts = watts;
    _saveAppliances();
    notifyListeners();
  }
}

class Appliance {
  String name;
  int watts;
  bool selected;

  Appliance({required this.name, required this.watts, this.selected = false});

  Map<String, dynamic> toJson() => {
        'name': name,
        'watts': watts,
        'selected': selected,
      };

  factory Appliance.fromJson(Map<String, dynamic> json) => Appliance(
        name: json['name'],
        watts: json['watts'],
        selected: json['selected'] ?? false,
      );
}