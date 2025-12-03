import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Navigation & Auth Imports
import 'package:zapac/authentication/login_page.dart';
import 'package:zapac/authentication/authentication.dart';
import 'app_constants.dart'; // Assuming this holds your primary color/accentGreen

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
  static const String _userStatus = 'Daily Commuter'; // consistent with settings

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  // --- DATA LOADING LOGIC ---

  void _loadUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) return;

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
    } else if (_currentUser?.photoURL != null) {
      _profileImageFile = null;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateUserComments({required String newDisplayName, required String newPhotoUrl}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == null) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final querySnapshot = await firestore
        .collection('public_data')
        .doc('zapac_community')
        .collection('comments')
        .where('senderUid', isEqualTo: currentUser!.uid)
        .get();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {
        'imageUrl': newPhotoUrl,
        'sender': newDisplayName,
      });
    }
    await batch.commit();
  }

  // --- UI WIDGETS (MATCHING SETTINGS PAGE) ---

  Widget _buildProfileTile({
    required String title,
    required IconData icon,
    String? value, // Added to show current data (e.g. "Male")
    VoidCallback? onTap,
    Color? iconColor,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Logic from SettingsPage
    final tileIconColor = iconColor ?? 
        (isDanger 
            ? Colors.red[400] 
            : (isDarkMode ? Colors.blue[300] : const Color(0xFF4A6FA5)));
    
    final titleColor = isDanger 
        ? Colors.red[400] 
        : theme.textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tileIconColor?.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: tileIconColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            if (value != null) const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: _profileImageFile != null
              ? CircleAvatar(radius: 48, backgroundImage: FileImage(_profileImageFile!))
              : (_currentUser?.photoURL != null
                  ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(_currentUser!.photoURL!))
                  : CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF4A6FA5),
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6CA89A), // Accent Green
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final primaryColor = theme.primaryColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _onProfilePicTap, // Triggers photo edit logic
              child: _buildProfileAvatar(),
            ),
            const SizedBox(height: 16),
            Text(
              _displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _userStatus,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
       return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        body: const Center(child: CircularProgressIndicator()),
       );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('PERSONAL DETAILS'),
                _buildProfileTile(
                  title: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  value: _displayName,
                  onTap: () async => await _showEditFullNameSheet(context, theme.colorScheme),
                ),
                _buildProfileTile(
                  title: 'Gender',
                  icon: Icons.wc_rounded,
                  value: _userGender,
                  onTap: () async => await _showEditGenderSheet(context, theme.colorScheme),
                ),
                _buildProfileTile(
                  title: 'Date of Birth',
                  icon: Icons.cake_outlined,
                  value: _userDOB,
                  onTap: () async => await _showEditDOBDialog(context, theme.colorScheme),
                ),
                
                const SizedBox(height: 16),
                _buildSectionHeader('ACCOUNT CONTROL'),
                _buildProfileTile(
                  title: 'Delete Account',
                  icon: Icons.delete_outline_rounded,
                  isDanger: true,
                  onTap: () async => await _confirmDeleteAccount(theme.colorScheme),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Your data is managed securely.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC FUNCTIONS (Unchanged from functionality perspective, just style adaptations) ---

  Future<void> _showEditFullNameSheet(BuildContext context, ColorScheme colorScheme) async {
    if (!mounted || _currentUser == null) return;
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
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  Text("Edit Full Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                      ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isSaving ? Colors.grey : const Color(0xFF6CA89A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 50)),
                    onPressed: isSaving || nameCtrl.text.trim().isEmpty
                        ? null
                        : () async {
                              setSB(() => isSaving = true);
                              final newName = nameCtrl.text.trim();
                              try {
                                  await _currentUser!.updateDisplayName(newName);
                                  await _currentUser!.reload();
                                  _loadUserData();
                                  if (sheetCtx.mounted) {
                                    await _updateUserComments(newDisplayName: newName, newPhotoUrl: _currentUser!.photoURL ?? ''); 
                                  }
                                  if (sheetCtx.mounted) {
                                    if (mounted) setState(() {});
                                    Navigator.of(sheetCtx).pop(newName);
                                  }
                              } catch (e) {
                                  if (sheetCtx.mounted) setSB(() => isSaving = false);
                              }
                            },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Save Changes"),
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

  Future<void> _showEditGenderSheet(BuildContext context, ColorScheme colorScheme) async {
    if (!mounted) return;
    String? choice = _userGender != 'Not provided' ? _userGender : null;
    final prefs = await SharedPreferences.getInstance();

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx2, setSB) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text("Select Gender", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text("Male"),
                value: "Male",
                groupValue: choice,
                activeColor: const Color(0xFF6CA89A),
                onChanged: (v) => setSB(() => choice = v),
              ),
              RadioListTile<String>(
                title: const Text("Female"),
                value: "Female",
                groupValue: choice,
                activeColor: const Color(0xFF6CA89A),
                onChanged: (v) => setSB(() => choice = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6CA89A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50)
                ),
                onPressed: () => Navigator.of(sheetCtx).pop(choice),
                child: const Text("Confirm"),
              ),
            ]),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _userGender = result!);
      await prefs.setString('user_gender', _userGender);
    }
  }

  Future<void> _showEditDOBDialog(BuildContext context, ColorScheme colorScheme) async {
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
                primary: const Color(0xFF6CA89A),
                onPrimary: Colors.white,
            ),
          ),
          child: child!
        );
      },
    );
    if (picked != null && mounted) {
      final dobStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _userDOB = dobStr);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_dob', _userDOB);
    }
  }

  Future<void> _onProfilePicTap() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Update Photo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(Icons.camera_alt_rounded, "Camera", () async {
                  final picked = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 900, imageQuality: 90);
                  if (picked != null && mounted) {
                     setState(() => _profileImageFile = File(picked.path));
                     await prefs.setString('profile_pic_path', picked.path);
                     final cu = FirebaseAuth.instance.currentUser;
                     if (cu != null) await _updateUserComments(newDisplayName: _displayName, newPhotoUrl: cu.photoURL ?? '');
                     if (ctx.mounted) Navigator.pop(ctx);
                  }
                }),
                _buildPhotoOption(Icons.photo_library_rounded, "Gallery", () async {
                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 900, imageQuality: 90);
                  if (picked != null && mounted) {
                     setState(() => _profileImageFile = File(picked.path));
                     await prefs.setString('profile_pic_path', picked.path);
                     final cu = FirebaseAuth.instance.currentUser;
                     if (cu != null) await _updateUserComments(newDisplayName: _displayName, newPhotoUrl: cu.photoURL ?? '');
                     if (ctx.mounted) Navigator.pop(ctx);
                  }
                }),
                if (_profileImageFile != null || (_currentUser?.photoURL != null))
                  _buildPhotoOption(Icons.delete_outline_rounded, "Remove", () async {
                     setState(() => _profileImageFile = null);
                     await prefs.remove('profile_pic_path');
                     if (ctx.mounted) Navigator.pop(ctx);
                  }, isDestructive: true),
              ],
            )
          ],
        ),
      )
    );
  }

  Widget _buildPhotoOption(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.withOpacity(0.1) : const Color(0xFF6CA89A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF6CA89A), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(ColorScheme colorScheme) async {
    if (!mounted) return;

    final TextEditingController otherReasonCtrl = TextEditingController();
    String? selectedReason;
    bool acknowledged = false;
    
    final List<String> reasons = [
      "I am no longer using my account",
      "I don’t understand how to use it",
      "ZAPAC is not available in my city",
      "Other",
    ];

    // Define the accent color used in settings (Green)
    const accentColor = Color(0xFF6CA89A);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Logic to enable/disable button
            final bool canDelete = (selectedReason != null) && acknowledged;

            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              
              // --- Header ---
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Delete Account',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // --- Body ---
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please tell us why you are leaving:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // --- Radio Options ---
                    ...reasons.map((r) => RadioListTile<String>(
                      title: Text(r, style: const TextStyle(fontSize: 14)),
                      value: r,
                      groupValue: selectedReason,
                      activeColor: accentColor,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (val) {
                        setStateDialog(() => selectedReason = val);
                      },
                    )),

                    // --- "Other" Text Field ---
                    if (selectedReason == 'Other') 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextField(
                          controller: otherReasonCtrl,
                          decoration: InputDecoration(
                            hintText: "Please specify...",
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: accentColor),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                    const Divider(height: 24),

                    // --- Acknowledgment Checkbox ---
                    CheckboxListTile(
                      value: acknowledged,
                      activeColor: Colors.red[400], // Red for danger
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'I understand that this action is permanent and cannot be undone.',
                        style: TextStyle(
                          fontSize: 12, 
                          color: colorScheme.onSurface.withOpacity(0.8)
                        ),
                      ),
                      onChanged: (val) {
                        setStateDialog(() => acknowledged = val ?? false);
                      },
                    ),
                  ],
                ),
              ),

              // --- Actions ---
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel', 
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red[100],
                    disabledForegroundColor: Colors.white.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  // Button is disabled (null) if criteria not met
                  onPressed: canDelete
                      ? () async {
                          try {
                            // Close dialog first
                            Navigator.pop(ctx);
                            
                            // Show loading indicator overlay if you prefer, 
                            // or just await the deletion
                            await _currentUser?.delete();
                            await AuthService().signOut();
                            
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                                (_) => false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Account deleted successfully."),
                                  backgroundColor: accentColor,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Delete failed. Please log in again and try."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
    
    otherReasonCtrl.dispose();
  }
}