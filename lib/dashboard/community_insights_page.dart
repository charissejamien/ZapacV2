import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapac/dashboard/models/chat_message.dart';
import 'package:zapac/dashboard/models/user_interaction.dart'; 
import 'package:zapac/core/widgets/insight_card.dart';
class CommentingSection extends StatefulWidget {
  final ValueSetter<bool>? onExpansionChanged;
  final List<ChatMessage> chatMessages; 
  final String? currentUserId; 
  // NEW: Accept hardcoded terminals
  final List<Map<String, dynamic>> hardcodedTerminals; 
  
  final FirebaseFirestore firestore = FirebaseFirestore.instance; 

  CommentingSection({
    super.key,
    this.onExpansionChanged,
    required this.chatMessages,
    this.currentUserId, 
    required this.hardcodedTerminals, // <--- NEW REQUIRED PROP
  });

  @override
  State<CommentingSection> createState() => _CommentingSectionState();
}

class _CommentingSectionState extends State<CommentingSection> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  bool _isSheetFullyExpanded = false;
  String _selectedFilter = 'All';
  // NEW: State to track which view is active in the sheet
  String _currentView = 'Insights'; // 'Insights' or 'Terminals'

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

    // FIX: Using null-aware access and simplifying the list creation
    final messagesWithIds = widget.chatMessages.where((msg) => msg.id != null).map((msg) => msg.id!).toSet();
    if (messagesWithIds.isEmpty) return;

    final newInteractions = <String, UserInteraction>{};

    for (final messageId in messagesWithIds) {
      try {
        // FIX: Access widget.currentUserId is safe here due to the null check above
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
        // Logger.error("Error fetching interaction for $messageId: $e");
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
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to vote.'), backgroundColor: Colors.red),
        );
      }
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
      // Logger.error("Error committing vote: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update vote. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _handleReport(ChatMessage message) async {
    if (widget.currentUserId == null || message.id == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to report a comment.'), backgroundColor: Colors.red),
        );
      }
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
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              // FIX: Replaced .background with .surface
              backgroundColor: colorScheme.surface, 
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
                      // FIX: Replaced .onBackground with .onSurface
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'We will review this insight shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      // FIX: Replaced .onBackground.withOpacity(0.7) with .onSurface.withAlpha(179)
                      color: colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    // FIX: Guard Navigator call
                    if (mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Logger.error("Error reporting message $messageId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to report comment. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }


  Future<void> _deleteMessage(ChatMessage message) async {
    if (widget.currentUserId == null || message.senderUid == null || message.id == null || !mounted) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete: Missing user or message ID.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (widget.currentUserId != message.senderUid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only delete your own insights.'), backgroundColor: Colors.red),
        );
      }
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
    
    // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
    showGeneralDialog(
        context: loadingContext,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 150),
        barrierColor: Colors.black.withAlpha(179),
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
      // FIX: Using null-aware access after previous null checks
      final messageRef = widget.firestore
          .collection('public_data')
          .doc('zapac_community')
          .collection('comments')
          .doc(message.id!);

      await messageRef.delete();
      
      if (loadingContext.mounted) {
          // FIX: Use loadingContext for navigation after async operation
          Navigator.of(loadingContext).pop(); 
      }

    } catch (e) {
      // Logger.error("Error deleting message ${message.id}: $e");
      
      if (loadingContext.mounted) {
          // FIX: Use loadingContext for navigation after async operation
          Navigator.of(loadingContext).pop(); 
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete insight.'), backgroundColor: Colors.red),
        );
      }
    }
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
  
  // MODIFIED: _buildTabButton now accepts an iconPath string
  Widget _buildTabButton(String label, String view, String iconPath, ColorScheme cs) {
    final bool isSelected = _currentView == view;
    const Color buttonBackgroundColor = Color(0xFFE6A84B); 
    
    final BorderSide border = isSelected 
      ? const BorderSide(color: Colors.white, width: 1.0)
      : const BorderSide(color: buttonBackgroundColor, width: 2.0);

    return SizedBox(
      width: 120, 
      height: 40, 
      child: TextButton(
        onPressed: () {
          if (!mounted) return;
          setState(() {
            _currentView = view;
          });
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: buttonBackgroundColor, 
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(8),
             side: border,
          ),
          minimumSize: Size.zero, 
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        // NEW: Use Row to place the image asset and text side-by-side
        child: Row( 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // **NOTE: Replace 'assets/icons/...' with your actual image paths**
            Image.asset(
              iconPath,
              width: 18, 
              height: 18,
              // Use color to tint the image white if it's a monochrome icon
              color: Colors.white, 
            ),
            const SizedBox(width: 8), 
            Text(
              label,
              style: const TextStyle( 
                fontWeight: FontWeight.bold,
                color: Colors.white, 
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // NEW: Widget to display a single Terminal Card
  Widget _buildTerminalCard(Map<String, dynamic> terminal, ColorScheme cs) {
    final details = terminal['details'] as Map<String, String>;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant, // Use a slight off-white/grey for card background
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300, 
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details['title'] ?? 'Terminal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: cs.primary,
              ),
            ),
            const Divider(height: 12),
            _buildTerminalDetailRow(Icons.access_time, 'Status', details['status'] ?? 'N/A', cs),
            _buildTerminalDetailRow(Icons.route, 'Routes', details['routes'] ?? 'N/A', cs),
            _buildTerminalDetailRow(Icons.local_convenience_store, 'Facilities', details['facilities'] ?? 'N/A', cs),
          ],
        ),
      ),
    );
  }

  // NEW: Helper for Terminal Detail Row
  Widget _buildTerminalDetailRow(IconData icon, String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.secondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: cs.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withAlpha(179),
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filteredMessages = widget.chatMessages.where((message) {
      if (_selectedFilter == 'All') return true;

      final messageLower = message.message.toLowerCase();

      switch (_selectedFilter) {
        case 'Warning':
          // ... (filter logic for Warning)
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
          // ... (filter logic for Shortcuts)
          return messageLower.contains('shortcut') ||
                 messageLower.contains('faster') ||
                 messageLower.contains('route') ||
                 messageLower.contains('quick') ||
                 messageLower.contains('lusot') ||
                 messageLower.contains('dali');
                 
        case 'Fare Tips':
          // ... (filter logic for Fare Tips)
          return messageLower.contains('fare') ||
                 messageLower.contains('price') ||
                 messageLower.contains('cost') ||
                 messageLower.contains('plete') ||
                 messageLower.contains('plite') ||
                 messageLower.contains('pliti') ||
                 messageLower.contains('pleti') ||
                 messageLower.contains('sukli') ||
                 messageLower.contains('tagpila') ||
                 messageLower.contains('bayad');
                 
        case 'Driver Reviews':
          // ... (filter logic for Driver Reviews)
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
            // FIX: Replaced .background with .surface
            color: colorScheme.surface, 
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                // FIX: Replaced .withOpacity(0.26) with .withAlpha(66)
                color: Colors.black.withAlpha(66),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // MODIFIED: Header Container with custom background color and centered buttons
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                // NEW: Use F4BE6C background color
                decoration: const BoxDecoration(
                  color: Color(0xFFF4BE6C), 
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // MODIFIED: Pass the icon path for Terminals
                    _buildTabButton('Terminals', 'Terminals', 'assets/terminalsIcon.png', colorScheme),
                    const SizedBox(width: 16),
                    // MODIFIED: Pass the icon path for Insights
                    _buildTabButton('Insights', 'Insights', 'assets/insightsIcon.png', colorScheme),
                  ],
                ),
              ),

              // NEW: Conditional content rendering for Insights view (Filter Chips are only for Insights)
              if (_currentView == 'Insights')
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Divider(height: 1, color: Colors.grey[300]!),
                  ],
                ),
                
              Expanded(
                child: _currentView == 'Insights'
                    ? ListView.builder(
                        controller: scrollController,
                        itemCount: filteredMessages.length,
                        itemBuilder: (context, index) {
                          final message = filteredMessages[index];
                          final interaction = (message.id != null && _userInteractions[message.id] != null)
                              ? _userInteractions[message.id]!
                              : const UserInteraction();
                          final isCurrentUserSender =
                              widget.currentUserId != null && widget.currentUserId == message.senderUid;

                          return InsightCard(
                            message: message,
                            interaction: interaction,
                            isCurrentUserSender: isCurrentUserSender,
                            onLike: () => _handleVote(message, true),
                            onDislike: () => _handleVote(message, false),
                            onReport: () => _handleReport(message),
                            onDelete: () => _deleteMessage(message),
                          );
                        },
                      )
                    // NEW: Display the Terminal List when the Terminals tab is selected
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: widget.hardcodedTerminals.length,
                        itemBuilder: (context, index) {
                          return _buildTerminalCard(widget.hardcodedTerminals[index], colorScheme);
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