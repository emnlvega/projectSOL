import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectsol/providers/weather_provider.dart';
import 'package:projectsol/models/forecast_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:projectsol/screens/widgets/gradient_background.dart';

class HourlyForecastScreen extends StatefulWidget {
  const HourlyForecastScreen({super.key});

  @override
  State<HourlyForecastScreen> createState() => _HourlyForecastScreenState();
}

class _HourlyForecastScreenState extends State<HourlyForecastScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final forecast = provider.getForecastForDay(_selectedDay);
    final filtered = forecast
        .where((f) => f.time.hour >= 6 && f.time.hour <= 21)
        .toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Pronóstico por Horas'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Cómo leer el gráfico?'),
                    content: const Text(
                      'Cada barra representa la irradiancia solar estimada para esa hora (0-100%).\n\n'
                      '• La barra más alta (naranja) es la Hora Pico.\n'
                      '• Las barras azules muestran el resto de horas.\n'
                      '• Los chips inferiores indican el porcentaje de nubes.\n\n'
                      'Usa los botones de flecha para ver otros días.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedDay = _selectedDay.subtract(const Duration(days: 1));
                });
              },
            ),
            Text(DateFormat('dd/MM').format(_selectedDay),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  _selectedDay = _selectedDay.add(const Duration(days: 1));
                });
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: filtered.isEmpty
              ? const Center(child: Text('No hay datos para este día'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Irradiancia estimada por hora (0-100%)',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < filtered.length) {
                                      final hour = filtered[index].time.hour;
                                      final hourStr = hour == 0 ? '12AM' : 
                                                      hour == 12 ? '12PM' :
                                                      hour > 12 ? '${hour - 12}PM' : '${hour}AM';
                                      return Text(hourStr,
                                          style: const TextStyle(color: Colors.white70, fontSize: 10));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toInt().toString(),
                                        style: const TextStyle(color: Colors.white70, fontSize: 10));
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(filtered.length, (i) {
                              final data = filtered[i];
                              final irradiance = 100 * (1 - (data.cloudCover / 100)) *
                                  provider.temperatureFactor;
                              final isPeak = irradiance == filtered
                                  .map((e) => 100 * (1 - (e.cloudCover / 100)) *
                                      provider.temperatureFactor)
                                  .reduce((a, b) => a > b ? a : b);
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: irradiance.clamp(0, 100),
                                    color: isPeak ? Colors.orange : Colors.blue,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: filtered.map((data) {
                          final hour = data.time.hour;
                          final hourStr = hour == 0 ? '12 AM' : 
                                          hour == 12 ? '12 PM' :
                                          hour > 12 ? '${hour - 12} PM' : '$hour AM';
                          return Chip(
                            label: Text('$hourStr ${data.cloudCover.toInt()}% nubes'),
                            avatar: Icon(Icons.cloud, size: 16, color: Colors.grey[400]),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            labelStyle: const TextStyle(fontSize: 10, color: Colors.white70),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      const Text('Barra más alta = Hora Pico (mayor radiación)',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}