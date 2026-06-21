import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projectsol/models/weather_data.dart';
import 'package:projectsol/models/forecast_data.dart';

class WeatherService {
  static const String apiKey = '8079705f6e2a5b987b4d8daa49515f8c';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData> fetchCurrentWeather(double lat, double lon) async {
    final url =
        '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return WeatherData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener clima actual');
    }
  }

  Future<List<ForecastData>> fetchFiveDayForecast(double lat, double lon) async {
    final url =
        '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = data['list'] as List;
      return list.map((item) => ForecastData.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener pronóstico');
    }
  }
}