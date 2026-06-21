class ForecastData {
  final DateTime time;
  final double temperature;
  final double cloudCover;

  ForecastData({
    required this.time,
    required this.temperature,
    required this.cloudCover,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final clouds = json['clouds'];
    return ForecastData(
      time: DateTime.parse(json['dt_txt']),
      temperature: (main['temp'] - 273.15),
      cloudCover: clouds['all'].toDouble(),
    );
  }
}