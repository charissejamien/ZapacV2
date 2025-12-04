import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_insights_page.dart' show ChatMessage;
import 'package:flutter/services.dart'; // Added for haptic feedback

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
    super.key, // Use super.key directly
  });

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
  static const int alpha128 = 128; // 0.5 opacity

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    // FIX: Guard the reload() call
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
      if (mounted) {
        setState(() {
          _charCount = insightController.text.length;
        });
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        insightFocusNode.requestFocus();
        _animController.forward();
      }
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
    // FIX: Replaced .withOpacity(0.5) with .withAlpha(128)
    return theme.textTheme.bodySmall?.color?.withAlpha(alpha128) ?? Colors.grey;
  }
  
  // NEW: Function to handle the asynchronous posting flow
  Future<void> _postInsight() async {
    if (_isPosting || !mounted) return;

    String text = insightController.text.trim();
    String route = routeController.text.trim();
    final theme = Theme.of(context);
    
    if (text.isEmpty || route.isEmpty) {
      if (mounted) {
        _showSnackBar( 
          'Please enter both insight and route.',
          Colors.orange,
          Icons.warning_amber,
        );
      }
      return;
    }
    
    if (_charCount > _maxChars) {
        if (mounted) {
            _showSnackBar( 
                'Insight exceeds maximum length.',
                theme.colorScheme.error,
                Icons.error_outline,
            );
        }
        return;
    }

    // --- FIX START: Swapping pop order and using try/finally for cleanup ---
    
    // 1. Set posting state
    if (mounted) setState(() => _isPosting = true);

    // Get refreshed user details
    final refreshedUser = FirebaseAuth.instance.currentUser;
    final senderName = refreshedUser?.displayName ?? 
                       refreshedUser?.email?.split('@').first ?? 
                       'Current User';
    final profileUrl = refreshedUser?.photoURL ?? ''; 
    final senderUid = refreshedUser?.uid;

    final newInsight = ChatMessage(
      sender: senderName,
      message: '“${capitalizeFirstLetter(text)}”',
      route: capitalizeFirstLetter(route),
      imageUrl: profileUrl,
      senderUid: senderUid,
    );
    
    // 2. Show a temporary loading screen on the root navigator (pushed on top of the current modal)
    // The current `context` is still valid and mounted here.
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 150),
        barrierColor: Colors.black.withOpacity(0.7),
        routeSettings: const RouteSettings(name: 'PostingIndicator'),
        pageBuilder: (ctx, a1, a2) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                    backgroundColor: theme.colorScheme.primary,
                ),
            );
        },
    );
    
    bool success = false;
    try {
      // 3. Post to Firebase (Wait for async operation)
      await widget.firestore 
        .collection('public_data')
        .doc('zapac_community')
        .collection('comments')
        .add(newInsight.toFirestore());

      success = true;

    } catch (e) {
      // Logger.error('Failed to post insight: $e');
      success = false;

    } finally {
      // 4. DISMISS LOADING DIALOG FIRST (pushed on root navigator)
      // Since `context` belongs to the modal sheet, we use `rootNavigator: true`.
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      // 5. DISMISS MODAL SHEET SECOND (the widget itself)
      if (mounted) {
         Navigator.pop(context); 
      }
      
      // 6. Provide feedback using the context that is still valid after the sheet pop (e.g., the root navigator's context).
      // Since we already popped the sheet, we rely on the global context provided by ScaffoldMessenger.
      if (mounted) {
        if (success) {
            widget.onInsightAdded(newInsight);
            SystemSound.play(SystemSoundType.click); 
            _showSnackBar(
              'Insight posted successfully!',
              const Color(0xFF6CA89A),
              Icons.check_circle_rounded,
            );
        } else {
            _showSnackBar(
              'Failed to post. Please try again.',
              theme.colorScheme.error,
              Icons.error_outline,
            );
        }
      }
      
      // Reset state for safety, though the widget is now disposed.
      if (mounted) setState(() => _isPosting = false);
    }
    // --- FIX END ---
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

  @override
  Widget build(BuildContext context) {
// ... (rest of the build function remains the same)
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    // final isDark = theme.brightness == Brightness.dark; // isDark is unused
    final hintColor = theme.colorScheme.onSurface.withAlpha(alpha128);

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
        // final senderUid = refreshedUser?.uid; // senderUid is only used in _postInsight

        final bool hasImageUrl = profileUrl.isNotEmpty;
        final String initials = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: hasImageUrl ? Colors.transparent : theme.colorScheme.primary, 
                        backgroundImage: hasImageUrl
                            ? NetworkImage(profileUrl) as ImageProvider<Object>?
                            : null,
                        child: hasImageUrl
                            ? null
                            : Text(
                                initials,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Posting publicly across ZAPAC',
                            style: TextStyle(
                              // FIX: Replaced .withOpacity(0.6) with .withAlpha(153)
                              color: textColor?.withAlpha(153),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: insightController,
                    focusNode: insightFocusNode, 
                    decoration: InputDecoration(
                      hintText: 'Share an insight to the community....',
                      hintStyle: TextStyle(color: hintColor),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: textColor),
                    maxLines: 4,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$_charCount/$_maxChars',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCharCountColor(theme),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: routeController,
                    decoration: InputDecoration(
                      hintText: 'What route are you on?',
                      hintStyle: TextStyle(color: hintColor),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // FIX: Call the refactored, safe posting function
                      onPressed: _isPosting ? null : _postInsight,
                      child: _isPosting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text("Post Insight"),
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