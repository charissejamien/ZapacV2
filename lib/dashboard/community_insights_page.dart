import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapac/dashboard/models/chat_message.dart';
import 'package:zapac/dashboard/models/user_interaction.dart'; 
import 'package:zapac/core/widgets/insight_card.dart';
import 'package:zapac/dashboard/dashboard.dart' show TerminalDetailsModal; // Import the modal for use here

class CommentingSection extends StatefulWidget {
  final ValueSetter<bool>? onExpansionChanged;
  final List<ChatMessage> chatMessages; 
  final String? currentUserId; 
  final List<Map<String, dynamic>> hardcodedTerminals; 
  
  // Terminal View State
  final bool isShowingTerminals;
  final VoidCallback onShowTerminalsPressed; 

  // PROPS FOR DETAIL VIEW
  final String? selectedTerminalId; // ID of the terminal to show details for
  final ValueSetter<String> onTerminalCardSelected; // Handler when a card is tapped
  final VoidCallback onBackToTerminals; // Handler for the back button

  final FirebaseFirestore firestore = FirebaseFirestore.instance; 

  CommentingSection({
    super.key,
    this.onExpansionChanged,
    required this.chatMessages,
    this.currentUserId, 
    required this.hardcodedTerminals,
    required this.isShowingTerminals, 
    required this.onShowTerminalsPressed, 
    
    // REQUIRED PROPS
    required this.selectedTerminalId, 
    required this.onTerminalCardSelected, 
    required this.onBackToTerminals, 
  });

  @override
  State<CommentingSection> createState() => _CommentingSectionState();
}

class _CommentingSectionState extends State<CommentingSection> {
  // Defines how "tall" the sheet is in each state (as a fraction of screen height)
  // closed  = just a thin grab area at the bottom
  // preview = header + a bit of content (like Google Maps peek)
  // expanded = full insights/terminal view
  static const double _closedSize = 0.10;
  static const double _previewSize = 0.26;
  static const double _expandedSize = 0.85;

  double _previousSize = _closedSize;
  double _lastDelta = 0.0;
  double _gestureStartSize = _closedSize;
  bool _isAnimatingSnap = false;
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
    final currentSize = _sheetController.size;

    // Track how the sheet is moving (up or down) when not in a programmatic snap.
    if (!_isAnimatingSnap) {
      _lastDelta = currentSize - _previousSize;
    }
    _previousSize = currentSize;

    // Only update whether the sheet is considered "expanded" or not,
    // and notify the parent if that state changes.
    const double fabSwitchThreshold = 0.55;
    final bool isExpandedNow = currentSize >= fabSwitchThreshold;

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
    
