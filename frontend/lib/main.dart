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
      print('Checking login status...');
      setState(() {
        _isLoading = true;
      });

      final isLoggedIn = await _authService.isLoggedIn();
      print('User is logged in: $isLoggedIn');
      
      if (!isLoggedIn) {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _hasCompletedOnboarding = false;
            _isLoading = false;
          });
        }
        return;
      }
      
      // Only check onboarding status if the user is logged in
      final hasCompletedOnboarding = await _authService.hasCompletedOnboarding();
      print('Onboarding completed: $hasCompletedOnboarding');
      
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
              ? '/swipe'  // Always go to swipe screen if logged in
              : '/auth'),
      // Remove '/swipe' from here so onGenerateRoute handles it.
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth': (context) => AuthScreen(),
        '/home': (context) => HomeScreen(),
        '/favourites': (context) => FavouritesScreen(),
        '/details': (context) => RestaurantDetailsScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/onboarding': (context) => OnboardingScreen(),
      },
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
