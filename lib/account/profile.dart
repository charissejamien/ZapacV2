import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:zapac/User.dart';
import 'package:zapac/application/dashboard.dart';
import 'package:zapac/authentication/login.dart';
import 'package:zapac/main.dart';

// --- Brand Accent Colors ---
const Color accentYellow = Color(0xFFF4BE6C);
const Color accentGreen = Color(0xFF6CA89A);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User? _currentUser;
  bool _isLoading = true;
  int _selectedIndex = 2; // Assuming Profile is index 2 in your BottomNavBar

  File? _profileImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    // _currentUser = AuthManager().currentUser;
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_pic_path');
    if (savedPath != null && File(savedPath).existsSync()) {
      _profileImageFile = File(savedPath);
    } else {
      _profileImageFile = null; // fallback to NetworkImage or AssetImage
    }
    setState(() => _isLoading = false);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
    // Handle other tabs as per your BottomNavBar setup
    // Example:
    // else if (index == 1) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (_) => const FavoriteRoutesPage()),
    //   );
    // } else if (index == 3) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (_) => const SettingsPage()),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        toolbarHeight: 52,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea( // SafeArea handles system intrusions
        child: _buildBody(colorScheme)
      ),
      // bottomNavigationBar: BottomNavBar(
      //   selectedIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      // ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: colorScheme.onBackground));
    }
    // if (_currentUser == null) {
    //   return Center(
    //     child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    //       Text("User not logged in.",
    //           style: TextStyle(color: colorScheme.onBackground)),
    //       const SizedBox(height: 20),
    //       ElevatedButton(
    //         onPressed: () => Navigator.of(context)
    //             .pushAndRemoveUntil(
    //                 MaterialPageRoute(
    //                     builder: (_) => const LoginPage()),
    //                 (r) => false),
    //         child: const Text("Go to Login"),
    //       )
    //     ]),
    //   );
    // }

    return Column(
      children: [
        _buildHeader(colorScheme), // This takes fixed vertical space
        // Expanded ensures the remaining space is given to the ListView for scrolling
        Expanded(
          child: _buildInfoSection(colorScheme),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    // ImageProvider<Object> avatar = _profileImageFile != null
    //     ? FileImage(_profileImageFile!)
    //     : (_currentUser!.profileImageUrl?.isNotEmpty == true
    //         ? NetworkImage(_currentUser!.profileImageUrl!)
    //         : const AssetImage('assets/logo.png'));

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
            // Avatar with subtle border ring + floating edit icon
            GestureDetector(
              onTap: _onProfilePicTap,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: colorScheme.onPrimary.withOpacity(0.15),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: colorScheme.surface,
                      // backgroundImage: avatar,
                    ),
                  ),
                  // Floating pencil
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: colorScheme.onPrimary.withOpacity(0.95),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _onProfilePicTap,
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
            // Name
            // Text(
            //   _currentUser!.fullName,
            //   textAlign: TextAlign.center,
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            //   style: TextStyle(
            //     color: colorScheme.onPrimary,
            //     fontSize: 20,
            //     fontWeight: FontWeight.w700,
            //     letterSpacing: 0.2,
            //   ),
            // ),
            const SizedBox(height: 4),
            // Role / tagline
            Text(
              'Daily Commuter',
              style: TextStyle(
                color: colorScheme.onPrimary.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            // Email with edit
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flexible(
                //   child: Text(
                //     _currentUser!.email,
                //     style: TextStyle(
                //       color: colorScheme.onPrimary.withOpacity(0.95),
                //       fontSize: 13,
                //     ),
                //     overflow: TextOverflow.ellipsis,
                //   ),
                // ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showEditEmailDialog(context, colorScheme),
                  child: Icon(
                    Icons.edit_outlined,
                    color: colorScheme.onPrimary.withOpacity(0.95),
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // NOTE: Removed the "Edit Profile" button entirely for a cleaner, more professional header.
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // MODIFIED: Improved vertical/horizontal padding for info section
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
        //   _infoRow(
        //     icon: Icons.person_outline,
        //     label: 'Full name',
        //     value: _currentUser!.fullName,
        //     valueColor: colorScheme.onSurface,
        //     onTap: () => _showEditFullNameSheet(context, colorScheme),
        //   ),
        // // Hook up to an editor when available
        //   const SizedBox(height: 10),
        //   _infoRow(
        //     icon: Icons.transgender,
        //     label: 'Gender',
        //     value: _currentUser!.gender ?? 'Not provided',
        //     valueColor: colorScheme.onSurface,
        //     onTap: () => _showEditGenderSheet(context, colorScheme),
        //   ),
        //   const SizedBox(height: 10),
        //   _infoRow(
        //     icon: Icons.cake_outlined,
        //     label: 'Date of Birth',
        //     value: _currentUser!.dateOfBirth ?? 'Not provided',
        //     valueColor: colorScheme.onSurface,
        //     onTap: () => _showEditDOBDialog(context, colorScheme),
        //   ),
          const SizedBox(height: 10),
          _infoRow(
            icon: Icons.delete_outline,
            label: 'Delete account',
            value: 'All your data will be permanently removed',
            valueColor: colorScheme.error,
            onTap: () => _confirmDeleteAccount(colorScheme),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    valueColor = valueColor ?? scheme.onSurface;

    final borderAccent = label.toLowerCase().contains('delete') ? accentYellow : accentGreen;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderAccent, width: 3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: scheme.onSurfaceVariant, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                            letterSpacing: 0.6,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: valueColor,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                    size: 18,
                    semanticLabel: 'Edit $label',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _onProfilePicTap() async {
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
                  color: accentGreen.withOpacity(0.15),
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
                  // CircleAvatar(
                  //   radius: 22,
                  //   backgroundColor: scheme.surfaceContainerHighest,
                  //   backgroundImage: _profileImageFile != null
                  //       ? FileImage(_profileImageFile!)
                  //       : (_currentUser?.profileImageUrl?.isNotEmpty == true
                  //           ? NetworkImage(_currentUser!.profileImageUrl!) as ImageProvider
                  //           : const AssetImage('assets/logo.png')),
                  // ),
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
              // Take a photo
              Material(
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature will be added soon!')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: accentGreen.withOpacity(0.12),
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
              // Choose from library
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
                    if (picked != null) {
                      final file = File(picked.path);
                      if (context.mounted) {
                        setState(() => _profileImageFile = file);
                        await prefs.setString('profile_pic_path', file.path);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Profile photo updated'), backgroundColor: accentGreen),
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
                            color: accentGreen.withOpacity(0.12),
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
              // if (_profileImageFile != null || (_currentUser?.profileImageUrl?.isNotEmpty == true))
                Material(
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      setState(() => _profileImageFile = null);
                      await prefs.remove('profile_pic_path');
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Profile photo removed'), backgroundColor: scheme.error),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: accentYellow.withOpacity(0.18),
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

  Widget _PhotoActionTile({
    required IconData icon,
    required String label,
    required String description,
    required Color iconColor,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: destructive ? scheme.error : scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _showEditEmailDialog(BuildContext context, ColorScheme colorScheme) async {
    // final emailCtrl = TextEditingController(text: _currentUser!.email);
    final passCtrl = TextEditingController();
    final emailFocus = FocusNode();
    final passFocus = FocusNode();

    bool showPass = false;
    bool isLoading = false;

    String? validateEmail(String value) {
      final v = value.trim();
      if (v.isEmpty) return 'Email is required';
      final r = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!r.hasMatch(v)) return 'Enter a valid email';
      return null;
    }

    String? validatePass(String value) {
      final v = value;
      if (v.isEmpty) return 'Password is required';
      if (v.length < 6) return 'Minimum 6 characters';
      return null;
    }

    bool canSubmitNow() =>
        // validateEmail(emailCtrl.text) == null &&
        validatePass(passCtrl.text) == null &&
        !isLoading;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSB) {
            final canSubmit = canSubmitNow();
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.alternate_email, size: 20, color: accentGreen),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Change your email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    splashRadius: 20,
                    onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'We’ll send a verification link to the new address. You’ll need to sign in again after this change.',
                        style: TextStyle(fontSize: 12, height: 1.3, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // TextField(
                    //   controller: emailCtrl,
                    //   focusNode: emailFocus,
                    //   keyboardType: TextInputType.emailAddress,
                    //   textInputAction: TextInputAction.next,
                    //   onSubmitted: (_) => passFocus.requestFocus(),
                    //   onChanged: (_) => setSB(() {}),
                    //   decoration: InputDecoration(
                    //     prefixIcon: const Icon(Icons.mail_outline),
                    //     labelText: 'New Email',
                    //     hintText: 'name@example.com',
                    //     errorText: emailCtrl.text.isEmpty ? null : validateEmail(emailCtrl.text),
                    //     border: const OutlineInputBorder(),
                    //     filled: true,
                    //     fillColor: colorScheme.surfaceContainerHighest,
                    //   ),
                    //   style: TextStyle(color: colorScheme.onSurface),
                    // ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      focusNode: passFocus,
                      textInputAction: TextInputAction.done,
                      obscureText: !showPass,
                      onChanged: (_) => setSB(() {}),
                      onSubmitted: (_) {
                        if (canSubmit) FocusScope.of(ctx).unfocus();
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        labelText: 'Password',
                        helperText: 'Minimum 6 characters',
                        errorText: passCtrl.text.isEmpty ? null : validatePass(passCtrl.text),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        suffixIcon: IconButton(
                          onPressed: () => setSB(() => showPass = !showPass),
                          icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () async {
                          setSB(() => isLoading = true);
                          try {
                            // final newEmail = emailCtrl.text.trim();
                            final newPassword = passCtrl.text;
                            // final updatedUser = User(
                            //   email: newEmail,
                            //   password: newPassword,
                            //   firstName: _currentUser!.firstName,
                            //   lastName: _currentUser!.lastName,
                            //   middleName: _currentUser!.middleName,
                            //   profileImageUrl: _currentUser!.profileImageUrl,
                            //   type: _currentUser!.type,
                            //   currentLocation: _currentUser!.currentLocation,
                            //   gender: _currentUser!.gender,
                            //   dateOfBirth: _currentUser!.dateOfBirth,
                            // );
                            // await AuthManager().updateUser(updatedUser);
                            if (ctx.mounted) {
                              // setState(() => _currentUser = updatedUser);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Email updated. Please verify via the link we sent.'),
                                  backgroundColor: accentGreen,
                                ),
                              );
                            }
                          } catch (_) {
                            if (ctx.mounted) {
                              setSB(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Something went wrong. Please try again.'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 44),
                    disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: colorScheme.onSurfaceVariant,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Update email'),
                ),
              ],
            );
          },
        );
      },
    );

  //   emailCtrl.dispose();
  //   passCtrl.dispose();
  //   emailFocus.dispose();
  //   passFocus.dispose();
  // }

  // Future<void> _showEditFullNameSheet(
  //         BuildContext context, ColorScheme colorScheme) async {
  //   final firstCtrl =
  //       TextEditingController(text: _currentUser!.firstName);
  //   final middleCtrl =
  //       TextEditingController(text: _currentUser!.middleName ?? '');
  //   final lastCtrl =
  //       TextEditingController(text: _currentUser!.lastName);

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          padding:
              const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius:
                          BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Text("Edit your data",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 16),
              // TextField(
              //     controller: firstCtrl,
              //     decoration: InputDecoration(
              //         labelText: "First name",
              //         labelStyle: TextStyle(color: colorScheme.onSurface),
              //         border: const OutlineInputBorder(),
              //         fillColor: colorScheme.surfaceContainerHighest,
              //         filled: true,
              //     ),
              //     style: TextStyle(color: colorScheme.onSurface),
              // ),
              // const SizedBox(height: 12),
              // TextField(
              //     controller: lastCtrl,
              //     decoration: InputDecoration(
              //         labelText: "Last name",
              //         labelStyle: TextStyle(color: colorScheme.onSurface),
              //         border: const OutlineInputBorder(),
              //         fillColor: colorScheme.surfaceContainerHighest,
              //         filled: true,
              //     ),
              //     style: TextStyle(color: colorScheme.onSurface),
              // ),
              // const SizedBox(height: 12),
              // TextField(
              //     controller: middleCtrl,
              //     decoration: InputDecoration(
              //         labelText: "Middle name",
              //         labelStyle: TextStyle(color: colorScheme.onSurface),
              //         border: const OutlineInputBorder(),
              //         fillColor: colorScheme.surfaceContainerHighest,
              //         filled: true,
              //     ),
              //     style: TextStyle(color: colorScheme.onSurface),
              // ),
              // const SizedBox(height: 24),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //       backgroundColor: colorScheme.primary,
              //       minimumSize:
              //           const Size(double.infinity, 48)),
              //   onPressed: () =>
              //       Navigator.of(sheetCtx).pop({
              //     'first': firstCtrl.text.trim(),
              //     'middle': middleCtrl.text.trim(),
              //     'last': lastCtrl.text.trim(),
              //   }),
              //   child: Text("OK",
              //       style:
              //           TextStyle(color: colorScheme.onPrimary)),
              // ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      // setState(() {
      //   _currentUser!
      //     ..firstName = result['first']!
      //     ..middleName = result['middle']
      //     ..lastName = result['last']!;
      // });
      // await AuthManager().updateUser(_currentUser!);
    }
  }

  Future<void> _showEditGenderSheet(BuildContext context, ColorScheme colorScheme) async {
    // String? choice = _currentUser!.gender;
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
              // RadioListTile<String>(
              //   title: Text("Male", style: TextStyle(color: colorScheme.onSurface)),
              //   value: "Male",
              //   groupValue: choice,
              //   activeColor: colorScheme.primary,
              //   onChanged: (v) => setSB(() => choice = v),
              // ),
              // RadioListTile<String>(
              //   title: Text("Female", style: TextStyle(color: colorScheme.onSurface)),
              //   value: "Female",
              //   groupValue: choice,
              //   activeColor: colorScheme.primary,
              //   onChanged: (v) => setSB(() => choice = v),
              // ),
              const SizedBox(height: 24),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, minimumSize: const Size(double.infinity, 48)),
              //   onPressed: () => Navigator.of(sheetCtx).pop(choice),
              //   child: Text("OK", style: TextStyle(color: colorScheme.onPrimary)),
              // ),
            ]),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        // _currentUser!.gender = result;
      });
      // await AuthManager().updateUser(_currentUser!);
    }
  }

  Future<void> _showEditDOBDialog(BuildContext context, ColorScheme colorScheme) async {
    // DateTime initial = DateTime.tryParse(_currentUser!.dateOfBirth ?? '') ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      // initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: colorScheme,
            // You might need to adjust other date picker specific colors here if necessary
            // e.g., textTheme for header, etc.
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      final dobStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      // setState(() {
      //   _currentUser!.dateOfBirth = dobStr;
      // });
      // await AuthManager().updateUser(_currentUser!);
    }
  }

  Future<void> _confirmDeleteAccount(ColorScheme colorScheme) async {
    String? reason;
    bool acknowledged = false;
    final TextEditingController otherCtrl = TextEditingController();
    final reasons = const [
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
                      color: accentYellow.withOpacity(0.18),
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
                      FocusScope.of(context).unfocus();
                      final nav = Navigator.of(context, rootNavigator: true);
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
                          title: Text(r, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
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
                    FocusScope.of(context).unfocus();
                    final nav = Navigator.of(context, rootNavigator: true);
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
                      ? () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (_) => false,
                          );
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
}
