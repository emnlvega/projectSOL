import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectsol/providers/weather_provider.dart';
import 'package:projectsol/models/forecast_data.dart';
import 'package:projectsol/screens/widgets/gradient_background.dart';
import 'package:intl/intl.dart';

class ExtendedForecastScreen extends StatelessWidget {
  const ExtendedForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final forecast = provider.forecast;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Pronóstico 5 Días'),
          backgroundColor: Colors.transparent,
        ),
        body: RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: forecast == null || forecast.isEmpty
              ? const Center(child: Text('Sin datos de pronóstico'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final day = DateTime.now().add(Duration(days: index));
                    final dayForecast = forecast.where((f) =>
                        f.time.year == day.year &&
                        f.time.month == day.month &&
                        f.time.day == day.day).toList();
                    if (dayForecast.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildDayCard(dayForecast, day, provider);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildDayCard(List<ForecastData> dayForecast, DateTime day, WeatherProvider provider) {
    // Calcular promedio del día
    final avgTemp = dayForecast.fold(0.0, (sum, f) => sum + f.temperature) / dayForecast.length;
    final avgCloud = dayForecast.fold(0.0, (sum, f) => sum + f.cloudCover) / dayForecast.length;
    final avgIrradiance = dayForecast.fold(0.0, (sum, f) =>
        sum + (100 * (1 - (f.cloudCover / 100)) * provider.temperatureFactor)) / dayForecast.length;
    
    // Encontrar hora pico del día

    String _formatHourTo12(int hour) {
      if (hour == 0) return '12:00 AM';
      if (hour == 12) return '12:00 PM';
      if (hour > 12) return '${hour - 12}:00 PM';
      return '$hour:00 AM';
    }
    
    double maxIrradiance = -1;
    String peakHour = '--:00';
      for (var f in dayForecast) {
        final hourFactor = 1 - ((f.time.hour - 13).abs() * 0.05);
        final irradiance = 100 * (1 - (f.cloudCover / 100)) * provider.temperatureFactor * hourFactor;
        if (irradiance > maxIrradiance) {
          maxIrradiance = irradiance;
          peakHour = _formatHourTo12(f.time.hour);
        }
      }

    

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('EEEE, d MMM').format(day),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (day.day == DateTime.now().day)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: const Text('Hoy', style: TextStyle(color: Colors.amber, fontSize: 10)),
                    ),
                ],
              ),
              Icon(
                avgCloud > 70 ? Icons.cloud : (avgCloud > 40 ? Icons.cloud_queue : Icons.wb_sunny),
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip('🌡️ ${avgTemp.toStringAsFixed(1)}°C'),
              const SizedBox(width: 8),
              _buildInfoChip('☁️ ${avgCloud.toStringAsFixed(0)}% nubes'),
              const SizedBox(width: 8),
              _buildInfoChip('⚡ ${avgIrradiance.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hora Pico: $peakHour',
                style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.3),
                      Colors.orange.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(avgIrradiance / 100 * 5).toStringAsFixed(1)} kWh',
                  style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    );
  }
}