import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/swipe_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/update_profile_screen.dart';
import 'screens/update_preferences_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'utils/supabase_config.dart' as supabase_config;
import 'utils/themes.dart'; // Provides AppTheme and AppColors

/// Global theme notifier to switch between dark and light modes.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show a black screen initially to avoid a white flash.
  runApp(
    MaterialApp(
      home: Container(color: Colors.black),
      debugShowCheckedModeBanner: false,
    ),
  );

  // On the next microtask, load preferences, initialize Supabase, and start the app.
  Future.microtask(() async {
    // Load saved theme preference.
    final prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool('isDarkTheme') ?? true;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    // Initialize Supabase in the background.
    _initializeSupabaseInBackground();

    // Run the main app.
    runApp(const RoomioApp());
  });
}

/// Initialize Supabase in the background.
Future<void> _initializeSupabaseInBackground() async {
  try {
    final supabaseService = SupabaseService();
    await supabaseService.initialize(
      supabase_config.SUPABASE_URL,
      supabase_config.SUPABASE_ANON_KEY,
    );
    if (kDebugMode) {
      print('Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing Supabase: $e');
    }
  }
}

class RoomioApp extends StatefulWidget {
  const RoomioApp({super.key});

  @override
  _RoomioAppState createState() => _RoomioAppState();
}

class _RoomioAppState extends State<RoomioApp> {
  // Navigator key for better control over transitions.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('App started');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Roomio',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          navigatorKey: _navigatorKey,
          initialRoute: '/splash',
          color: Colors.black,
          routes: {
            '/splash': (context) => SplashScreen(),
            '/auth': (context) => AuthScreen(),
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/onboarding': (context) => OnboardingScreen(),
            '/update_profile': (context) => UpdateProfileScreen(),
            '/update_preferences': (context) => UpdatePreferencesScreen()
          },
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == '/swipe') {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SwipeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            } else if (settings.name == '/profile') {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ProfileScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            } else if (settings.name == '/matches') {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MatchesScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            }
            return null; // Use default routing for other routes.
          },
        );
      },
    );
  }
}
