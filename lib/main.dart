import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectsol/providers/weather_provider.dart';
import 'package:projectsol/providers/settings_provider.dart';
import 'package:projectsol/providers/history_provider.dart';
import 'package:projectsol/screens/dashboard_screen.dart';
import 'package:projectsol/screens/onboarding_screen.dart';
import 'package:projectsol/screens/settings_screen.dart';
import 'package:projectsol/screens/extended_forecast_screen.dart';
import 'package:projectsol/services/notification_service.dart';
import 'package:projectsol/screens/radiation_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'projectSOL',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            foregroundColor: Colors.white,
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/settings': (context) => const SettingsScreen(),
          '/extended_forecast': (context) => const ExtendedForecastScreen(),
          '/radiation_map': (context) => const RadiationMapScreen(),
        },
      ),
    );
  }
}



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    
    // Pequeña pausa para mostrar el splash
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => completed 
              ? const DashboardScreen() 
              : const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E17),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Cargando projectSOL...',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}