import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String apiKey = '8079705f6e2a5b987b4d8daa49515f8c'; // Usa la misma API Key de OpenWeatherMap

  static Future<List<Map<String, dynamic>>> searchCity(String query) async {
    if (query.isEmpty) return [];
    
    final url = 'http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => {
        'name': e['name'] ?? '',
        'country': e['country'] ?? '',
        'state': e['state'] ?? '',
        'lat': e['lat'] ?? 0.0,
        'lon': e['lon'] ?? 0.0,
      }).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> reverseGeocode(double lat, double lon) async {
    final url = 'http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return {
          'name': data[0]['name'] ?? '',
          'country': data[0]['country'] ?? '',
          'state': data[0]['state'] ?? '',
          'lat': data[0]['lat'] ?? 0.0,
          'lon': data[0]['lon'] ?? 0.0,
        };
      }
    }
    return null;
  }
}