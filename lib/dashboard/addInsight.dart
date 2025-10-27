import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_insights_page.dart' show ChatMessage;

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
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post an insight.'), backgroundColor: Colors.red),
      );
      return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) { 
      return FutureBuilder<void>(
        future: currentUser.reload(), 
        builder: (context, snapshot) {
          final refreshedUser = FirebaseAuth.instance.currentUser;
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final senderName = refreshedUser?.displayName ?? refreshedUser?.email?.split('@').first ?? 'Current User';
          final profileUrl = refreshedUser?.photoURL ?? ''; 
          final senderUid = refreshedUser?.uid;

          final TextEditingController insightController = TextEditingController();
          final TextEditingController routeController   = TextEditingController();
          
          final FocusNode insightFocusNode = FocusNode();
          
          final theme = Theme.of(ctx);
          final textColor = theme.textTheme.bodyLarge?.color;
          final hintColor = theme.hintColor;
          
          final bool hasImageUrl = profileUrl.isNotEmpty;
          final String initials = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            insightFocusNode.requestFocus();
          });
          
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView( 
                padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: textColor?.withOpacity(0.6),
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
                        onPressed: () async {
                          String text = insightController.text.trim();
                          String route = routeController.text.trim();
                          
                          if (text.isEmpty || route.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar( 
                              const SnackBar(content: Text('Please enter both insight and route.'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          
                          text = capitalizeFirstLetter(text);
                          route = capitalizeFirstLetter(route);
                          
                          final newInsight = ChatMessage(
                            sender: senderName,
                            message: '“$text”',
                            route: route,
                            imageUrl: profileUrl,
                            senderUid: senderUid,
                          );

                          if (ctx.mounted) {
                              Navigator.pop(ctx); 
                          } else {
                              return; 
                          }
                          
                          final loadingContext = context; 
                          
                          showGeneralDialog(
                              context: loadingContext,
                              barrierDismissible: false,
                              transitionDuration: const Duration(milliseconds: 150),
                              barrierColor: Colors.black.withOpacity(0.7),
                              pageBuilder: (context, a1, a2) {
                                  return Center(
                                      child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                          backgroundColor: theme.colorScheme.primary,
                                      ),
                                  );
                              },
                          );

                          try {
                              await firestore
                                .collection('public_data')
                                .doc('zapac_community')
                                .collection('comments')
                                .add(newInsight.toFirestore());

                              if (loadingContext.mounted) {
                                  Navigator.of(loadingContext).pop();
                              }

                              onInsightAdded(newInsight);

                          } catch (e) {
                               print('Failed to post insight to Firestore: $e');

                               if (loadingContext.mounted) {
                                   Navigator.of(loadingContext).pop();
                               }

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
              ),
          );
        },
      );
    },
  );
}