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
    print("Swiped card $index: ${direction == SwipeDirection.right ? 'LIKE' : 'DISLIKE'}");

    // If near the end, fetch more
    if (_restaurants.length - index <= 3) {
      _fetchRestaurants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // dark background
      body: SafeArea(
        child: Column(
          children: [
            // ===== TOP BAR (Avatar, "Hello Sab!", location, bell) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Example avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150?text=Avatar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Greeting & location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Hello Sab !",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
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
    Restaurant r,
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
                          r.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Rating
                        if (r.avgRating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.yellow, size: 20),
                              const SizedBox(width: 5),
                              Text(
                                r.avgRating!.toStringAsFixed(1),
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
                    width: 130,  // tweak width
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
                        Icon(Icons.close, color: const Color(0xFFFF6F40), size: 27),
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



/*
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
*/