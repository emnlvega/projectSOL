import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectsol/providers/weather_provider.dart';
import 'package:projectsol/providers/history_provider.dart';
import 'package:projectsol/providers/settings_provider.dart';
import 'package:projectsol/screens/hourly_forecast_screen.dart';
import 'package:projectsol/screens/planner_screen.dart';
import 'package:projectsol/screens/radiation_map_screen.dart';
import 'package:projectsol/screens/widgets/gradient_background.dart';
import 'package:projectsol/screens/widgets/recommendation_card.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final weather = provider.currentWeather;
    final isLoading = provider.isLoading;
    final error = provider.error;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('project',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Text('S',
                  style:
                      TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const Text('L',
                  style:
                      TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(error, textAlign: TextAlign.center),
                          ElevatedButton(
                            onPressed: () => provider.refreshData(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : weather == null
                      ? const Center(child: Text('Sin datos'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ubicación - CLICKEABLE
                              GestureDetector(
                                onTap: () {
                                  _showLocationOptions(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Text(
                                        provider.currentLocationName,
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down,
                                          color: Colors.white54, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Potencial Solar
                              _buildGradientCard(
                                borderColor: Colors.amber,
                                borderOpacity: 0.4,
                                child: _buildInfoCardContent(
                                  title: 'Potencial Solar Hoy',
                                  value: '${provider.solarPotential.toStringAsFixed(0)}%',
                                  subtitle: 'Basado en nubes y temperatura',
                                  icon: Icons.wb_sunny,
                                  infoText:
                                      'El potencial solar indica el porcentaje de energía solar que se puede aprovechar según la cobertura de nubes y la temperatura. A mayor porcentaje, mejor rendimiento de tus paneles solares.',
                                  outlineColor: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tarjetas de generación y ahorro
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildGradientCard(
                                      borderColor: Colors.green,
                                      borderOpacity: 0.4,
                                      padding: const EdgeInsets.all(12),
                                      child: _buildInfoCardContent(
                                        title: 'Generación Estimada',
                                        value:
                                            '${provider.estimatedKwh.toStringAsFixed(1)} kWh',
                                        subtitle: 'Energía producida',
                                        icon: Icons.flash_on,
                                        infoText:
                                            'Cálculo estimado de kilowatts-hora que producirán tus paneles hoy, basado en el potencial solar y la capacidad de tu sistema.',
                                        outlineColor: Colors.green,
                                        small: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: _buildGradientCard(
                                      borderColor: Colors.lightGreen,
                                      borderOpacity: 0.4,
                                      padding: const EdgeInsets.all(12),
                                      child: _buildInfoCardContent(
                                        title: 'Ahorro Aprox.',
                                        value:
                                            '\$${provider.moneySaved.toStringAsFixed(2)}',
                                        subtitle: 'Pesos ahorrados',
                                        icon: Icons.attach_money,
                                        infoText:
                                            'Ahorro estimado en tu factura eléctrica al usar energía solar en lugar de la red, considerando un costo de \$0.30 por kWh.',
                                        outlineColor: Colors.lightGreen,
                                        small: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Hora Pico
                              _buildGradientCard(
                                borderColor: Colors.orange,
                                borderOpacity: 0.4,
                                child: _buildInfoCardContent(
                                  title: 'Hora Pico',
                                  value: provider.peakHour,
                                  subtitle: 'Momento de mayor radiación',
                                  icon: Icons.timelapse,
                                  infoText:
                                      'La hora pico es el momento del día con mayor radiación solar, ideal para conectar electrodomésticos de alto consumo y maximizar el uso de energía solar.',
                                  outlineColor: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Temperatura y Factor de Calor
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildGradientCard(
                                      borderColor: Colors.blue,
                                      borderOpacity: 0.4,
                                      padding: const EdgeInsets.all(12),
                                      child: _buildInfoCardContent(
                                        title: 'Temperatura',
                                        value:
                                            '${weather.temperature.toStringAsFixed(1)}°C',
                                        subtitle: 'Actual',
                                        icon: Icons.thermostat,
                                        infoText:
                                            'Temperatura ambiente actual. Afecta la eficiencia de los paneles solares: temperaturas altas (>25°C) reducen su rendimiento.',
                                        outlineColor: Colors.blue,
                                        small: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: _buildGradientCard(
                                      borderColor: Colors.purple,
                                      borderOpacity: 0.4,
                                      padding: const EdgeInsets.all(12),
                                      child: _buildInfoCardContent(
                                        title: 'Factor de Calor',
                                        value: provider.temperatureFactor
                                            .toStringAsFixed(3),
                                        subtitle: provider.temperatureFactor > 0.9
                                            ? 'Eficiencia alta'
                                            : 'Pérdida por calor',
                                        icon: Icons.speed,
                                        infoText:
                                            'El factor de calor indica la pérdida de eficiencia de los paneles por temperatura. Si es menor a 1.0, significa que el calor reduce la producción. Ejemplo: 0.95 significa 5% menos de eficiencia.',
                                        outlineColor: Colors.purple,
                                        small: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Gráfico de tendencia
                              _buildTrendChart(provider),
                              const SizedBox(height: 16),

                              // Comparativa Día vs Día
                              _buildComparisonSection(provider),
                              const SizedBox(height: 16),

                              // Recomendaciones Personalizadas
                              _buildRecommendations(provider),
                              const SizedBox(height: 16),

                              // Botones de navegación
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildNavButton(
                                      icon: Icons.show_chart,
                                      label: 'Pronóstico Horas',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const HourlyForecastScreen(),
                                          ),
                                        );
                                      },
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: _buildNavButton(
                                      icon: Icons.schedule,
                                      label: 'Planificador',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PlannerScreen(),
                                          ),
                                        );
                                      },
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Botones de navegación adicionales
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildNavButton(
                                      icon: Icons.calendar_today,
                                      label: 'Pronóstico 5 Días',
                                      onPressed: () {
                                        Navigator.pushNamed(
                                            context, '/extended_forecast');
                                      },
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildNavButton(
                                      icon: Icons.settings,
                                      label: 'Configuración',
                                      onPressed: () {
                                        Navigator.pushNamed(
                                            context, '/settings');
                                      },
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }

  // Widget helper para tarjetas con gradiente
  Widget _buildGradientCard({
    required Widget child,
    Color borderColor = Colors.white,
    double borderOpacity = 0.1,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double borderRadius = 16,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF151A2B),
            Color(0xFF1E2438),
            Color(0xFF161C2E),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor.withOpacity(borderOpacity),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  // Contenido de las tarjetas de información
  Widget _buildInfoCardContent({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required String infoText,
    required Color outlineColor,
    bool small = false,
  }) {
    final fontSize = small ? 14.0 : 24.0;
    final iconSize = small ? 16.0 : 20.0;
    final titleSize = small ? 11.0 : 14.0;
    final subtitleSize = small ? 10.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Icon(icon, color: outlineColor, size: iconSize),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: titleSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline,
                  color: outlineColor, size: small ? 14 : 18),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(title),
                    content: Text(infoText),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: outlineColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white60,
            fontSize: subtitleSize,
          ),
        ),
      ],
    );
  }

  // Diálogo para opciones de ubicación
  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ubicación',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map, color: Colors.amber),
              ),
              title: const Text('Ver mapa de radiación',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                  'Visualiza la radiación solar en tu área',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RadiationMapScreen()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_location, color: Colors.blue),
              ),
              title: const Text('Cambiar ubicación',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Buscar y seleccionar otra ciudad',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return _buildGradientCard(
      borderColor: color,
      borderOpacity: 0.4,
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        label: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(WeatherProvider provider) {
    final forecast = provider.forecast;
    if (forecast == null || forecast.isEmpty) return const SizedBox.shrink();

    final recent = forecast.where((f) => f.time.hour >= 6 && f.time.hour <= 21).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    final display = recent.length > 6 ? recent.sublist(recent.length - 6) : recent;

    return _buildGradientCard(
      borderColor: Colors.white,
      borderOpacity: 0.1,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tendencia de Irradiancia (últimas horas)',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < display.length) {
                          return Text('${display[index].time.hour}h',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: display.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final irradiance = 100 *
                          (1 - (data.cloudCover / 100)) *
                          provider.temperatureFactor;
                      return FlSpot(index.toDouble(), irradiance.clamp(0, 100));
                    }).toList(),
                    isCurved: true,
                    color: Colors.amber,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.amber,
                          strokeWidth: 0,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(WeatherProvider provider) {
    final historyProvider = Provider.of<HistoryProvider>(context);
    final comparison = historyProvider.todayPotentialComparison;

    return _buildGradientCard(
      borderColor: Colors.white,
      borderOpacity: 0.1,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Comparativa vs ayer',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: comparison >= 0
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: comparison >= 0
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  comparison >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: comparison >= 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${comparison >= 0 ? '+' : ''}${comparison.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: comparison >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(WeatherProvider provider) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final potential = provider.solarPotential;
    final totalConsumption = settingsProvider.totalWatts;

    String title;
    String description;
    IconData icon;
    Color color;

    if (potential > 80) {
      title = '⚡ Excelente día para paneles';
      description =
          'Aprovecha al máximo, conecta tus electrodomésticos de alto consumo.';
      icon = Icons.emoji_events;
      color = Colors.green;
    } else if (potential > 50) {
      title = '☀️ Buen potencial solar';
      description = 'Momento ideal para cargar tu EV o usar la lavadora.';
      icon = Icons.wb_sunny;
      color = Colors.amber;
    } else if (potential > 30) {
      title = '⛅ Potencial moderado';
      description =
          'Prioriza electrodomésticos pequeños o espera un mejor momento.';
      icon = Icons.cloud_queue;
      color = Colors.orange;
    } else {
      title = '🌧️ Bajo potencial solar';
      description =
          'Considera usar la red eléctrica o reducir el consumo hoy.';
      icon = Icons.cloud;
      color = Colors.blueGrey;
    }

    // Personalización según consumo
    if (totalConsumption > 3000 && potential < 50) {
      description =
          '⚠️ Alto consumo con bajo potencial. Considera postergar algunos dispositivos.';
      color = Colors.red;
    }

    return _buildGradientCard(
      borderColor: color,
      borderOpacity: 0.3,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}