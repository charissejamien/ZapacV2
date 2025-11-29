import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_insights_page.dart' show ChatMessage;

String capitalizeFirstLetter(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class _AddInsightContent extends StatefulWidget {
  final ValueSetter<ChatMessage> onInsightAdded;
  final FirebaseFirestore firestore;
  
  const _AddInsightContent({
    required this.onInsightAdded,
    required this.firestore,
    Key? key,
  }) : super(key: key);

  @override
  State<_AddInsightContent> createState() => _AddInsightContentState();
}

class _AddInsightContentState extends State<_AddInsightContent> with SingleTickerProviderStateMixin {
  final TextEditingController insightController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final FocusNode insightFocusNode = FocusNode();
  final FocusNode routeFocusNode = FocusNode();
  
  late Future<void> _reloadUserFuture;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isPosting = false;
  int _charCount = 0;
  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _reloadUserFuture = currentUser?.reload() ?? Future.value();
    
    // Setup animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    
    insightController.addListener(() {
      setState(() {
        _charCount = insightController.text.length;
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      insightFocusNode.requestFocus();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    insightController.dispose();
    routeController.dispose();
    insightFocusNode.dispose();
    routeFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Color _getCharCountColor(ThemeData theme) {
    if (_charCount > _maxChars) return theme.colorScheme.error;
    if (_charCount > _maxChars * 0.9) return Colors.orange;
    return theme.textTheme.bodySmall?.color?.withOpacity(0.5) ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<void>(
      future: _reloadUserFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }
        
        final refreshedUser = FirebaseAuth.instance.currentUser;
        final senderName = refreshedUser?.displayName ?? 
                          refreshedUser?.email?.split('@').first ?? 
                          'Current User';
        final profileUrl = refreshedUser?.photoURL ?? ''; 
        final senderUid = refreshedUser?.uid;
        
        final bool hasImageUrl = profileUrl.isNotEmpty;
        final String initials = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Share Insight',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(height: 1, color: textColor.withOpacity(0.1)),
                  
                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User profile section
                          Row(
                            children: [
                              Hero(
                                tag: 'user_avatar_$senderUid',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: hasImageUrl 
                                        ? Colors.transparent 
                                        : theme.colorScheme.primary,
                                    backgroundImage: hasImageUrl
                                        ? NetworkImage(profileUrl)
                                        : null,
                                    child: hasImageUrl
                                        ? null
                                        : Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      senderName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.public,
                                          size: 14,
                                          color: textColor.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Posting to ZAPAC Community',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: textColor.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Insight text field
                          Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: textColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: insightController,
                              focusNode: insightFocusNode,
                              decoration: InputDecoration(
                                hintText: 'What\'s on your mind? Share your insight...',
                                hintStyle: TextStyle(
                                  color: textColor.withOpacity(0.4),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                counterText: '',
                              ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                height: 1.5,
                              ),
                              maxLines: 6,
                              minLines: 4,
                              maxLength: _maxChars,
                            ),
                          ),
                          
                          // Character counter
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$_charCount / $_maxChars',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _getCharCountColor(theme),
                                    fontWeight: _charCount > _maxChars * 0.9
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Route field with icon
                          Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: textColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: routeController,
                              focusNode: routeFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Which route?',
                                hintStyle: TextStyle(
                                  color: textColor.withOpacity(0.4),
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  Icons.route,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Post button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isPosting ? null : _handlePost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6CA89A),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade400,
                                elevation: 0,
                                shadowColor: const Color(0xFF6CA89A).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isPosting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.send_rounded, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Post Insight',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePost() async {
    String text = insightController.text.trim();
    String route = routeController.text.trim();
    
    if (text.isEmpty || route.isEmpty) {
      _showSnackBar(
        'Please fill in both fields',
        Colors.orange,
        Icons.warning_amber_rounded,
      );
      return;
    }
    
    if (_charCount > _maxChars) {
      _showSnackBar(
        'Insight exceeds maximum length',
        Theme.of(context).colorScheme.error,
        Icons.error_outline,
      );
      return;
    }
    
    setState(() => _isPosting = true);
    
    final refreshedUser = FirebaseAuth.instance.currentUser;
    final senderName = refreshedUser?.displayName ?? 
                      refreshedUser?.email?.split('@').first ?? 
                      'Current User';
    final profileUrl = refreshedUser?.photoURL ?? '';
    final senderUid = refreshedUser?.uid;
    
    text = capitalizeFirstLetter(text);
    route = capitalizeFirstLetter(route);
    
    final newInsight = ChatMessage(
      sender: senderName,
      message: '"$text"',
      route: route,
      imageUrl: profileUrl,
      senderUid: senderUid,
    );

    try {
      await widget.firestore
          .collection('public_data')
          .doc('zapac_community')
          .collection('comments')
          .add(newInsight.toFirestore());

      if (mounted) {
        widget.onInsightAdded(newInsight);
        Navigator.pop(context);
        
        // Success feedback with haptic
        _showSnackBar(
          'Insight posted successfully!',
          const Color(0xFF6CA89A),
          Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      print('Failed to post insight: $e');
      
      if (mounted) {
        setState(() => _isPosting = false);
        _showSnackBar(
          'Failed to post. Please try again.',
          Theme.of(context).colorScheme.error,
          Icons.error_outline,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

void showAddInsightModal({
  required BuildContext context,
  required ValueSetter<ChatMessage> onInsightAdded,
  required FirebaseFirestore firestore,
}) {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.login, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Please log in to post an insight',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _AddInsightContent(
        onInsightAdded: onInsightAdded,
        firestore: firestore,
      );
    },
  );
}