import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import '../services/api_service.dart';
import '../models/restaurant.dart';

class SwipeScreen extends StatefulWidget {
  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final SwipableStackController _controller = SwipableStackController();
  final ApiService _apiService = ApiService();

  List<Restaurant> _restaurants = [];
  int _offset = 0;
  final int _limit = 10;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);

    try {
      final newRestaurants = await _apiService.fetchRestaurants(
        offset: _offset,
        limit: _limit,
      );
      if (newRestaurants.isNotEmpty) {
        setState(() {
          _restaurants.addAll(newRestaurants);
          _offset += _limit;
        });
      }
    } catch (e) {
      print("Error fetching restaurants: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _onSwipeCompleted(int index, SwipeDirection direction) {
    print("Swiped card $index: ${direction == SwipeDirection.right ? 'LIKE' : 'NOPE'}");

    if (_restaurants.length - index <= 3) {
      _fetchRestaurants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
        title: Text(
          "Swipe Restaurants",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: Colors.red),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
        ],
      ),
      body: _restaurants.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// **Swipable Stack**
                Expanded(
                  flex: 8,
                  child: Center( // Ensures proper centering
                    child: SwipableStack(
                      controller: _controller,
                      itemCount: _restaurants.length,
                      onSwipeCompleted: _onSwipeCompleted,
                      builder: (BuildContext context, int index, BoxConstraints constraints) {
                        final Restaurant restaurant = _restaurants[index];

                        return Align(
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: constraints.maxWidth * 0.85, // Slightly smaller cards
                              height: constraints.maxHeight * 0.8, // Moves cards up slightly
                              margin: EdgeInsets.only(top: 10), 
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://via.placeholder.com/600x800?text=No+Image',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.6),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                padding: EdgeInsets.only(bottom: 80, left: 20, right: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 4,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    if (restaurant.cuisine1 != null)
                                      Text(
                                        restaurant.cuisine1!,
                                        style: TextStyle(color: Colors.white, fontSize: 16),
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                /// **Action Buttons Below**
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20), 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.close,
                          color: Colors.red,
                          onPressed: () {
                            _controller.next(swipeDirection: SwipeDirection.left);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.replay,
                          color: Colors.yellow,
                          onPressed: () {
                            _controller.rewind();
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.favorite,
                          color: Colors.green,
                          onPressed: () {
                            _controller.next(swipeDirection: SwipeDirection.right);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// **Circular Button Builder**
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
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
