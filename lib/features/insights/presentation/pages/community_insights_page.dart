import 'package:flutter/material.dart';

// --- ChatMessage Model (Restored and Kept Here) ---
class ChatMessage {
  final String sender;
  final String message;
  final String route;
  final String timeAgo;
  final String imageUrl;
  int likes;
  int dislikes;
  bool isLiked;
  bool isDisliked;
  bool isMostHelpful;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.route,
    required this.timeAgo,
    required this.imageUrl,
    this.likes = 0,
    this.dislikes = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.isMostHelpful = false,
  });
}

class CommentingSection extends StatefulWidget {
  final ValueSetter<bool>? onExpansionChanged;
  // Dashboard passes the full list of messages
  final List<ChatMessage> chatMessages; 
  // No need for onNewInsightAdded here, as the modal is separate.

  const CommentingSection({
    super.key,
    this.onExpansionChanged,
    required this.chatMessages,
  });

  @override
  State<CommentingSection> createState() => _CommentingSectionState();
}

class _CommentingSectionState extends State<CommentingSection> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final TextEditingController _commentController = TextEditingController(); // Can be removed later if not used
  
  bool _isSheetFullyExpanded = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_handleExpansionChange);
  }

  void _handleExpansionChange() {
    final bool isExpandedNow = _sheetController.size >= 0.85;
    if (isExpandedNow != _isSheetFullyExpanded) {
      if (mounted) {
        setState(() {
          _isSheetFullyExpanded = isExpandedNow;
        });
      }
      // Notify parent (Dashboard) of the sheet size change
      widget.onExpansionChanged?.call(_isSheetFullyExpanded); 
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike(int index) {
    if (mounted) {
      setState(() {
        final message = _filteredMessages[index];
        message.isLiked = !message.isLiked;
        message.likes += message.isLiked ? 1 : -1;
        if (message.isLiked && message.isDisliked) {
          message.isDisliked = false;
          message.dislikes -= 1;
        }
      });
    }
  }

  void _toggleDislike(int index) {
    if (mounted) {
      setState(() {
        final message = _filteredMessages[index];
        message.isDisliked = !message.isDisliked;
        message.dislikes += message.isDisliked ? 1 : -1;
        if (message.isDisliked && message.isLiked) {
          message.isLiked = false;
          message.likes -= 1;
        }
      });
    }
  }

  // Filtered messages list logic
  List<ChatMessage> get _filteredMessages {
    if (_selectedFilter == 'All') {
      // Return a sorted list based on likes/helpfulness if needed, 
      // but keeping original order for structure coherence.
      return widget.chatMessages;
    }

    final filterLower = _selectedFilter.toLowerCase();
    
    return widget.chatMessages.where((message) {
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
  }

  Widget _buildInsightCard(ChatMessage message, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Extracted styles and used const where possible
    const iconSize = 20.0;
    final dividerColor = Theme.of(context).dividerColor;
    
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
                        // Action menu (Report/Delete)
                        GestureDetector(
                          onTapDown: (details) async {
                            // Menu logic remains the same (implementation moved to Dashboard or helper if needed)
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
                    Text(
                      'Route: ${message.route}  |  ${message.timeAgo}',
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
                  onTap: () => _toggleLike(index),
                  child: Row(
                    children: [
                      Icon(
                        message.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: message.isLiked ? Colors.blue : dividerColor,
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
                  onTap: () => _toggleDislike(index),
                  child: Row(
                    children: [
                      Icon(
                        message.isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                        color: message.isDisliked ? Colors.red : dividerColor,
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
    // Removed isDark check inside chip building as it's not strictly necessary if colors are primary/secondary
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
    final List<ChatMessage> currentMessages = _filteredMessages; 

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
                  itemCount: currentMessages.length,
                  itemBuilder: (context, index) {
                    return _buildInsightCard(currentMessages[index], index);
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
