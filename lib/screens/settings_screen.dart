import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectsol/providers/settings_provider.dart';
import 'package:projectsol/providers/weather_provider.dart';
import 'package:projectsol/screens/widgets/gradient_background.dart';
import 'package:projectsol/services/geocoding_service.dart';
import 'package:projectsol/screens/radiation_map_screen.dart';
import 'package:projectsol/screens/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _countController = TextEditingController();
  final _angleController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _locationController.text = settings.settings.customLocation;
      _capacityController.text = settings.settings.panelCapacity.toString();
      _countController.text = settings.settings.panelCount.toString();
      _angleController.text = settings.settings.panelAngle.toString();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _capacityController.dispose();
    _countController.dispose();
    _angleController.dispose();
    super.dispose();
  }

  void _searchLocation(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await GeocodingService.searchCity(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    final displayName = '${location['name']}${location['state'] != null && location['state']!.isNotEmpty ? ', ${location['state']}' : ''}, ${location['country']}';
    _locationController.text = displayName;
    
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    
    settingsProvider.updateLocation(displayName);
    weatherProvider.updateLocation(
      location['lat'],
      location['lon'],
      displayName,
    );
    
    setState(() {
      _searchResults = [];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ubicación actualizada: $displayName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Configuración'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ubicación manual con autocompletado
            _buildSection(
              title: 'Ubicación Manual',
              icon: Icons.location_on,
              children: [
                TextField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Busca tu ciudad...',
                    labelStyle: const TextStyle(color: Colors.white60),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  onChanged: _searchLocation,
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D111C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        final name = location['name'] ?? '';
                        final state = location['state'] ?? '';
                        final country = location['country'] ?? '';
                        final subtitle = state.isNotEmpty ? '$state, $country' : country;
                        
                        return ListTile(
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          leading: const Icon(Icons.location_city, color: Colors.amber),
                          onTap: () => _selectLocation(location),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Escribe el nombre de tu ciudad y selecciona de la lista',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Paneles Solares
            _buildSection(
              title: 'Mi Sistema Solar',
              icon: Icons.solar_power,
              subtitle: 'Estos datos se usan en el planificador para calcular si tu consumo excede la capacidad de tus paneles.',
              children: [
                TextField(
                  controller: _capacityController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacidad por panel (kW)',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _countController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de paneles',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _angleController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ángulo de instalación (°)',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final capacity = double.tryParse(_capacityController.text) ?? 5.0;
                          final count = int.tryParse(_countController.text) ?? 1;
                          final angle = double.tryParse(_angleController.text) ?? 30.0;
                          settingsProvider.updatePanelSettings(capacity, count, angle);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configuración actualizada')),
                          );
                        },
                        child: const Text('Guardar Configuración'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total:',
                                style: TextStyle(color: Colors.white60, fontSize: 12)),
                            Text(
                              '${(settingsProvider.settings.panelCapacity * settingsProvider.settings.panelCount).toStringAsFixed(1)} kW',
                              style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Mapa de Radiación
            _buildSection(
              title: 'Mapa de Radiación',
              icon: Icons.map,
              subtitle: 'Visualiza la radiación solar en tu área',
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.wb_sunny, color: Colors.amber),
                  ),
                  title: const Text('Ver Mapa de Radiación', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Círculos de intensidad solar alrededor de tu ubicación', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RadiationMapScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Información del sistema
            _buildSection(
              title: 'Información del Sistema',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  leading: const Icon(Icons.storage, color: Colors.blue),
                  title: const Text('Datos almacenados', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${settingsProvider.appliances.length} electrodomésticos',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Volver a ver el tutorial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
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
            children: [
              Icon(icon, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}