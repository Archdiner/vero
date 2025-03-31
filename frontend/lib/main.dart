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
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'utils/supabase_config.dart' as supabase_config;
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
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
  
  runApp(const TinderForRestaurants());
}

class TinderForRestaurants extends StatefulWidget {
  const TinderForRestaurants({super.key});

  @override
  _TinderForRestaurantsState createState() => _TinderForRestaurantsState();
}

class _TinderForRestaurantsState extends State<TinderForRestaurants> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    print('App started, checking login status...');
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      final hasCompletedOnboarding = await _authService.hasCompletedOnboarding();
      print('Login check completed. User logged in: $isLoggedIn, Onboarding completed: $hasCompletedOnboarding');
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _hasCompletedOnboarding = hasCompletedOnboarding;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking login status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _hasCompletedOnboarding = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building app with loading: $_isLoading, logged in: $_isLoggedIn, onboarding completed: $_hasCompletedOnboarding');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tinder for Restaurants',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      initialRoute: _isLoading 
        ? '/splash' 
        : (_isLoggedIn 
          ? '/swipe'  // If logged in, go to swipe screen regardless of onboarding status
          : '/auth'),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth': (context) => AuthScreen(),
        '/home': (context) => HomeScreen(),
        '/swipe': (context) => SwipeScreen(),
        '/favourites': (context) => FavouritesScreen(),
        '/details': (context) => RestaurantDetailsScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/profile': (context) => ProfileScreen(),
        '/onboarding': (context) => OnboardingScreen()
      },
    );
  }
}
