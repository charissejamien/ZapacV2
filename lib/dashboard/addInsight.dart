import 'package:flutter/material.dart';
// Note: User.dart and AuthManager.dart imports were removed as they are from the old project.
// The user object below is mocked for structure coherence.
import 'community_insights_page.dart' show ChatMessage;

// Mock User structure for modal coherence (assuming you have a current user context)
class MockUser {
    final String firstName = 'Current User';
    final String profileImageUrl = 'https://cdn-icons-png.flaticon.com/512/100/100913.png';
}

void showAddInsightModal({
  required BuildContext context,
  required ValueSetter<ChatMessage> onInsightAdded,
}) {
  // Use a mock/placeholder user until integrated with Firebase Auth
  final user = MockUser(); 
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
                  backgroundImage: NetworkImage(user.profileImageUrl),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.firstName, 
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
                onPressed: () {
                  final text = insightController.text.trim();
                  final route = routeController.text.trim();
                  if (text.isNotEmpty && route.isNotEmpty) {
                    final newInsight = ChatMessage(
                      sender: user.firstName,
                      message: '“$text”',
                      route: route,
                      timeAgo: 'Just now',
                      imageUrl: user.profileImageUrl,
                    );
                    onInsightAdded(newInsight);
                    Navigator.pop(context);
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
  ).whenComplete(() {
    insightController.dispose();
    routeController.dispose();
  });
}
