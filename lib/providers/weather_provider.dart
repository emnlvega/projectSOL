import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectsol/models/weather_data.dart';
import 'package:projectsol/models/forecast_data.dart';
import 'package:projectsol/services/location_service.dart';
import 'package:projectsol/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherData? _currentWeather;
  List<ForecastData>? _forecast;
  bool _isLoading = false;
  String _error = '';
  bool _initialized = false;
  String _currentLocationName = '';

  WeatherData? get currentWeather => _currentWeather;
  List<ForecastData>? get forecast => _forecast;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get currentLocationName {
    if (_currentLocationName.isNotEmpty) return _currentLocationName;
    if (_currentWeather != null) return _currentWeather!.cityName;
    return 'Ubicación desconocida';
  }

  double get temperatureFactor {
    if (_currentWeather == null) return 1.0;
    final temp = _currentWeather!.temperature;
    if (temp > 25) return 1 - ((temp - 25) * 0.005);
    return 1.0;
  }

  double get solarPotential {
    if (_currentWeather == null) return 0;
    final base = 100 * (1 - (_currentWeather!.cloudCover / 100));
    return base * temperatureFactor;
  }

  double get estimatedKwh {
    final potential = solarPotential / 100;
    return 5 * 5 * 0.8 * potential;
  }

  double get moneySaved => estimatedKwh * 0.30;

  String get peakHour {
    if (_forecast == null || _forecast!.isEmpty) return '12:00 PM';
    
    final dayForecast = _forecast!
        .where((f) => f.time.hour >= 8 && f.time.hour <= 18)
        .toList();
    
    if (dayForecast.isEmpty) return '12:00 PM';
    
    double maxIrradiance = -1;
    ForecastData? peak;
    
    for (var f in dayForecast) {
      final hourFactor = 1 - ((f.time.hour - 13).abs() * 0.05);
      final irradiance = 100 * (1 - (f.cloudCover / 100)) * temperatureFactor * hourFactor;
      
      if (irradiance > maxIrradiance) {
        maxIrradiance = irradiance;
        peak = f;
      }
    }
    
    if (peak == null) return '12:00 PM';
    return _formatHourTo12(peak.time.hour);
  }

  String get peakHour24 {
    if (_forecast == null || _forecast!.isEmpty) return '12:00';
    
    final dayForecast = _forecast!
        .where((f) => f.time.hour >= 8 && f.time.hour <= 18)
        .toList();
    
    if (dayForecast.isEmpty) return '12:00';
    
    double maxIrradiance = -1;
    ForecastData? peak;
    
    for (var f in dayForecast) {
      final hourFactor = 1 - ((f.time.hour - 13).abs() * 0.05);
      final irradiance = 100 * (1 - (f.cloudCover / 100)) * temperatureFactor * hourFactor;
      
      if (irradiance > maxIrradiance) {
        maxIrradiance = irradiance;
        peak = f;
      }
    }
    
    if (peak == null) return '12:00';
    return '${peak.time.hour.toString().padLeft(2, '0')}:00';
  }

  String _formatHourTo12(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour > 12) return '${hour - 12}:00 PM';
    return '$hour:00 AM';
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadData(force: false);
    _initialized = true;
  }

  void updateLocation(double lat, double lon, String locationName) {
    _saveCustomLocation(lat, lon, locationName);
    _loadDataWithCustomLocation(lat, lon, locationName);
  }

  Future<void> _saveCustomLocation(double lat, double lon, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('custom_lat', lat);
    await prefs.setDouble('custom_lon', lon);
    await prefs.setString('custom_location_name', name);
  }

  Future<void> _loadDataWithCustomLocation(double lat, double lon, String locationName) async {
    _isLoading = true;
    _error = '';
    _currentLocationName = locationName;
    notifyListeners();

    try {
      final weather = await WeatherService()
          .fetchCurrentWeather(lat, lon);
      final forecast = await WeatherService()
          .fetchFiveDayForecast(lat, lon);
      _currentWeather = weather;
      _forecast = forecast;
      _error = '';
    } catch (e) {
      _error = e.toString();
      _currentWeather = null;
      _forecast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadData({bool force = false}) async {
    if (_initialized && !force) return;
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final customLat = prefs.getDouble('custom_lat');
      final customLon = prefs.getDouble('custom_lon');
      final customName = prefs.getString('custom_location_name') ?? '';
      
      double lat, lon;
      
      if (customLat != null && customLon != null) {
        lat = customLat;
        lon = customLon;
        _currentLocationName = customName;
      } else {
        final position = await LocationService.getCurrentLocation();
        lat = position.latitude;
        lon = position.longitude;
        _currentLocationName = '';
      }
      
      final weather = await WeatherService()
          .fetchCurrentWeather(lat, lon);
      final forecast = await WeatherService()
          .fetchFiveDayForecast(lat, lon);
      _currentWeather = weather;
      _forecast = forecast;
      _error = '';
    } catch (e) {
      _error = e.toString();
      _currentWeather = null;
      _forecast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  

  Future<void> refreshData() async {
    await _loadData(force: true);
  }

  List<ForecastData> getForecastForDay(DateTime day) {
    if (_forecast == null) return [];
    return _forecast!
        .where((f) =>
            f.time.year == day.year &&
            f.time.month == day.month &&
            f.time.day == day.day)
        .toList();
  }
}