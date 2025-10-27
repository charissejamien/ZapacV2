import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_insights_page.dart' show ChatMessage;

// Utility function to capitalize the first letter of a string
String capitalizeFirstLetter(String s) {
  if (s.isEmpty) {
    return s;
  }
  return s[0].toUpperCase() + s.substring(1);
}

void showAddInsightModal({
  required BuildContext context,
  required ValueSetter<ChatMessage> onInsightAdded,
  required FirebaseFirestore firestore,
}) {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
     // Show feedback, then silently return.
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post an insight.'), backgroundColor: Colors.red),
      );
      return;
  }

  final senderName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Current User';
  final profileUrl = currentUser.photoURL ?? 'https://cdn-icons-png.flaticon.com/512/100/100913.png';
  final senderUid = currentUser.uid;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) { 
      // CRITICAL FIX: Define controllers inside the builder 
      final TextEditingController insightController = TextEditingController();
      final TextEditingController routeController   = TextEditingController();
      
      final theme = Theme.of(ctx);
      final textColor = theme.textTheme.bodyLarge?.color;
      final hintColor = theme.hintColor;
      
      return Padding(
        // RENDERFLEX FIX: This handles the keyboard overlay without overflow
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar and Name
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(profileUrl),
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
                        color: textColor?.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Insight Input
            TextField(
              controller: insightController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Share an insight to the community....',
                hintStyle: TextStyle(color: hintColor),
                border: InputBorder.none,
              ),
              style: TextStyle(color: textColor),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            // Route Input
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
            // OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String text = insightController.text.trim();
                  String route = routeController.text.trim();
                  
                  if (text.isEmpty || route.isEmpty) {
                    // Validation Feedback
                    ScaffoldMessenger.of(ctx).showSnackBar( 
                      const SnackBar(content: Text('Please enter both insight and route.'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  
                  // Apply capitalization for insight and route as requested
                  text = capitalizeFirstLetter(text);
                  route = capitalizeFirstLetter(route);
                  
                  final newInsight = ChatMessage(
                    sender: senderName,
                    message: '“$text”',
                    route: route,
                    imageUrl: profileUrl,
                    senderUid: senderUid, // SAVE THE UID
                  );

                  // 1. CRITICAL: POP MODAL IMMEDIATELY
                  if (ctx.mounted) {
                      Navigator.pop(ctx); 
                  } else {
                      return; 
                  }
                  
                  // --- Loading Overlay Implementation ---
                  final loadingContext = context; 
                  
                  // Show the full-screen loading overlay in the parent context
                  showGeneralDialog(
                      context: loadingContext,
                      barrierDismissible: false,
                      transitionDuration: const Duration(milliseconds: 150),
                      // Faded black overlay
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
                  // ------------------------------------------


                  // 2. Perform ASYNC WRITE in the background.
                  try {
                      await firestore
                        .collection('public_data')
                        .doc('zapac_community')
                        .collection('comments')
                        .add(newInsight.toFirestore());

                      // Success: Hide the loading overlay
                      if (loadingContext.mounted) {
                          Navigator.of(loadingContext).pop();
                      }

                      // 3. Call callback after successful post
                      onInsightAdded(newInsight); 
                      
                  } catch (e) {
                       print('Failed to post insight to Firestore: $e');
                       
                       // Error: Hide the loading overlay before showing the error SnackBar
                       if (loadingContext.mounted) {
                           Navigator.of(loadingContext).pop();
                       }

                       // Show failure message using the stable parent context
                       if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post failed. Check console for error.'), backgroundColor: Colors.red),
                          );
                       }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6CA89A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('OK'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  ); // CRITICAL FIX: Removed .whenComplete() block completely
}