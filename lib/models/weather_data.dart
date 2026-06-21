class WeatherData {
  final double temperature;
  final double cloudCover; // 0-100
  final String description;
  final String cityName;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.cloudCover,
    required this.description,
    required this.cityName,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final clouds = json['clouds'];
    return WeatherData(
      temperature: (main['temp'] - 273.15), // Kelvin a Celsius
      cloudCover: clouds['all'].toDouble(),
      description: weather['description'],
      cityName: json['name'],
      timestamp: DateTime.now(),
    );
  }
}