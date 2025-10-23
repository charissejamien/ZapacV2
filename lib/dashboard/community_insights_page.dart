import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

// 1. TIME AGO UTILITY FUNCTION
String timeAgoSinceDate(Timestamp? timestamp) {
  // Handles null timestamps from samples or delayed Firebase writes
  if (timestamp == null) {
    return 'N/A'; 
  }
  
  final DateTime now = DateTime.now();
  final DateTime date = timestamp.toDate();
  final Duration diff = now.difference(date);

  if (diff.inSeconds < 60) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes} mins ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} hours ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays} days ago';
  } else if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks weeks ago';
  } else if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '$months months ago';
  } else {
    final years = (diff.inDays / 365).floor();
    return '$years years ago';
  }
}

// --- UserInteraction Model (Constant) ---
@immutable 
class UserInteraction {
  final bool isLiked;
  final bool isDisliked;

  const UserInteraction({this.isLiked = false, this.isDisliked = false});

  factory UserInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return const UserInteraction(); 
    }
    return UserInteraction(
      isLiked: data['isLiked'] ?? false,
      isDisliked: data['isDisliked'] ?? false,
    );
  }
}

// --- ChatMessage Model ---
class ChatMessage {
  final String? id; 
  final String sender;
  final String message;
  final String route;
  // Removed timeAgo
  final String imageUrl;
  int likes;
  int dislikes;
  
  UserInteraction userInteraction; 
  
  bool isMostHelpful;
  
  final Timestamp? createdAt; 

  ChatMessage({
    this.id, 
    required this.sender,
    required this.message,
    required this.route,
    required this.imageUrl,
    this.likes = 0,
    this.dislikes = 0,
    this.userInteraction = const UserInteraction(), 
    this.isMostHelpful = false,
    this.createdAt, 
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      sender: data['sender'] ?? 'Anonymous',
      message: data['message'] ?? 'No message',
      route: data['route'] ?? 'Unknown Route',
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/50x50/cccccc/000000?text=User',
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      isMostHelpful: data['isMostHelpful'] ?? false,
      createdAt: data['createdAt'] as Timestamp?, 
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender': sender,
      'message': message,
      'route': route,
      'imageUrl': imageUrl,
      'likes': 0, 
      'dislikes': 0,
      'isMostHelpful': false,
      'createdAt': FieldValue.serverTimestamp(), 
    };
  }
}

class CommentingSection extends StatefulWidget {
  final ValueSetter<bool>? onExpansionChanged;
  final List<ChatMessage> chatMessages; 
  final String? currentUserId; 
  
  final FirebaseFirestore firestore = FirebaseFirestore.instance; 

  // FIX: Removed 'const' keyword
  CommentingSection({
    super.key,
    this.onExpansionChanged,
    required this.chatMessages,
    this.currentUserId, 
  });

  @override
  State<CommentingSection> createState() => _CommentingSectionState();
}

