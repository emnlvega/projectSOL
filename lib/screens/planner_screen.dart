import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectsol/providers/weather_provider.dart';
import 'package:projectsol/providers/settings_provider.dart';
import 'package:projectsol/screens/widgets/gradient_background.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wattsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _wattsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final weather = Provider.of<WeatherProvider>(context);
    final peakHour = weather.peakHour;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Planificador Inteligente'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Cómo usar el planificador?'),
                    content: const Text(
                      '1. Agrega tus electrodomésticos con su potencia en watts.\n'
                      '2. Selecciona los que planeas usar hoy.\n'
                      '3. La app calculará el consumo total.\n'
                      '4. Te mostrará la Hora Pico para conectarlos y maximizar el ahorro.\n\n'
                      'Conectar tus dispositivos en la Hora Pico aprovecha al máximo la energía solar.\n\n'
                      'Si tu consumo excede la capacidad de tus paneles, verás una advertencia.'
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
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => weather.refreshData(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Agregar electrodoméstico
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Electrodoméstico',
                                labelStyle: TextStyle(color: Colors.white60),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blueGrey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Nombre requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _wattsController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Watts',
                                labelStyle: TextStyle(color: Colors.white60),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blueGrey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Potencia requerida' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final name = _nameController.text.trim();
                            final watts = int.parse(_wattsController.text.trim());
                            settings.addAppliance(name, watts);
                            _nameController.clear();
                            _wattsController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Electrodoméstico agregado')),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.blueGrey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Lista de electrodomésticos
              const Text('Mis electrodomésticos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              ...settings.appliances.asMap().entries.map((entry) {
                final index = entry.key;
                final app = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: app.selected ? Colors.amber : Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: app.selected,
                      onChanged: (_) => settings.toggleAppliance(index),
                      activeColor: Colors.amber,
                      checkColor: Colors.black,
                    ),
                    title: Text(app.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${app.watts} W', style: const TextStyle(color: Colors.white60)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        settings.removeAppliance(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Electrodoméstico eliminado')),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              // Resumen y recomendación
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consumo total seleccionado:',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('${settings.totalWatts.toStringAsFixed(0)} W',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Mejor horario para conectarlos:',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(peakHour,
                        style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('(Hora de mayor radiación solar)',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Advertencia de capacidad del sistema solar
              _buildCapacityWarning(settings, weather),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityWarning(SettingsProvider settings, WeatherProvider weather) {
    final totalCapacity = settings.settings.panelCapacity * settings.settings.panelCount; // kW
    final totalConsumption = settings.totalWatts / 1000; // Convertir a kW
    final potential = weather.solarPotential / 100; // 0-1
    
    // Estimación de generación real considerando el potencial solar
    final estimatedGeneration = totalCapacity * potential * 5; // 5 horas de sol pico
    
    if (totalConsumption == 0) return const SizedBox.shrink();
    
    final isExceeding = totalConsumption > estimatedGeneration;
    final percentage = estimatedGeneration > 0 ? (totalConsumption / estimatedGeneration * 100) : 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExceeding ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExceeding ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExceeding ? Icons.warning_amber_rounded : Icons.check_circle,
                color: isExceeding ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isExceeding ? '⚠️ Consumo excede la capacidad' : '✅ Dentro de la capacidad',
                style: TextStyle(
                  color: isExceeding ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Capacidad del sistema: ${estimatedGeneration.toStringAsFixed(1)} kWh estimados hoy',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            'Consumo planeado: ${totalConsumption.toStringAsFixed(1)} kWh (${percentage.toStringAsFixed(0)}% de la capacidad)',
            style: TextStyle(
              color: isExceeding ? Colors.red : Colors.white60,
              fontSize: 12,
            ),
          ),
          if (isExceeding)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '💡 Recomendación: Desconecta algunos dispositivos o conéctalos en la hora pico (${weather.peakHour})',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}