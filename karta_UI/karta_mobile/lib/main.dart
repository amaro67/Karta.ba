import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karta_shared/karta_shared.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'config/routes.dart';

// DEMO MODE: Set to true to skip login and see the design immediately
const bool isDemoMode = false; // Set to false to use real login/register flow

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale data for date formatting (bosanski)
  await initializeDateFormatting('bs', null);
  
  // Set the client type for API calls
  ApiClient.clientType = 'karta_mobile';
  
  runApp(const KartaMobileApp());
}

class KartaMobileApp extends StatelessWidget {
  const KartaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, EventProvider>(
          create: (context) => EventProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => EventProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TicketProvider>(
          create: (context) => TicketProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => TicketProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Karta.ba',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
            routes: AppRoutes.routes,
          );
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Demo mode: Skip authentication and go straight to home screen
    if (isDemoMode) {
      await Future.delayed(const Duration(seconds: 1)); // Show splash briefly
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }

    // Initialize auth provider
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    // Navigate based on authentication status
    if (authProvider.isAuthenticated) {
      final user = authProvider.currentUser;
      if (user != null) {
        if (user.roles.contains('Scanner')) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.scannerHome);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'karta.ba',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
