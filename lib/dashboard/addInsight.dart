import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_insights_page.dart' show ChatMessage;

void showAddInsightModal({
  required BuildContext context,
  required ValueSetter<ChatMessage> onInsightAdded,
  required FirebaseFirestore firestore,
}) {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
     // Show a user-friendly message immediately if no user is logged in
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post an insight.'), backgroundColor: Colors.red),
      );
      return;
  }

  final senderName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Current User';
  final profileUrl = currentUser.photoURL ?? 'https://cdn-icons-png.flaticon.com/512/100/100913.png';
  
  final TextEditingController insightController = TextEditingController();
  final TextEditingController routeController   = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final textColor = theme.textTheme.bodyLarge?.color;
      final hintColor = theme.hintColor;
      
      return Padding(
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
                  final text = insightController.text.trim();
                  final route = routeController.text.trim();
                  
                  if (text.isEmpty || route.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter both insight and route.'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  
                  // Disable button and show loading here if needed, but not necessary for a quick post

                  final newInsight = ChatMessage(
                    sender: senderName,
                    message: '“$text”',
                    route: route,
                    timeAgo: 'Just now', 
                    imageUrl: profileUrl,
                  );

                  // --- SAVE TO FIRESTORE ---
                  try {
                      await firestore
                        .collection('public_data')
                        .doc('zapac_community')
                        .collection('comments')
                        .add(newInsight.toFirestore());

                      if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Insight posted successfully!'), backgroundColor: Color(0xFF6CA89A)),
                          );
                          Navigator.pop(context);
                      }
                  } catch (e) {
                       print('Failed to post insight to Firestore: $e');
                       if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Post failed. Check console for error.')),
                          );
                       }
                  }
                  onInsightAdded(newInsight);
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
  ).whenComplete(() {
    insightController.dispose();
    routeController.dispose();
  });
}