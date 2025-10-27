import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

String timeAgoSinceDate(Timestamp? timestamp) {
  if (timestamp == null) {
    return 'N/A'; 
  }
  
  final DateTime now = DateTime.now();
  final DateTime date = timestamp.toDate();
  final Duration diff = now.difference(date);

  if (diff.inSeconds < 60) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    return '$minutes min${minutes == 1 ? '' : 's'} ago';
  } else if (diff.inHours < 24) {
    final hours = diff.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  } else if (diff.inDays < 7) {
    final days = diff.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  } else if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  } else if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '$months month${months == 1 ? '' : 's'} ago';
  } else {
    final years = (diff.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }
}

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

class ChatMessage {
  final String? id; 
  final String sender;
  final String message;
  final String route;
  final String imageUrl;
  final String? senderUid; 
  int likes;
  int dislikes;
  
  UserInteraction userInteraction; 
  
  final bool isMostHelpful;
  final Timestamp? createdAt; 

  ChatMessage({
    this.id, 
    required this.sender,
    required this.message,
    required this.route,
    required this.imageUrl,
    this.senderUid, 
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
      imageUrl: data['imageUrl'] ?? '',
      senderUid: data['senderUid'] as String?, 
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
      'senderUid': senderUid, 
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
    
    if (likeChange != 0 || dislikeChange != 0) {
      batch.update(messageRef, {
        'likes': FieldValue.increment(likeChange),
        'dislikes': FieldValue.increment(dislikeChange),
      });
    }

    batch.set(voteRef, {
      'isLiked': newIsLiked,
      'isDisliked': newIsDisliked,
      'timestamp': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
      
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
  
  Future<void> _handleReport(ChatMessage message) async {
    if (widget.currentUserId == null || message.id == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report a comment.'), backgroundColor: Colors.red),
      );
      return;
    }

    final messageId = message.id!;
    final userId = widget.currentUserId!;

    final reportRef = widget.firestore
        .collection('public_data')
        .doc('zapac_community')
        .collection('comments')
        .doc(messageId)
        .collection('reports')
        .doc(userId);

    try {
      await reportRef.set({
        'reporterUid': userId,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      final messageRef = widget.firestore
          .collection('public_data')
          .doc('zapac_community')
          .collection('comments')
          .doc(messageId);
          
      await messageRef.set({'reportCount': FieldValue.increment(1)}, SetOptions(merge: true));
      
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              contentPadding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 8), 
              actionsPadding: const EdgeInsets.only(right: 15, bottom: 5), 
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Comment Reported',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'We will review this insight shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error reporting message $messageId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to report comment. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }


  Future<void> _deleteMessage(ChatMessage message) async {
    if (widget.currentUserId == null || message.senderUid == null || message.id == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Missing user or message ID.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (widget.currentUserId != message.senderUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own insights.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 5.0),
          content: const Text('Are you sure you want to delete this insight? This action cannot be undone.'),
          actionsPadding: const EdgeInsets.only(right: 15.0, bottom: 12.0),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final loadingContext = context; 
    
    showGeneralDialog(
        context: loadingContext,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 150),
        barrierColor: Colors.black.withOpacity(0.7),
        pageBuilder: (context, a1, a2) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                ),
            );
        },
    );

    try {
      final messageRef = widget.firestore
          .collection('public_data')
          .doc('zapac_community')
          .collection('comments')
          .doc(message.id!);

      await messageRef.delete();
      
      if (loadingContext.mounted) {
          Navigator.of(loadingContext).pop();
      }

    } catch (e) {
      print("Error deleting message ${message.id}: $e");
      
      if (loadingContext.mounted) {
          Navigator.of(loadingContext).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete insight.'), backgroundColor: Colors.red),
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
    final timeDisplay = timeAgoSinceDate(message.createdAt);
    
    final bool isCurrentUserSender = 
        widget.currentUserId != null && 
        message.senderUid != null &&
        widget.currentUserId == message.senderUid;

    final bool hasImageUrl = message.imageUrl.isNotEmpty;
    final String initials = message.sender.isNotEmpty ? message.sender[0].toUpperCase() : '?';


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
                backgroundColor: hasImageUrl ? Colors.transparent : colorScheme.primary, 
                backgroundImage: hasImageUrl
                    ? NetworkImage(message.imageUrl) as ImageProvider<Object>?
                    : null,
                child: hasImageUrl
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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
                        PopupMenuButton<String>(
                          onSelected: (String result) {
                            if (result == 'delete' && message.id != null) {
                              _deleteMessage(message);
                            } else if (result == 'report' && message.id != null) {
                                _handleReport(message);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'report',
                              child: Text('Report'),
                            ),
                            if (isCurrentUserSender)
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                          ],
                          icon: Icon(
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
          Padding(
            padding: const EdgeInsets.only(left: 61),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _handleVote(message, true),
                  child: Row(
                    children: [
                      Icon(
                        interaction.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: interaction.isLiked ? Colors.blue : dividerColor,
                        size: iconSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.likes.toString(),
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () => _handleVote(message, false),
                  child: Row(
                    children: [
                      Icon(
                        interaction.isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                        color: interaction.isDisliked ? Colors.red : dividerColor,
                        size: iconSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.dislikes.toString(),
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
    
    final List<ChatMessage> currentMessages = widget.chatMessages.map((msg) {
        if (msg.id != null && _userInteractions.containsKey(msg.id)) {
          return ChatMessage(
            id: msg.id,
            sender: msg.sender,
            message: msg.message,
            route: msg.route,
            imageUrl: msg.imageUrl,
            senderUid: msg.senderUid, 
            likes: msg.likes,
            dislikes: msg.dislikes,
            isMostHelpful: msg.isMostHelpful,
            createdAt: msg.createdAt,
            userInteraction: _userInteractions[msg.id]!,
          );
        }
        return msg;
    }).toList(); 

    final filteredMessages = currentMessages.where((message) {
      if (_selectedFilter == 'All') return true;

      final messageLower = message.message.toLowerCase();

      switch (_selectedFilter) {
        case 'Warning':
          return messageLower.contains('traffic') ||
                 messageLower.contains('accident') ||
                 messageLower.contains('danger') ||
                 messageLower.contains('slow') ||
                 messageLower.contains('kuyaw') ||
                 messageLower.contains('trapik') ||
                 messageLower.contains('aksidente') ||
                 messageLower.contains('hinay') ||
                 messageLower.contains('slide') ||
                 messageLower.contains('slippery') ||
                 messageLower.contains('baha') ||
                 messageLower.contains('flood') ||
                 messageLower.contains('landslide') ||
                 messageLower.contains('atang') ||
                 messageLower.contains('kidnap') ||
                 messageLower.contains('holdup') ||
                 messageLower.contains('tulis') ||
                 messageLower.contains('manulis') ||
                 messageLower.contains('ngitngit') ||
                 messageLower.contains('dark') ||
                 messageLower.contains('snatch') ||
                 messageLower.contains('hole') ||
                 messageLower.contains('buslot') ||
                 messageLower.contains('lubak') ||
                 messageLower.contains('bangga');
                 
        case 'Shortcuts':
          return messageLower.contains('shortcut') ||
                 messageLower.contains('faster') ||
                 messageLower.contains('route') ||
                 messageLower.contains('quick') ||
                 messageLower.contains('lusot') ||
                 messageLower.contains('dali');
                 
        case 'Fare Tips':
          return messageLower.contains('fare') ||
                 messageLower.contains('price') ||
                 messageLower.contains('cost') ||
                 messageLower.contains('plete') ||
                 messageLower.contains('sukli') ||
                 messageLower.contains('tagpila') ||
                 messageLower.contains('bayad');
                 
        case 'Driver Reviews':
          return messageLower.contains('driver') ||
                 messageLower.contains('reckless') ||
                 messageLower.contains('rude') ||
                 messageLower.contains('kind') ||
                 messageLower.contains('buotan') ||
                 messageLower.contains('barato');
                 
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
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    return _buildInsightCard(filteredMessages[index]);
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