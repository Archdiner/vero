import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/roommate_service.dart';
import 'package:intl/intl.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final RoommateService _roommateService = RoommateService();
  List<UserProfile> _matches = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final matches = await _roommateService.fetchMatches();
      
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching matches: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to format match date
  String _formatMatchDate(String? matchedAt) {
    if (matchedAt == null) return 'Recently';
    
    try {
      final date = DateTime.parse(matchedAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Just now';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      print('Error parsing date: $e');
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Your Matches',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMatches,
            color: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6F40)),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load matches',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchMatches,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F40),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : _matches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: Colors.white54,
                              size: 72,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No matches yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'When you and another person both like each other, they\'ll show up here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/swipe');
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('Find Roommates'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6F40),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMatches,
                        color: const Color(0xFFFF6F40),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _matches.length,
                          itemBuilder: (context, index) {
                            final match = _matches[index];
                            return _buildMatchCard(match);
                          },
                        ),
                      ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left: search icon (gray)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white54, size: 28),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/swipe');
              },
            ),
            // Center: chat icon (orange) to indicate current screen
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF6F40), size: 26),
              onPressed: () {
                // Already on matches screen
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
    );
  }

  Widget _buildMatchCard(UserProfile match) {
    // Calculate how long ago the match was created
    String matchTime = _formatMatchDate(match.matchedAt);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: () {
          _showMatchOptions(match);
        },
        child: Row(
          children: [
            // Profile image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                match.profilePicture.isNotEmpty
                    ? match.profilePicture
                    : 'https://via.placeholder.com/100?text=No+Image',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[800],
                    child: const Icon(Icons.person, color: Colors.white54, size: 40),
                  );
                },
              ),
            ),
            // User info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.age} • ${match.university}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (match.major != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        match.major!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    
                    // Display match date
                    const SizedBox(height: 4),
                    Text(
                      'Matched $matchTime',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    
                    // Display compatibility score if available
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFFF6F40),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          match.compatibilityScore != null
                            ? '${(match.compatibilityScore! * 100).toInt()}% Compatible'
                            : 'Compatible',
                          style: const TextStyle(
                            color: Color(0xFFFF6F40),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Chat button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  _showChatScreen(match);
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFFFF6F40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMatchOptions(UserProfile match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Match name
            Text(
              match.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Chat button
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFFFF6F40)),
              title: const Text(
                'Send Message',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showChatScreen(match);
              },
            ),
            
            // View Profile button
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white70),
              title: const Text(
                'View Profile',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDetailedProfile(match);
              },
            ),
            
            // Unmatch button
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text(
                'Unmatch',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showUnmatchConfirmation(match);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showChatScreen(UserProfile match) {
    // TODO: Implement chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat with ${match.fullName} coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showDetailedProfile(UserProfile match) {
    // TODO: Implement detailed profile view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${match.fullName}\'s profile coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showUnmatchConfirmation(UserProfile match) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Unmatch',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to unmatch with ${match.fullName}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _unmatchUser(match);
              },
              child: const Text(
                'Unmatch',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _unmatchUser(UserProfile match) async {
    try {
      // Use the RoommateService to unmatch with this user
      final success = await _roommateService.unmatchUser(match.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unmatched from ${match.fullName}'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh the matches list
        _fetchMatches();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unmatch. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error unmatching user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while unmatching.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
} 