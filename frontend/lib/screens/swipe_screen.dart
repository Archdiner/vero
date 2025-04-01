import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'dart:math' show min;

// Import our new models and services
import '../models/user_profile.dart';
import '../services/roommate_service.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({Key? key}) : super(key: key);

  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final SwipableStackController _controller = SwipableStackController();
  final RoommateService _roommateService = RoommateService();

  List<UserProfile> _potentialMatches = [];
  int _offset = 0;
  final int _limit = 10;
  bool _isFetching = false;
  String _userName = '';
  Map<String, dynamic> _currentUserProfile = {};

  @override
  void initState() {
    super.initState();
    _fetchPotentialMatches();
    _fetchCurrentUserInfo();
  }

  Future<void> _fetchPotentialMatches() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);

    try {
      final newMatches = await _roommateService.fetchPotentialMatches(
        offset: _offset,
        limit: _limit,
      );
      
      print("Fetched ${newMatches.length} potential roommates");
      
      if (newMatches.isNotEmpty) {
        setState(() {
          _potentialMatches.addAll(newMatches);
          _offset += _limit;
          _isFetching = false;
        });
      } else {
        // No more matches found - show empty state
        setState(() {
          _isFetching = false;
          // Keep _potentialMatches as is (empty if initial load, or with remaining cards if mid-swiping)
        });
        
        // If this was an initial load (offset=0) and no profiles were found,
        // we should show the empty state immediately
        if (_offset == 0 && _potentialMatches.isEmpty) {
          print("No potential roommates available at all");
        } else if (_potentialMatches.isEmpty) {
          print("No more potential roommates to load");
        }
      }
    } catch (e) {
      print("Error fetching potential matches: $e");
      setState(() => _isFetching = false);
    }
  }

  Future<void> _fetchCurrentUserInfo() async {
    try {
      final profileData = await _roommateService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUserProfile = profileData;
          _userName = profileData['fullname'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  void _onSwipeCompleted(int index, SwipeDirection direction) {
    final swipedUser = _potentialMatches[index];
    
    if (direction == SwipeDirection.right) {
      // User liked this profile - Check if it's a match
      _checkForMatch(swipedUser);
      print("Liked user: ${swipedUser.fullName}");
    } else if (direction == SwipeDirection.left) {
      // User disliked this profile
      _roommateService.dislikeUser(swipedUser.id);
      print("Disliked user: ${swipedUser.fullName}");
    }

    // If near the end, fetch more
    if (_potentialMatches.length - index <= 3) {
      _fetchPotentialMatches();
    }
    
    // If this was the last card, check if we need to show empty state
    if (index == _potentialMatches.length - 1) {
      // Add a short delay to let the swipe animation finish
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _potentialMatches.length <= index + 1) {
          print("Last card swiped, checking for more profiles");
          setState(() {
            // Clear the list so we show the empty state while fetching
            if (_potentialMatches.length == index + 1) {
              _potentialMatches = [];
            }
          });
        }
      });
    }
  }

  void _checkForMatch(UserProfile matchedUser) async {
    try {
      // Call likeUser once and check if it resulted in a match
      final isMatch = await _roommateService.likeUser(matchedUser.id);
      
      if (isMatch && mounted) {
        // Show match dialog
        _showMatchDialog(matchedUser);
      }
    } catch (e) {
      print('Error checking for match: $e');
    }
  }
  
  void _showMatchDialog(UserProfile matchedUser) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6F40),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with match text
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      // Confetti or stars animation could be added here
                      const Text(
                        'It\'s a Match!',
                        style: TextStyle(
                          color: Color(0xFFFF6F40),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You and ${matchedUser.fullName} have liked each other',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // User avatars side by side
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Current user avatar
                      Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              image: _currentUserProfile['profile_picture'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(_currentUserProfile['profile_picture']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _currentUserProfile['profile_picture'] == null
                                ? const Icon(Icons.person, color: Colors.white, size: 50)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _userName.split(' ').first,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      
                      // Heart icon between avatars
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFFFF6F40),
                        size: 40,
                      ),
                      
                      // Matched user avatar
                      Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              image: matchedUser.profilePicture.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(matchedUser.profilePicture),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: matchedUser.profilePicture.isEmpty
                                ? const Icon(Icons.person, color: Colors.white, size: 50)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            matchedUser.fullName.split(' ').first,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // Send Message button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            // TODO: Navigate to chat with this user
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Chat with ${matchedUser.fullName} coming soon!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F40),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Send Message',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Keep Swiping button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Keep Swiping',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // dark background
      body: SafeArea(
        child: Column(
          children: [
            // ===== TOP BAR (Avatar, "Hello [name]!", location) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // User's avatar 
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: _currentUserProfile.isEmpty
                      ? Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        )
                      : Hero(
                          tag: 'user-profile-picture',
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF6F40),
                                width: 2,
                              ),
                              image: _currentUserProfile['profile_picture'] != null && 
                                     _currentUserProfile['profile_picture'].toString().isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_currentUserProfile['profile_picture']),
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) {
                                      print('Error loading profile image: $exception');
                                    }
                                  )
                                : null,
                            ),
                            child: _currentUserProfile['profile_picture'] == null || 
                                  _currentUserProfile['profile_picture'].toString().isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),
                  // Greeting & university
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName.isEmpty 
                            ? "Hello there!" 
                            : "Hello ${_userName.split(' ').first}!",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentUserProfile['university'] ?? "Find your roommate",
                          style: const TextStyle(
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

            // ===== SEARCH BAR + FILTER ICON =====
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
                          hintText: "Search for roommates",
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
                        color: const Color(0xFFFF6F40), // brand orange
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: () {
                          // TODO: Add filtering functionality later
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Filtering feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
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
              child: _potentialMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isFetching
                              ? const CircularProgressIndicator(color: Color(0xFFFF6F40))
                              : const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                          const SizedBox(height: 16),
                          Text(
                            _isFetching 
                                ? "Finding roommates..." 
                                : _offset > 0
                                    ? "No more profiles to show"
                                    : "No profiles available",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          if (!_isFetching) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _offset > 0
                                    ? "You've seen all available roommates. Check back later for new matches!"
                                    : "There are no potential roommates matching your criteria at this time.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Try to fetch again
                                _offset = 0;
                                _potentialMatches = [];
                                _fetchPotentialMatches();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("Try Again"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6F40),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : SwipableStack(
                      controller: _controller,
                      itemCount: _potentialMatches.length,
                      onSwipeCompleted: _onSwipeCompleted,
                      builder: (context, index, constraints) {
                        final userProfile = _potentialMatches[index];
                        return _buildUserProfileCard(context, constraints, userProfile);
                      },
                    ),
            ),

            // ===== BOTTOM NAVIGATION (3 icons) =====
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Left: search icon (orange) to indicate current screen
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFFFF6F40), size: 28),
                    onPressed: () {
                      // Already on search screen
                    },
                  ),
                  // Center: chat icon
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 26),
                    onPressed: () {
                      // Navigate to matches screen
                      Navigator.pushReplacementNamed(context, '/matches');
                    },
                  ),
                  // Right: person icon (gray)
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white54, size: 28),
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

  Widget _buildUserProfileCard(
    BuildContext context,
    BoxConstraints constraints,
    UserProfile userProfile,
  ) {
    // Slightly smaller so it doesn't get chopped
    final cardWidth = constraints.maxWidth * 0.9;
    final cardHeight = constraints.maxHeight * 0.85;

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
                  image: userProfile.profilePicture.isNotEmpty
                      ? NetworkImage(userProfile.profilePicture)
                      : const NetworkImage('https://via.placeholder.com/600x800?text=No+Image'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Dark gradient overlay for readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                            Colors.black.withOpacity(0.3), // light overlay at the top
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // User info at the bottom
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 80, // space for the buttons
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // University chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userProfile.university,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Name and Age
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${userProfile.fullName}, ${userProfile.age}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Year of Study (if available)
                        if (userProfile.yearOfStudy != null)
                          Text(
                            "Year ${userProfile.yearOfStudy}",
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),

                        // Bio (if available)
                        if (userProfile.bio != null && userProfile.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            userProfile.bio!,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                    width: 130,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C), // dark gray
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: Color(0xFFFF6F40), size: 28),
                        SizedBox(width: 8),
                        Text(
                          "NOPE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite, color: Colors.white, size: 26),
                        SizedBox(width: 8),
                        Text(
                          "LIKE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info button (top-right)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                // Show more detailed profile info
                _showDetailedProfile(context, userProfile);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
  
  void _showDetailedProfile(BuildContext context, UserProfile userProfile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header with image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        userProfile.profilePicture.isNotEmpty
                            ? userProfile.profilePicture
                            : 'https://via.placeholder.com/150?text=No+Image',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name, age, university details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${userProfile.fullName}, ${userProfile.age}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userProfile.university,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          if (userProfile.yearOfStudy != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              "Year ${userProfile.yearOfStudy}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Bio section
                if (userProfile.bio != null && userProfile.bio!.isNotEmpty) ...[
                  const Text(
                    "About Me",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProfile.bio!,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // NOPE Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller.next(swipeDirection: SwipeDirection.left);
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text("NOPE", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    
                    // LIKE Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller.next(swipeDirection: SwipeDirection.right);
                      },
                      icon: const Icon(Icons.favorite, color: Colors.white),
                      label: const Text("LIKE", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
