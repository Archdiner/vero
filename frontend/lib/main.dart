import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/home_screen.dart';
import 'screens/swipe_screen.dart';
import 'screens/favourites_screen.dart';
import 'screens/restaurant_details_screen.dart';

void main() {
  runApp(TinderForRestaurants());
}

class TinderForRestaurants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tinder for Restaurants',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth': (context) => AuthScreen(),
        '/preferences': (context) => PreferencesScreen(),
        '/home': (context) => HomeScreen(),
        '/swipe': (context) => SwipeScreen(),
        '/favourites': (context) => FavouritesScreen(),
        '/details': (context) => RestaurantDetailsScreen(),
      },
    );
  }
}


/*

import 'package:flutter/material.dart';
import 'package:tcard/tcard.dart';

void main() {
  runApp(TinderForRestaurants());
}

class TinderForRestaurants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RestaurantSwipeScreen(),
    );
  }
}

//enum SwipeDirection { left, right }

class RestaurantSwipeScreen extends StatefulWidget {
  @override
  _RestaurantSwipeScreenState createState() => _RestaurantSwipeScreenState();
}


class _RestaurantSwipeScreenState extends State<RestaurantSwipeScreen> {
  final TCardController _controller = TCardController();

  final List<Map<String, String>> restaurants = [
    {
      'name': 'McDonald’s',
      'rating': '3.8',
      'cuisine': 'American • Fast Food',
      'location': 'Saar',
      'image': 'https://your-image-url.com', // Replace with API data later
    },
    {
      'name': 'KFC',
      'rating': '4.1',
      'cuisine': 'Fried Chicken • Fast Food',
      'location': 'Manama',
      'image': 'https://your-image-url.com', // Replace with API data later
    },
  ];

  

 void _onSwipe(SwipDirection direction, int index) {
  if (direction == SwipDirection.Right) {
    print("Liked ${restaurants[index]['name']}");
  } else if (direction == SwipDirection.Left) {
    print("Disliked ${restaurants[index]['name']}");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Swiping Cards
          Positioned.fill(
            child: TCard(
              controller: _controller,
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height * 0.8),
              cards: restaurants.map((restaurant) => _buildRestaurantCard(restaurant)).toList(),
              onForward: (index, info) {
                _onSwipe(info.direction, index);
              },
              onEnd: () {
                print("No more restaurants!");
              },
            )
          ),
          // Bottom Buttons
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.close, Colors.red, () {
                  _controller.forward(direction: SwipDirection.Left);
                }),
                _buildActionButton(Icons.arrow_back, Colors.yellow, () {
                  _controller.back();
                }),
                _buildActionButton(Icons.favorite, Colors.green, () {
                  _controller.forward(direction: SwipDirection.Right);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, String> restaurant) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(restaurant['image']!),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.only(bottom: 100, left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant['name']!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow, size: 20),
                SizedBox(width: 5),
                Text(
                  restaurant['rating']!,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              restaurant['cuisine']!,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 20),
                SizedBox(width: 5),
                Text(
                  restaurant['location']!,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: onPressed,
      ),
    );
  }
}

*/
