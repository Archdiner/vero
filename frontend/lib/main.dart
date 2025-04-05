import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/swipe_screen.dart';
import 'screens/favourites_screen.dart';
import 'screens/restaurant_details_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/update_profile_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'utils/supabase_config.dart' as supabase_config;
import 'utils/themes.dart'; // Import our new themes
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize Flutter bindings synchronously - this is required
  // to avoid the white screen on startup
  WidgetsFlutterBinding.ensureInitialized();
  
  // First show a black screen to avoid white flash
  runApp(
    MaterialApp(
      home: Container(color: Colors.black),
      debugShowCheckedModeBanner: false,
    )
  );
  
  // Then on the next frame, start the actual app - avoids white screen flash
  Future.microtask(() {
    // Start the app immediately 
    runApp(const TinderForRestaurants());

    // Initialize Supabase in the background after app has started
    _initializeSupabaseInBackground();
  });
}

// Keep Supabase initialization completely separate and in background
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

class TinderForRestaurants extends StatefulWidget {
  const TinderForRestaurants({super.key});

  @override
  _TinderForRestaurantsState createState() => _TinderForRestaurantsState();
}

class _TinderForRestaurantsState extends State<TinderForRestaurants> {
  // Use a navigator key to better control transitions
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    print('App started');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tinder for Restaurants',
      theme: AppTheme.darkTheme, // Use our dark theme with blue accent colors
      
      // Use navigator key to better control transitions
      navigatorKey: _navigatorKey,
      
      // Always start with splash screen - it handles auth checking
      initialRoute: '/splash',
      
      // Performance optimizations to avoid white screen
      themeMode: ThemeMode.dark, // Force dark mode for faster initial render
      
      // Additional settings to speed up initial render
      color: Colors.black, // Fill background color immediately
      
      // Routes configuration
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth': (context) => AuthScreen(),
        '/home': (context) => HomeScreen(),
        '/favourites': (context) => FavouritesScreen(),
        '/details': (context) => RestaurantDetailsScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/update_profile': (context) => UpdateProfileScreen()
      },
      
      // Route generation with no transitions for faster navigation
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/swipe') {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => SwipeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        } else if (settings.name == '/profile') {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => ProfileScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        } else if (settings.name == '/matches') {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => MatchesScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        }
        return null; // For other routes, use default routing.
      },
    );
  }
}