    // If we transition to detail view, ensure the sheet is expanded.
    if (widget.selectedTerminalId != null && oldWidget.selectedTerminalId == null) {
      if (_sheetController.size < _expandedSize) {
        _sheetController.animateTo(
          _expandedSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'We will review this insight shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
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
      // Logger.error("Error deleting message ${message.id}: $e");
      
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

  /// Infer a simple category label for a given ChatMessage based on its text.
  String? _inferCategoryLabel(ChatMessage message) {
    final messageLower = message.message.toLowerCase();

    // Warning
    if (messageLower.contains('traffic') ||
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
        messageLower.contains('bangga') ||
        messageLower.contains('warning')) {
      return 'Warning';
    }

    // Shortcuts
    if (messageLower.contains('shortcut') ||
        messageLower.contains('faster') ||
        messageLower.contains('route') ||
        messageLower.contains('quick') ||
        messageLower.contains('lusot') ||
        messageLower.contains('dali') ||
        messageLower.contains('shortcut')) {
      return 'Shortcut';
    }

    // Fare Tips
    if (messageLower.contains('fare') ||
        messageLower.contains('price') ||
        messageLower.contains('cost') ||
        messageLower.contains('plete') ||
        messageLower.contains('plite') ||
        messageLower.contains('pliti') ||
        messageLower.contains('pleti') ||
        messageLower.contains('sukli') ||
        messageLower.contains('tagpila') ||
        messageLower.contains('bayad') ||
        messageLower.contains('Fare Tips')) {
      return 'Fare Tip';
    }

    // Driver Reviews
    if (messageLower.contains('driver') ||
        messageLower.contains('reckless') ||
        messageLower.contains('rude') ||
        messageLower.contains('kind') ||
        messageLower.contains('buotan') ||
        messageLower.contains('barato')) {
      return 'Driver Review';
    }

    return null;
  }
  
  // Widget to display a single Terminal Card
  Widget _buildTerminalCard(Map<String, dynamic> terminal, ColorScheme cs) {
    // FIX: Change Map<String, String> to Map<String, dynamic>
    final details = terminal['details'] as Map<String, dynamic>;
    return GestureDetector(
      onTap: () {
        // Call the parent handler to switch to detail view
        widget.onTerminalCardSelected(terminal['id'] as String); 
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceVariant, 
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
                details['title'] as String? ?? 'Terminal', // FIX: Add safe casting
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: cs.primary,
                ),
              ),
              const Divider(height: 12),
              // FIX: Add safe casting
              _buildTerminalDetailRow(Icons.access_time, 'Status', details['status'] as String? ?? 'N/A', cs),
              _buildTerminalDetailRow(Icons.route, 'Routes', details['routes'] as String? ?? 'N/A', cs),
              _buildTerminalDetailRow(Icons.local_convenience_store, 'Facilities', details['facilities'] as String? ?? 'N/A', cs),
              const SizedBox(height: 8),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                      'Tap for more details...',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: cs.secondary,
                      ),
                  ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  // MODIFIED: Widget to display the full details of the selected terminal with Route/Fare table
  Widget _buildTerminalDetailView(Map<String, dynamic> terminal, ColorScheme cs, ScrollController scrollController) {
    final details = terminal['details'] as Map<String, dynamic>;
    final List<Map<String, dynamic>> routesFares = (details['routes_fares'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList() ?? [];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      children: [
        // Title
        Text(
          details['title'] as String? ?? 'Terminal Details', // FIX: Add safe casting
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 16),
        
        // General Details (Status, Routes, Facilities)
        // FIX: Add safe casting
        _buildTerminalDetailRow(Icons.access_time_filled, 'Status', details['status'] as String? ?? 'N/A', cs),
        const SizedBox(height: 10),
        _buildTerminalDetailRow(Icons.directions_bus, 'Primary Routes', details['routes'] as String? ?? 'N/A', cs),
        const SizedBox(height: 10),
        _buildTerminalDetailRow(Icons.local_convenience_store, 'Facilities', details['facilities'] as String? ?? 'N/A', cs),
        
        // NEW SECTION: Routes & Fares
        const SizedBox(height: 30),
        Text(
          'Routes & Fares',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        
        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Route', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary)),
              ),
              Expanded(
                flex: 1,
                child: Text('Fare', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary)),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey[400]),

        // Route/Fare List
        ...routesFares.map((rf) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    rf['route'] as String? ?? 'N/A', 
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                    softWrap: true,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    rf['fare'] as String? ?? 'N/A', 
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        // Footer (Location Coordinates)
        const SizedBox(height: 30),
        Text(
          'Location Coordinates:',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        Text(
          'Lat: ${terminal['lat']}, Lng: ${terminal['lng']}',
          style: TextStyle(color: cs.onSurface.withAlpha(179)),
        ),
      ],
    );
  }


  // Helper for Terminal Detail Row (used for Status, Routes, Facilities)
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

  /// Helper to render "Taga ZAPAC says..." with only "ZAPAC" bold and gradient
  /// Helper to render "Taga ZAPAC says..." with adaptive text color
  Widget _buildZapacHeaderTitle(Color textColor) { // <--- ADDED PARAMETER
    const double fontSize = 18;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Taga ',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: fontSize,
              color: textColor, // <--- USE PARAMETER
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF6CA89A), 
                    Color(0xFF4A6FA5), 
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Text(
                'ZAPAC',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: Colors.white, 
                ),
              ),
            ),
          ),
          TextSpan(
            text: ' says...',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: fontSize,
              color: textColor, // <--- USE PARAMETER
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final headerColor = isDarkMode ? const Color(0xFF8F6F3A) : const Color(0xFFF4BE6C);

    final headerTextColor = isDarkMode ? Colors.white : Colors.black87;

    final filteredMessages = widget.chatMessages.where((message) {
      if (_selectedFilter == 'All') return true;

      final messageLower = message.message.toLowerCase();

      switch (_selectedFilter) {
        case 'Warning':
          // Explicit filter words for Warning
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
          // Explicit filter words for Shortcuts
          return messageLower.contains('shortcut') ||
                 messageLower.contains('faster') ||
                 messageLower.contains('route') ||
                 messageLower.contains('quick') ||
                 messageLower.contains('lusot') ||
                 messageLower.contains('dali');
                 
        case 'Fare Tips':
          // Explicit filter words for Fare Tips
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
          // Explicit filter words for Driver Reviews
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

    // Conditional Title and Find Selected Terminal
    String headerTitle;
    Map<String, dynamic>? selectedTerminal;

    if (widget.isShowingTerminals) {
      if (widget.selectedTerminalId != null) {
        selectedTerminal = widget.hardcodedTerminals.firstWhere(
            (t) => t['id'] == widget.selectedTerminalId,
            orElse: () => <String, dynamic>{},
        );
        headerTitle = selectedTerminal.isNotEmpty 
            ? selectedTerminal['name'] as String 
            : 'Terminal Details';
      } else {
        headerTitle = 'Terminals';
      }
    } else {
      headerTitle = 'Taga ZAPAC Says...';
    }


    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _closedSize,
      minChildSize: _closedSize,
      maxChildSize: _expandedSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface, 
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(66),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Track the start size of this drag/scroll gesture.
              if (notification is ScrollStartNotification) {
                _gestureStartSize = _sheetController.size;
                return false;
              }

              // Only handle snapping when the gesture ends.
              if (notification is! ScrollEndNotification) {
                return false;
              }

              if (_isAnimatingSnap) return false;

              final size = _sheetController.size;
              const double epsilon = 0.02;

              // If we're already very close to closed or fully expanded, don't interfere.
              if (size <= _closedSize + epsilon || size >= _expandedSize - epsilon) {
                return false;
              }

              // Determine gesture direction based on total movement across the drag.
              final double gestureDelta = size - _gestureStartSize;

              // 1) Determine which "level" we're closest to right now.
              // 0 = closed, 1 = preview, 2 = expanded
              int currentLevel;
              final midClosedPreview = (_closedSize + _previewSize) / 2;
              final midPreviewExpanded = (_previewSize + _expandedSize) / 2;

              if (size < midClosedPreview) {
                currentLevel = 0;
              } else if (size < midPreviewExpanded) {
                currentLevel = 1;
              } else {
                currentLevel = 2;
              }

              // 2) Decide target level based on gesture direction.
              int targetLevel;
              const double directionThreshold = 0.015; // avoid noise/bounce

              if (gestureDelta < -directionThreshold) {
                // Dragging downward → always go one step "down"
                // Expanded -> Preview, Preview -> Closed
                targetLevel = (currentLevel - 1).clamp(0, 2);
              } else if (gestureDelta > directionThreshold) {
                // Dragging upward → always go one step "up"
                // Closed -> Preview, Preview -> Expanded
                targetLevel = (currentLevel + 1).clamp(0, 2);
              } else {
                // No clear direction → snap to the nearest of the three anchors
                targetLevel = currentLevel;
              }

              // 3) Map level back to specific size.
              double target;
              switch (targetLevel) {
                case 0:
                  target = _closedSize;
                  break;
                case 1:
                  target = _previewSize;
                  break;
                case 2:
                default:
                  target = _expandedSize;
                  break;
              }

              _isAnimatingSnap = true;
              _sheetController
                  .animateTo(
                    target,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  )
                  .whenComplete(() {
                _isAnimatingSnap = false;
              });

              return false;
            },
            child: Column(
              children: [
              
              // CORRECTED HEADER LOGIC (Single Title or Back Button + Title)
              GestureDetector(
                onTap: () {
                  // Cycle: closed -> preview -> expanded -> closed
                  final currentSize = _sheetController.size;
                  const double epsilon = 0.03;

                  double target;
                  if ((currentSize - _closedSize).abs() < epsilon) {
                    target = _previewSize;
                  } else if ((currentSize - _previewSize).abs() < epsilon) {
                    target = _expandedSize;
                  } else {
                    target = _closedSize;
                  }

                  _isAnimatingSnap = true;
                  _sheetController
                      .animateTo(
                        target,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      )
                      .whenComplete(() {
                    _isAnimatingSnap = false;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    gradient: isDarkMode
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8F6F3A),
                              Color(0xFF6E532A),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF9D48A),
                              Color(0xFFF4BE6C),
                            ],
                          ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle hint so users know the sheet is draggable/tappable
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: (isDarkMode ? Colors.white : Colors.black87)
                                .withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Back button visible only if viewing a specific terminal
                          if (widget.selectedTerminalId != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: widget.onBackToTerminals,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          
                          if (widget.selectedTerminalId != null)
                            const SizedBox(width: 8),

                          Expanded(
                            child: Center(
                              child: widget.isShowingTerminals
                                  ? Text(
                                      headerTitle, // "Terminals" or Terminal Name
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: headerTextColor,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  : _buildZapacHeaderTitle(headerTextColor),
                            ),
                          ),
                          
                          // Spacer to balance the back button size if needed
                          if (widget.selectedTerminalId != null)
                            const SizedBox(width: 48),
                        ],
                      ),
                    ],
                  ),
                ),
              ),


              // Filter Chips (Only visible for Insights and when sheet is at least in preview state)
              if (!widget.isShowingTerminals && _sheetController.size >= _previewSize - 0.02)
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
                // FINAL CONDITIONAL RENDERING LOGIC
                child: widget.isShowingTerminals
                    ? (widget.selectedTerminalId != null && selectedTerminal != null && selectedTerminal.isNotEmpty)
                        // Detail View
                        ? _buildTerminalDetailView(selectedTerminal, colorScheme, scrollController) 
                        // List View
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: widget.hardcodedTerminals.length,
                            itemBuilder: (context, index) {
                              return _buildTerminalCard(widget.hardcodedTerminals[index], colorScheme);
                            },
                          )
                    // Insights View
                    : (filteredMessages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'No insights yet for this filter.\nBe the first to share what\'s happening on the road!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withAlpha(179),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filteredMessages.length,
                            itemBuilder: (context, index) {
                              final message = filteredMessages[index];
                              final interaction = (message.id != null && _userInteractions[message.id] != null)
                                  ? _userInteractions[message.id]!
                                  : const UserInteraction();
                              final isCurrentUserSender =
                                  widget.currentUserId != null && widget.currentUserId == message.senderUid;

                              final categoryLabel = _inferCategoryLabel(message);

                              return InsightCard(
                                message: message,
                                interaction: interaction,
                                isCurrentUserSender: isCurrentUserSender,
                                categoryLabel: categoryLabel,
                                onLike: () => _handleVote(message, true),
                                onDislike: () => _handleVote(message, false),
                                onReport: () => _handleReport(message),
                                onDelete: () => _deleteMessage(message),
                              );
                            },
                          )),
              ),
            ],
          ),
          )
        );
      },
    );
  }
}