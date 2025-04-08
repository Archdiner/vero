import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'dart:math' show min;
import 'package:url_launcher/url_launcher.dart';

// Import our new models and services
import '../models/user_profile.dart';
import '../services/roommate_service.dart';
import '../widgets/detailed_profile_view.dart';
import '../utils/themes.dart'; // Import our theme

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
    
    // Check if widget is still mounted before setting state
    if (mounted) {
      setState(() => _isFetching = true);
    } else {
      return; // Exit early if widget is no longer mounted
    }

    try {
      final newMatches = await _roommateService.fetchPotentialMatches(
        offset: _offset,
        limit: _limit,
      );
      
      print("Fetched ${newMatches.length} potential roommates");
      
      // Debug log the first profile to see what fields are available
      if (newMatches.isNotEmpty) {
        final firstProfile = newMatches[0];
        print('First profile data: ${firstProfile.fullName}, University: ${firstProfile.university}');
        print('Profile preferences: Cleanliness: ${firstProfile.cleanlinessLevel}, Sleep: ${firstProfile.sleepTime}, Wake: ${firstProfile.wakeTime}');
        print('More preferences: Smoking: ${firstProfile.smokingPreference}, Drinking: ${firstProfile.drinkingPreference}, Pets: ${firstProfile.petPreference}');
        print('Compatibility score: ${firstProfile.compatibilityScore}');
      }
      
      // Check if the widget is still mounted before calling setState
      if (!mounted) return;
      
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
      
      // Check if widget is still mounted before setting state
      if (mounted) {
        setState(() => _isFetching = false);
      }
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
    // ADDED: Get brightness for dynamic colors in dialog
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: brightness == Brightness.dark ? Colors.transparent : Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              color: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white, // CHANGED: dynamic background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryBlue, // remains the same
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
                          color: AppColors.primaryBlue, // remains the same
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You and ${matchedUser.fullName} have liked each other',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white70 : Colors.black54, // CHANGED
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
                                color: brightness == Brightness.dark ? Colors.white : Colors.black, // CHANGED
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
                                ? Icon(Icons.person, color: brightness == Brightness.dark ? Colors.white : Colors.black, size: 50) // CHANGED
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _userName.split(' ').first,
                            style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black), // CHANGED
                          ),
                        ],
                      ),
                      
                      // Heart icon between avatars
                      const Icon(
                        Icons.favorite,
                        color: AppColors.primaryBlue, // unchanged
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
                                color: brightness == Brightness.dark ? Colors.white : Colors.black, // CHANGED
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
                                ? Icon(Icons.person, color: brightness == Brightness.dark ? Colors.white : Colors.black, size: 50) // CHANGED
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            matchedUser.fullName.split(' ').first,
                            style: TextStyle(color: brightness == Brightness.dark ? Colors.white : Colors.black), // CHANGED
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
                            backgroundColor: AppColors.primaryBlue, // unchanged
                            foregroundColor: Colors.white, // keep white for contrast on blue
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
                            foregroundColor: brightness == Brightness.dark ? Colors.white : Colors.black, // CHANGED
                            side: BorderSide(color: brightness == Brightness.dark ? Colors.white : Colors.black, width: 1), // CHANGED
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Keep Swiping',
                            style: TextStyle(
                              fontSize: 16,
                              color: brightness == Brightness.dark ? Colors.white : Colors.black, // CHANGED
                            ),
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
    // ADDED: Obtain brightness for dynamic colors
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: brightness == Brightness.dark ? Colors.black : Colors.white, // CHANGED
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
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                              image: _currentUserProfile['profile_picture'] != null && 
                                     _currentUserProfile['profile_picture'].toString().isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_currentUserProfile['profile_picture']),
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) {
                                      print('Error loading profile image: $exception');
                                    })
                                : null,
                            ),
                            child: _currentUserProfile['profile_picture'] == null || 
                                  _currentUserProfile['profile_picture'].toString().isEmpty
                                ? Icon(Icons.person, color: brightness == Brightness.dark ? Colors.white : Colors.black)
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
                          style: TextStyle(
                            color: brightness == Brightness.dark ? Colors.white : Colors.black, // CHANGED
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentUserProfile['university'] ?? "Find your roommate",
                          style: TextStyle(
                            color: brightness == Brightness.dark ? Colors.white54 : Colors.black54, // CHANGED
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification icon
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_none, color: brightness == Brightness.dark ? Colors.white : Colors.black), // CHANGED
                  ),
                ],
              ),
            ),

            // ===== SWIPE STACK =====
            Expanded(
              child: _potentialMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isFetching
                              ? const CircularProgressIndicator(color: AppColors.primaryBlue)
                              : Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: brightness == Brightness.dark ? Colors.white54 : Colors.black54, // CHANGED
                                ),
                          const SizedBox(height: 16),
                          Text(
                            _isFetching 
                                ? "Finding roommates..." 
                                : _offset > 0
                                    ? "No more profiles to show"
                                    : "No profiles available",
                            style: TextStyle(
                              color: brightness == Brightness.dark ? Colors.white : Colors.black, // CHANGED
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                                style: TextStyle(color: brightness == Brightness.dark ? Colors.white70 : Colors.black54), // CHANGED
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
                                backgroundColor: AppColors.primaryBlue,
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
                  // Left: search icon (blue) to indicate current screen
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primaryBlue, size: 28),
                    onPressed: () {
                      // Already on search screen
                    },
                  ),
                  // Center: chat icon
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: brightness == Brightness.dark ? Colors.white54 : Colors.black54, size: 26), // CHANGED
                    onPressed: () {
                      // Navigate to matches screen
                      Navigator.pushReplacementNamed(context, '/matches');
                    },
                  ),
                  // Right: person icon (gray)
                  IconButton(
                    icon: Icon(Icons.person_outline, color: brightness == Brightness.dark ? Colors.white54 : Colors.black54, size: 28), // CHANGED
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
    // Adjusted card size to better fill the available space after removing the search bar
    final cardWidth = constraints.maxWidth * 0.9;
    final cardHeight = constraints.maxHeight * 0.90;
    final brightness = Theme.of(context).brightness;

    return Align(
      // Changed alignment to topCenter so the card sits higher with less white space above
      alignment: Alignment.topCenter,
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
                  // Add error handler for images
                  onError: (exception, stackTrace) => print('Error loading profile image: $exception'),
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
                            Colors.black.withOpacity(0.3),
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
                        // University chip - add null check
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
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
                                style: TextStyle(
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
                        
                        // Add compatibility score if available
                        if (userProfile.compatibilityScore != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: AppColors.primaryBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${userProfile.compatibilityScore!.toInt()}% Compatible',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                      color: brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey[300],
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
                        Icon(Icons.close, color: AppColors.primaryBlue, size: 28),
                        SizedBox(width: 8),
                        Text(
                          "NOPE",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
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
                      color: AppColors.primaryBlue,
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
                  color: brightness == Brightness.dark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brightness == Brightness.dark ? Colors.white : Colors.black, width: 1.5),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: brightness == Brightness.dark ? Colors.white : Colors.black,
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
    final brightness = Theme.of(context).brightness;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: brightness == Brightness.dark ? Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DetailedProfileView(
        userProfile: userProfile,
        onInstagramTap: (username) {
          if (username.isNotEmpty) {
            final instagramUrl = 'https://instagram.com/$username';
            _launchURL(instagramUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Instagram username not available'),
              ),
            );
          }
        },
        actionButtons: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
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
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Instagram'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Override dispose to cancel the SwipableStackController
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Add helper method to check if a profile has preference data, similar to matches_screen
  bool _hasAnyPreferences(UserProfile profile) {
    return profile.cleanlinessLevel != null ||
        profile.sleepTime != null ||
        profile.wakeTime != null ||
        profile.smokingPreference != null ||
        profile.drinkingPreference != null ||
        profile.petPreference != null ||
        profile.musicPreference != null ||
        profile.socialPreference != null ||
        (profile.guestPolicy != null && profile.guestPolicy!.isNotEmpty) ||
        (profile.roomTypePreference != null && profile.roomTypePreference!.isNotEmpty) ||
        (profile.religiousPreference != null && profile.religiousPreference!.isNotEmpty) ||
        (profile.dietaryRestrictions != null && profile.dietaryRestrictions!.isNotEmpty) ||
        profile.budgetRange != null;
  }
}