class _CommentingSectionState extends State<CommentingSection> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final TextEditingController _commentController = TextEditingController();
  
  bool _isSheetFullyExpanded = false;
  String _selectedFilter = 'All';

  Map<String, UserInteraction> _userInteractions = {};

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_handleExpansionChange);
    if (widget.currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchUserInteractions();
      });
    }
  }

  void _fetchUserInteractions() async {
    if (widget.currentUserId == null || widget.chatMessages.isEmpty || !mounted) return;

    final messagesWithIds = widget.chatMessages.where((msg) => msg.id != null).map((msg) => msg.id!).toSet();
    if (messagesWithIds.isEmpty) return;

    final newInteractions = <String, UserInteraction>{};

    for (final messageId in messagesWithIds) {
      try {
        final doc = await widget.firestore
            .collection('public_data')
            .doc('zapac_community')
            .collection('comments')
            .doc(messageId)
            .collection('votes')
            .doc(widget.currentUserId!)
            .get();
        
        if (doc.exists) {
          newInteractions[messageId] = UserInteraction.fromFirestore(doc);
        }
      } catch (e) {
        print("Error fetching interaction for $messageId: $e");
      }
    }

    if (mounted) {
      setState(() {
        _userInteractions = newInteractions;
      });
    }
  }

  void _handleExpansionChange() {
    final bool isExpandedNow = _sheetController.size >= 0.85;
    if (isExpandedNow != _isSheetFullyExpanded) {
      if (mounted) {
        setState(() {
          _isSheetFullyExpanded = isExpandedNow;
        });
      }
      widget.onExpansionChanged?.call(_isSheetFullyExpanded); 
    }
  }

  @override
  void didUpdateWidget(covariant CommentingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatMessages.length != oldWidget.chatMessages.length || widget.currentUserId != oldWidget.currentUserId) {
      _fetchUserInteractions();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleVote(ChatMessage message, bool isLiking) async {
    if (widget.currentUserId == null || message.id == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to vote.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final messageId = message.id!;
    final userId = widget.currentUserId!;

    final messageRef = widget.firestore
        .collection('public_data')
        .doc('zapac_community')
        .collection('comments')
        .doc(messageId);
        
    final voteRef = messageRef.collection('votes').doc(userId);
    
    final currentInteraction = _userInteractions[messageId] ?? const UserInteraction();
    
    int likeChange = 0;
    int dislikeChange = 0;
    bool newIsLiked = currentInteraction.isLiked;
    bool newIsDisliked = currentInteraction.isDisliked;

    if (isLiking) {
      if (currentInteraction.isLiked) { 
        likeChange = -1;
        newIsLiked = false;
      } else { 
        likeChange = 1;
        newIsLiked = true;
        if (currentInteraction.isDisliked) { 
          dislikeChange = -1;
          newIsDisliked = false;
        }
      }
    } else { 
      if (currentInteraction.isDisliked) { 
        dislikeChange = -1;
        newIsDisliked = false;
      } else { 
        dislikeChange = 1;
        newIsDisliked = true;
        if (currentInteraction.isLiked) { 
          likeChange = -1;
          newIsLiked = false;
        }
      }
    }
    
    final batch = widget.firestore.batch();
    
    // 1. Update the global counters atomically
    if (likeChange != 0 || dislikeChange != 0) {
      batch.update(messageRef, {
        'likes': FieldValue.increment(likeChange),
        'dislikes': FieldValue.increment(dislikeChange),
      });
    }

    // 2. Set the user's vote status
    batch.set(voteRef, {
      'isLiked': newIsLiked,
      'isDisliked': newIsDisliked,
      'timestamp': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
      
      // 3. OPTIMISTIC UI UPDATE
      if (mounted) {
        setState(() {
          _userInteractions[messageId] = UserInteraction(
            isLiked: newIsLiked, 
            isDisliked: newIsDisliked
          );
        });
      }
      
    } catch (e) {
      print("Error committing vote: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update vote. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }


  Widget _buildInsightCard(ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    const iconSize = 20.0;
    final dividerColor = Theme.of(context).dividerColor;
    
    final interaction = _userInteractions[message.id] ?? message.userInteraction;
    
    // NEW: Calculate time ago dynamically
    final timeDisplay = timeAgoSinceDate(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(message.imageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.sender,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (message.isMostHelpful)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6CA89A).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '💡 Most Helpful',
                              style: TextStyle(
                                color: Color(0xFF6CA89A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTapDown: (details) async {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Menu functionality (Report/Delete) is active.')),
                            );
                          },
                          child: Icon(
                            Icons.more_horiz,
                            color: dividerColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // NEW: Display the calculated time
                    Text(
                      'Route: ${message.route}  |  $timeDisplay',
                      style: TextStyle(
                        color: textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Like/Dislike Buttons
          Padding(
            padding: const EdgeInsets.only(left: 61),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _handleVote(message, true), // Handle Like
                  child: Row(
                    children: [
                      Icon(
                        interaction.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: interaction.isLiked ? Colors.blue : dividerColor,
                        size: iconSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.likes.toString(), // Display global count from Firestore
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () => _handleVote(message, false), // Handle Dislike
                  child: Row(
                    children: [
                      Icon(
                        interaction.isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                        color: interaction.isDisliked ? Colors.red : dividerColor,
                        size: iconSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.dislikes.toString(), // Display global count from Firestore
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (mounted && selected) {
          setState(() => _selectedFilter = label);
        }
      },
      backgroundColor: const Color(0xFF6CA89A),
      selectedColor: const Color(0xFF4A6FA5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      showCheckmark: isSelected,
      checkmarkColor: Colors.white,
      avatar: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Inject the fetched user interaction state into the message objects for rendering
    final List<ChatMessage> currentMessages = widget.chatMessages.map((msg) {
        if (msg.id != null && _userInteractions.containsKey(msg.id)) {
          return ChatMessage(
            id: msg.id,
            sender: msg.sender,
            message: msg.message,
            route: msg.route,
            imageUrl: msg.imageUrl,
            likes: msg.likes,
            dislikes: msg.dislikes,
            isMostHelpful: msg.isMostHelpful,
            createdAt: msg.createdAt,
            userInteraction: _userInteractions[msg.id]!,
          );
        }
        return msg;
    }).toList(); 

    // Filter messages after injecting user interaction state
    final filteredMessages = currentMessages.where((message) {
      if (_selectedFilter == 'All') return true;

      final filterLower = _selectedFilter.toLowerCase();
      final messageLower = message.message.toLowerCase();

      switch (filterLower) {
        case 'warning':
          return messageLower.contains('traffic') ||
                 messageLower.contains('danger') ||
                 messageLower.contains('kuyaw') || 
                 messageLower.contains('beware');
        case 'shortcuts':
          return messageLower.contains('shortcut') ||
                 messageLower.contains('cut through') ||
                 messageLower.contains('faster route');
        case 'fare tips':
          return messageLower.contains('plete') || 
                 messageLower.contains('fare') ||
                 messageLower.contains('pesos');
        case 'driver reviews':
          return messageLower.contains('driver') ||
                 messageLower.contains('kuya driver');
        default:
          return true;
      }
    }).toList();


    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFDBA252) : const Color(0xFFF4BE6C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.black : Colors.black,
                        fontFamily: 'Roboto',
                      ),
                      children: [
                        const TextSpan(text: 'Taga '),
                        TextSpan(
                          text: 'ZAPAC',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        const TextSpan(text: ' says...'),
                      ],
                    ),
                  ),
                ),
              ),
              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Warning'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Shortcuts'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Fare Tips'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Driver Reviews'),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              // Comments List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    return _buildInsightCard(filteredMessages[index]); // Pass the updated message
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
