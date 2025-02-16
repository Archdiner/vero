import 'package:flutter/material.dart';
import 'package:tcard/tcard.dart';
import '../services/api_service.dart';
import '../models/restaurant.dart';

class SwipeScreen extends StatefulWidget {
  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final TCardController _controller = TCardController();
  final ApiService _apiService = ApiService();

  List<Restaurant> _restaurants = [];
  int _offset = 0;
  final int _limit = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
  if (_isLoading) return; // Prevent duplicate calls
  setState(() => _isLoading = true);

  try {
    final newRestaurants = await _apiService.fetchRestaurants(
      offset: _offset, // Offset increases every fetch
      limit: _limit,
    );

    if (newRestaurants.isNotEmpty) {
      setState(() {
        _restaurants.addAll(newRestaurants);
        _offset += _limit; // Increase offset for the next batch
      });
    }
  } catch (e) {
    print('Error fetching restaurants: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}


  void _onSwipe(int index, bool isLiked) {
  if (index >= _restaurants.length - 3) { // When 3 cards left, fetch more
    _fetchRestaurants();
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: Colors.red),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
        ],
      ),
      body: _restaurants.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: TCard(
                    controller: _controller,
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height * 0.8,
                    ),
                    cards: _restaurants.map(_buildRestaurantCard).toList(),
                    onForward: (index, info) {
                      bool isLiked = info.direction == SwipDirection.Right;
                      _onSwipe(index, isLiked);
                    },
                    onEnd: () => _fetchRestaurants(),
                  ),
                ),
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

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://your-image-url.com'), // Replace with real images later
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
              restaurant.name,
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            if (restaurant.avgRating != null)
              Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow, size: 20),
                  SizedBox(width: 5),
                  Text(
                    restaurant.avgRating!.toStringAsFixed(1),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            SizedBox(height: 5),
            if (restaurant.cuisine1 != null)
              Text(
                restaurant.cuisine1!,
                style: TextStyle(color: Colors.white, fontSize: 16),
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
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: onPressed,
      ),
    );
  }
}
