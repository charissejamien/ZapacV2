import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapac/authentication/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/dashboard/dashboard.dart';
import 'package:zapac/authentication/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

// New imports for modularized components
import 'app_constants.dart';
import 'profile_header.dart';
import 'profile_info_row.dart';
import '../settings/settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  bool _isLoading = true;

  File? _profileImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  String _displayName = 'Welcome User';
  String _userEmail = 'N/A';
  String _initials = '?';
  String _userGender = 'Not provided';
  String _userDOB = 'Not provided';

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  void _loadUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) return;
    
    // FIX: Asserting non-null on _currentUser after null check
    _userEmail = _currentUser!.email ?? 'N/A';
    String potentialDisplayName = _currentUser!.displayName ?? '';
    if (potentialDisplayName.isEmpty && _currentUser!.email != null) {
        potentialDisplayName = _userEmail.split('@').first;
    }
    _displayName = potentialDisplayName.isNotEmpty ? potentialDisplayName : 'Welcome User';
    _initials = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';
  }

  Future<void> _initProfile() async {
    _loadUserData();

    final prefs = await SharedPreferences.getInstance();

    _userGender = prefs.getString('user_gender') ?? 'Not provided';
    _userDOB = prefs.getString('user_dob') ?? 'Not provided';

    final savedPath = prefs.getString('profile_pic_path');
    if (savedPath != null && File(savedPath).existsSync()) {
      _profileImageFile = File(savedPath);
    }
    else if (_currentUser?.photoURL != null) {
      _profileImageFile = null;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // FIRESTORE LOGIC: Update user comments when name/photo changes
  Future<void> _updateUserComments({required String newDisplayName, required String newPhotoUrl}) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // FIX: Guard unconditional access to uid
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) return;

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      final querySnapshot = await firestore
          .collection('public_data') 
          .doc('zapac_community')
          .collection('comments')
          .where('senderUid', isEqualTo: currentUserId) // Use guarded ID
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'imageUrl': newPhotoUrl, 
          'sender': newDisplayName, 
        });
      }

      await batch.commit();
      // Logger.info("Firestore Batch Update complete. ${querySnapshot.docs.length} comments updated.");
  }


  Future<void> _showEditFullNameSheet(BuildContext context, ColorScheme colorScheme) async {
    // FIX: Guard context usage at the start of async function
    if (!context.mounted || _currentUser == null) return;

    final nameCtrl = TextEditingController(text: _displayName);
    bool isSaving = false;

    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx2, setSB) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Edit Full Name",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                          labelText: "Full Name",
                          labelStyle: TextStyle(color: colorScheme.onSurface),
                          border: const OutlineInputBorder(),
                          fillColor: colorScheme.surfaceContainerHighest,
                          filled: true,
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isSaving ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                        minimumSize: const Size(double.infinity, 48)),
                    onPressed: isSaving || nameCtrl.text.trim().isEmpty
                        ? null
                        : () async {
                              setSB(() => isSaving = true);
                              final newName = nameCtrl.text.trim();
                                              
                              try {
                                  await _currentUser!.updateDisplayName(newName);

                                  await _currentUser!.reload();
                                  _loadUserData();
                                  
                                  // Use sheetCtx.mounted check for interaction with a parent context's state/scaffold
                                  if (sheetCtx.mounted) {
                                    await _updateUserComments(
                                        newDisplayName: newName, 
                                        newPhotoUrl: _currentUser!.photoURL ?? ''
                                    ); 
                                  }

                                  if (sheetCtx.mounted) {
                                    // Use context.mounted for global context functions like setState on the main widget
                                    if (mounted) setState(() {});
                                    
                                    Navigator.of(sheetCtx).pop(newName);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Name and comments updated successfully!'), backgroundColor: accentGreen),
                                    );
                                  }
                              } catch (e) {
                                  if (sheetCtx.mounted) {
                                    setSB(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to update name. Try logging in again.'), backgroundColor: Colors.red),
                                    );
                                  }
                              }
                            },
                    child: isSaving
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary)))
                        : Text("Save", style: TextStyle(color: colorScheme.onPrimary)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    nameCtrl.dispose();
  }


  // NAVIGATION LOGIC
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsPage())); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        toolbarHeight: 52,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(colorScheme)
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: colorScheme.onSurface));
    }
    if (_currentUser == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("User not logged in.",
              style: TextStyle(color: colorScheme.onSurface)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context)
                .pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const LoginPage()),
                    (r) => false),
            child: const Text("Go to Login"),
          )
        ]),
      );
    }

    return Column(
      children: [
        // Using the modularized ProfileHeader
        ProfileHeader(
            currentUser: _currentUser,
            profileImageFile: _profileImageFile,
            displayName: _displayName,
            userEmail: _userEmail,
            initials: _initials,
            onProfilePicTap: _onProfilePicTap,
        ),
        Expanded(
          child: _buildInfoSection(colorScheme),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: ListView(
        children: [
          Text(
            'PROFILE DETAILS',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Using the modularized ProfileInfoRow
          ProfileInfoRow(
            icon: Icons.person_outline,
            label: 'Full name',
            value: _displayName,
            valueColor: colorScheme.onSurface,
            // FIX: Guard call with context.mounted (which is guaranteed by mounted check in outer widget lifecycle)
            onTap: () async { if (mounted) await _showEditFullNameSheet(context, colorScheme); },
          ),
          const SizedBox(height: 10),
          ProfileInfoRow(
            icon: Icons.transgender,
            label: 'Gender',
            value: _userGender,
            valueColor: colorScheme.onSurface,
            // FIX: Guard call with context.mounted
            onTap: () async { if (mounted) await _showEditGenderSheet(context, colorScheme); },
          ),
          const SizedBox(height: 10),
          ProfileInfoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: _userDOB,
            valueColor: colorScheme.onSurface,
            // FIX: Guard call with context.mounted
            onTap: () async { if (mounted) await _showEditDOBDialog(context, colorScheme); },
          ),
          const SizedBox(height: 10),
          ProfileInfoRow(
            icon: Icons.delete_outline,
            label: 'Delete account',
            value: 'All your data will be permanently removed',
            valueColor: colorScheme.error,
            // FIX: Guard call with context.mounted
            onTap: () async { if (mounted) await _confirmDeleteAccount(colorScheme); },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }


  Future<void> _onProfilePicTap() async {
    // FIX: Guard context usage at the start of async function
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    final prefs = await SharedPreferences.getInstance();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  // FIX: Replaced .withOpacity(0.15) with .withAlpha(38)
                  color: accentGreen.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.person_outline, size: 20, color: accentGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                splashRadius: 20,
                onPressed: () => Navigator.of(ctx).pop(),
                icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: _profileImageFile != null
                        ? CircleAvatar(radius: 22, backgroundImage: FileImage(_profileImageFile!))
                        : (_currentUser?.photoURL?.isNotEmpty == true
                            ? CircleAvatar(radius: 22, backgroundImage: NetworkImage(_currentUser!.photoURL!))
                            : CircleAvatar(
                                radius: 22,
                                backgroundColor: primaryColor,
                                child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 20)),
                              )
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Choose how you want to update your photo.',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    // --- CAMERA FEATURE IMPLEMENTATION ---
                    final picked = await _imagePicker.pickImage(
                      source: ImageSource.camera, // CHANGE SOURCE TO CAMERA
                      maxWidth: 900,
                      imageQuality: 90,
                    );
                    
                    // FIX: Check mounted before using context/setState
                    if (picked != null && mounted) {
                      final file = File(picked.path);
                      setState(() => _profileImageFile = file);
                      await prefs.setString('profile_pic_path', file.path);
                      
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                          await _updateUserComments(
                              newDisplayName: _displayName,
                              newPhotoUrl: currentUser.photoURL ?? ''
                          );
                      }

                      // FIX: Use context from builder scope for navigation
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Photo taken and profile updated!'), backgroundColor: accentGreen),
                        );
                      }
                    }
                    // --- END CAMERA FEATURE IMPLEMENTATION ---
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            // FIX: Replaced .withOpacity(0.12) with .withAlpha(31)
                            color: accentGreen.withAlpha(31),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.photo_camera_outlined, color: accentGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Take a photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    final picked = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 900,
                      imageQuality: 90,
                    );
                    
                    // FIX: Check mounted before using context/setState
                    if (picked != null && mounted) {
                      final file = File(picked.path);
                      setState(() => _profileImageFile = file);
                      await prefs.setString('profile_pic_path', file.path);
                      
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                          await _updateUserComments(
                              newDisplayName: _displayName,
                              newPhotoUrl: currentUser.photoURL ?? ''
                          );
                      }

                      // FIX: Use context from builder scope for navigation
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Profile photo and comments updated!'), backgroundColor: accentGreen),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            // FIX: Replaced .withOpacity(0.12) with .withAlpha(31)
                            color: accentGreen.withAlpha(31),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.photo_library_outlined, color: accentGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Choose from library', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_profileImageFile != null || (_currentUser?.photoURL?.isNotEmpty == true))
                Material(
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      // REMOVE LOCAL FILE PATH AND CLEAR UI STATE
                      // FIX: Check mounted before using setState
                      if (mounted) setState(() => _profileImageFile = null);
                      await prefs.remove('profile_pic_path');
                      
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                          await _updateUserComments(
                              newDisplayName: _displayName,
                              newPhotoUrl: currentUser.photoURL ?? '' 
                          );
                      }
                      
                      // FIX: Use context from builder scope for navigation
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Profile photo and comments updated!'), backgroundColor: scheme.error),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              // FIX: Replaced .withOpacity(0.18) with .withAlpha(46)
                              color: accentYellow.withAlpha(46),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: const Icon(Icons.delete_outline, color: accentYellow, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Remove photo',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.error),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
              style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(ColorScheme colorScheme) async {
    // FIX: Guard context usage at the start of async function
    if (!mounted) return;
    String? reason;
    bool acknowledged = false;
    final TextEditingController otherCtrl = TextEditingController();
    final reasons = [
      "I am no longer using my account",
      "I don’t understand how to use it",
      "ZAPAC is not available in my city",
      "Other",
    ];

    await showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSB) {
            final canDelete = (reason != null) && acknowledged;
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      // FIX: Replaced .withOpacity(0.18) with .withAlpha(46)
                      color: accentYellow.withAlpha(46),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.warning_amber_rounded, color: accentYellow, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Delete your account',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    splashRadius: 20,
                    onPressed: () {
                      FocusScope.of(ctx).unfocus(); 
                      final nav = Navigator.of(ctx, rootNavigator: true);
                      if (nav.canPop()) {
                        nav.pop();
                      }
                    },
                    icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This action is permanent. All your data will be removed and cannot be recovered.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    ...reasons.map((r) => RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(r, style: TextStyle(color: colorScheme.onSurface, fontSize: 13)),
                          value: r,
                          groupValue: reason,
                          onChanged: (v) {
                            if (ctx2.mounted) setSB(() => reason = v);
                          },
                          activeColor: accentGreen,
                        )),
                    if (reason == 'Other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: otherCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Tell us a bit more (optional)',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ],
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: acknowledged,
                      onChanged: (v) {
                        if (ctx2.mounted) setSB(() => acknowledged = v ?? false);
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: accentGreen,
                      title: Text(
                        'I understand that this action cannot be undone.',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentGreen),
                    minimumSize: const Size(120, 44),
                    foregroundColor: colorScheme.onSurface,
                  ),
                  onPressed: () {
                    FocusScope.of(ctx).unfocus(); 
                    final nav = Navigator.of(ctx, rootNavigator: true);
                    if (nav.canPop()) {
                      nav.pop();
                    }
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    minimumSize: const Size(140, 44),
                  ),
                  onPressed: canDelete
                      ? () async {
                            try {
                              await _currentUser?.delete();
                              await AuthService().signOut();
                              
                              if (ctx.mounted) {
                                Navigator.of(ctx).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                  (_) => false,
                                );
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text("Account successfully deleted."), backgroundColor: accentGreen)
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text("Deletion failed. Please log in again and try.")),
                                );
                              }
                            }
                          }
                      : null,
                  child: const Text('Delete account'),
                ),
              ],
            );
          },
        );
      },
    );

    otherCtrl.dispose();
  }

  Future<void> _showEditGenderSheet(BuildContext context, ColorScheme colorScheme) async {
    // FIX: Guard context usage at the start of async function
    if (!mounted) return;
    String? choice = _userGender != 'Not provided' ? _userGender : null;
    final prefs = await SharedPreferences.getInstance();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx2, setSB) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: colorScheme.secondary, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Text("Please specify your gender", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: Text("Male", style: TextStyle(color: colorScheme.onSurface)),
                value: "Male",
                groupValue: choice,
                activeColor: colorScheme.primary,
                onChanged: (v) => setSB(() => choice = v),
              ),
              RadioListTile<String>(
                title: Text("Female", style: TextStyle(color: colorScheme.onSurface)),
                value: "Female",
                groupValue: choice,
                activeColor: colorScheme.primary,
                onChanged: (v) => setSB(() => choice = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, minimumSize: const Size(double.infinity, 48)),
                onPressed: () => Navigator.of(sheetCtx).pop(choice),
                child: Text("OK", style: TextStyle(color: colorScheme.onPrimary)),
              ),
            ]),
          ),
        );
      },
    );

    // FIX: Check mounted again before using setState/async calls after dismissal
    if (result != null && mounted) {
      setState(() {
        _userGender = result ?? 'Not provided';
      });
      await prefs.setString('user_gender', _userGender);
    }
  }

  Future<void> _showEditDOBDialog(BuildContext context, ColorScheme colorScheme) async {
    // FIX: Guard context usage at the start of async function
    if (!mounted) return;
    DateTime initial = DateTime(2000);
    if (_userDOB != 'Not provided') {
        initial = DateTime.tryParse(_userDOB) ?? DateTime(2000);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: colorScheme.copyWith(
                primary: accentGreen,
                onPrimary: Colors.white,
            ),
          ),
          child: child!
        );
      },
    );
    // FIX: Check mounted again before using setState/async calls after dismissal
    if (picked != null && mounted) {
      final dobStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _userDOB = dobStr;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_dob', _userDOB);
    }
  }
}