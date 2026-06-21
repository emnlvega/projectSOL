import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location_package;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectsol/providers/weather_provider.dart';
import 'package:projectsol/providers/settings_provider.dart';
import 'package:projectsol/screens/widgets/gradient_background.dart';
import 'package:geocoding/geocoding.dart';

class RadiationMapScreen extends StatefulWidget {
  const RadiationMapScreen({super.key});

  @override
  State<RadiationMapScreen> createState() => _RadiationMapScreenState();
}

class _RadiationMapScreenState extends State<RadiationMapScreen> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = const LatLng(32.5, -117.0);
  bool _isLoading = true;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    
    // Obtener ubicación del provider de clima (que ya tiene la ubicación seleccionada)
    final customLat = await _getCustomLat();
    final customLon = await _getCustomLon();
    final customName = await _getCustomName();
    
    if (customLat != null && customLon != null) {
      setState(() {
        _currentPosition = LatLng(customLat, customLon);
        _locationName = customName;
        _isLoading = false;
      });
    } else {
      // Si no hay ubicación personalizada, usar GPS
      try {
        final position = await _getCurrentLocation();
        if (position != null) {
          setState(() {
            _currentPosition = LatLng(position.latitude!, position.longitude!);
            _isLoading = false;
          });
          // Obtener nombre de la ubicación
          _getLocationName(position.latitude!, position.longitude!);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    // Actualizar círculos después de tener la ubicación
    _updateRadiationCircles();
  }

  Future<double?> _getCustomLat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('custom_lat');
  }

  Future<double?> _getCustomLon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('custom_lon');
  }

  Future<String> _getCustomName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_location_name') ?? '';
  }

  Future<location_package.LocationData?> _getCurrentLocation() async {
    try {
      final location = location_package.Location();
      final serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        await location.requestService();
      }

      final permission = await location.hasPermission();
      if (permission == location_package.PermissionStatus.denied) {
        await location.requestPermission();
      }

      return await location.getLocation();
    } catch (e) {
      return null;
    }
  }

  Future<void> _getLocationName(double lat, double lon) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      final place = placemarks.first;
      setState(() {
        _locationName = '${place.locality ?? place.administrativeArea ?? place.country ?? ''}';
      });
    } catch (e) {
      setState(() {
        _locationName = 'Ubicación actual';
      });
    }
  }

  void _updateRadiationCircles() {
    final provider = Provider.of<WeatherProvider>(context, listen: false);
    final potential = provider.solarPotential / 100; // 0-1

    // Círculos de radiación alrededor de la ubicación seleccionada
    final baseRadius = 10000.0; // 10 km
    final baseOpacity = 0.2 + (potential * 0.6); // 0.2 a 0.8
    final baseColor = _getRadiationColor(potential);

    // Si la radiación es baja, mostrar menos círculos
    final circleCount = potential > 0.5 ? 3 : 2;

    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('radiation_center'),
          center: _currentPosition,
          radius: baseRadius * 0.8,
          fillColor: baseColor.withOpacity(baseOpacity),
          strokeColor: baseColor.withOpacity(0.8),
          strokeWidth: 2,
        ),
        Circle(
          circleId: const CircleId('radiation_mid'),
          center: _currentPosition,
          radius: baseRadius * 1.5,
          fillColor: baseColor.withOpacity(baseOpacity * 0.5),
          strokeColor: baseColor.withOpacity(0.4),
          strokeWidth: 1,
        ),
        if (circleCount > 2)
          Circle(
            circleId: const CircleId('radiation_outer'),
            center: _currentPosition,
            radius: baseRadius * 2.5,
            fillColor: baseColor.withOpacity(baseOpacity * 0.2),
            strokeColor: baseColor.withOpacity(0.2),
            strokeWidth: 1,
          ),
      };

      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: _locationName.isNotEmpty ? _locationName : 'Ubicación seleccionada',
            snippet: 'Radiación: ${(potential * 100).toStringAsFixed(0)}%',
          ),
        ),
      };
    });
  }

  Color _getRadiationColor(double potential) {
    if (potential > 0.8) return Colors.red;
    if (potential > 0.6) return Colors.orange;
    if (potential > 0.4) return Colors.yellow;
    if (potential > 0.2) return Colors.lightGreen;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final potential = provider.solarPotential;
    final locationName = provider.currentLocationName;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Radiación Solar'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadLocationData();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Mapa
            Expanded(
              flex: 3,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition,
                        zoom: 11.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      circles: _circles,
                      markers: _markers,
                    ),
            ),
            // Leyenda e información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ubicación actual
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationName.isNotEmpty ? locationName : 'Ubicación seleccionada',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Potencial solar: ${potential.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Leyenda de Radiación Solar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildLegendItem(Colors.blue, '0-20%'),
                      _buildLegendItem(Colors.lightGreen, '20-40%'),
                      _buildLegendItem(Colors.yellow, '40-60%'),
                      _buildLegendItem(Colors.orange, '60-80%'),
                      _buildLegendItem(Colors.red, '80-100%'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Los círculos muestran la intensidad de radiación en tu área.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El mapa se centra en la ubicación que tienes seleccionada.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}