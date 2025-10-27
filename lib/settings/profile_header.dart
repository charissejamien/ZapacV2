import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'app_constants.dart';

class ProfileHeader extends StatelessWidget {
  final User? currentUser;
  final File? profileImageFile;
  final String displayName;
  final String userEmail;
  final String initials;
  final VoidCallback onProfilePicTap;
  final String userStatus = 'Daily Commuter'; // Static status

  const ProfileHeader({
    super.key,
    required this.currentUser,
    required this.profileImageFile,
    required this.displayName,
    required this.userEmail,
    required this.initials,
    required this.onProfilePicTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ImageProvider? avatarImage;
    Widget avatarChild;

    // 1. Check local file path
    if (profileImageFile != null) {
        avatarImage = FileImage(profileImageFile!);
        avatarChild = const SizedBox.expand();
    } 
    // 2. Check Firebase/Network URL
    else if (currentUser?.photoURL?.isNotEmpty == true) {
        avatarImage = NetworkImage(currentUser!.photoURL!);
        avatarChild = const SizedBox.expand();
    } 
    // 3. Fallback to Initials Avatar (First Letter)
    else {
        avatarChild = Text(
            initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
            ),
        );
        avatarImage = null;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            GestureDetector(
              onTap: onProfilePicTap,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: colorScheme.onPrimary.withOpacity(0.15),
                    child: CircleAvatar(
                      radius: 38,
                      // Set fallback color for initials avatar
                      backgroundColor: avatarImage != null ? colorScheme.surface : primaryColor, 
                      backgroundImage: avatarImage,
                      child: avatarImage == null ? avatarChild : null,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: colorScheme.onPrimary.withOpacity(0.95),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onProfilePicTap,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit_outlined, size: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PROFILE PHOTO',
              style: TextStyle(
                color: colorScheme.onPrimary.withOpacity(0.9),
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    userEmail,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.95),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
