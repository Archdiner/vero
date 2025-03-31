import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'dart:math' show min;

// Example placeholders for your services and models
import '../services/api_service.dart';
import '../models/restaurant.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({Key? key}) : super(key: key);

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
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
    _fetchUserName();
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

  Future<void> _fetchUserName() async {
    try {
      final name = await _apiService.getUserName();
      if (mounted) {
        setState(() {
          _userName = name;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  void _onSwipeCompleted(int index, SwipeDirection direction) {
    print("Swiped card $index: ${direction == SwipeDirection.right ? 'LIKE' : 'DISLIKE'}");

    // If near the end, fetch more
    if (_restaurants.length - index <= 3) {
      _fetchRestaurants();
    }
  }

  // New method to toggle favorite status for a restaurant
  Future<void> _toggleFavorite(Restaurant restaurant) async {
    try {
      final bool updatedFavoriteState = await _apiService.toggleFavorite(
        restaurant.chainId
      );
      setState(() {
        restaurant.isFavorited = updatedFavoriteState;
      });
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // dark background
      body: SafeArea(
        child: Column(
          children: [
            // ===== TOP BAR (Avatar, "Hello [name]!", location, bell) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Example avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(
                      'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Greeting & location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello ${_userName}!",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Your location",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification icon
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ===== SEARCH BAR + ORANGE SQUARE ICON =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Search",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    // Orange square with the filter icon
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6F40), // brand orange
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: () {
                          // handle filter
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ===== SWIPE STACK =====
            Expanded(
              child: _restaurants.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SwipableStack(
                      controller: _controller,
                      itemCount: _restaurants.length,
                      onSwipeCompleted: _onSwipeCompleted,
                      builder: (context, index, constraints) {
                        final restaurant = _restaurants[index];
                        return _buildRestaurantCard(context, constraints, restaurant);
                      },
                    ),
            ),

            // ===== BOTTOM NAVIGATION (3 icons) =====
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Left: search icon (orange) to indicate current screen
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFFFF6F40)),
                    onPressed: () {
                      // Already on search screen?
                    },
                  ),
                  // Center: three-dot icon (gray)
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white54),
                    onPressed: () {
                      // handle middle nav
                    },
                  ),
                  // Right: person icon (gray)
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white54),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/profile');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    BoxConstraints constraints,
    Restaurant restaurant,
  ) {
    // Slightly smaller so it doesn't get chopped
    final cardWidth = constraints.maxWidth * 0.9;
    final cardHeight = constraints.maxHeight * 0.75;

    return Align(
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none, // allow buttons to overflow
        children: [
          // Main card with gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://via.placeholder.com/600x800?text=No+Image',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Dark gradient at bottom
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),

                  // Restaurant info
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 60, // space for the buttons
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "Location" chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Location",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Name
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Rating
                        if (restaurant.avgRating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.yellow, size: 20),
                              const SizedBox(width: 5),
                              Text(
                                restaurant.avgRating!.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ],

                        // Example tags
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTag("Tag 01"),
                            _buildTag("Tag 02"),
                            _buildTag("Tag 03"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Responsive Bookmark/Save Icon
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: () {
                _toggleFavorite(restaurant);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  restaurant.isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: restaurant.isFavorited ? const Color(0xFFFF6F40) : Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

          // ===== "Nope" & "Like" Buttons =====
          Positioned(
            bottom: -20, // overlap the card
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // NOPE Button (dark pill)
                InkWell(
                  onTap: () {
                    _controller.next(swipeDirection: SwipeDirection.left);
                  },
                  child: Container(
                    width: 130, // tweak width
                    height: 50, // tweak height
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C), // dark gray
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.close, color: Color(0xFFFF6F40), size: 27),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),

                // LIKE Button (orange pill)
                InkWell(
                  onTap: () {
                    _controller.next(swipeDirection: SwipeDirection.right);
                  },
                  child: Container(
                    width: 130,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6F40),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.favorite, color: Colors.white, size: 27),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
