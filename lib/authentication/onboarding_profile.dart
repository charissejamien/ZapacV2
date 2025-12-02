import 'package:flutter/material.dart';
import 'package:zapac/core/widgets/onboardHeader.dart';
import 'package:zapac/core/widgets/onboardFooter.dart'; 
import 'onboarding_tour.dart'; 

enum UserProfile {
  local,
  tourist,
  commuter,
}

class OnboardingProfilePage extends StatefulWidget {
  const OnboardingProfilePage({super.key});

  @override
  State<OnboardingProfilePage> createState() => _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends State<OnboardingProfilePage> {
  UserProfile? _selectedProfile;
  bool _isRedirecting = false;

  void _selectProfile(UserProfile profile) {
    if (_isRedirecting) return;

    if (mounted) {
      setState(() {
        _selectedProfile = profile;
        _isRedirecting = true;
      });
    }

    // Simulate checkmark highlight for 1 second, then navigate
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        // Navigate to OnboardingTourPage
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => OnboardingTourPage(
            userProfile: profile.toString().split('.').last, // pass selected profile
          )),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  Widget _buildProfileButton(UserProfile profile, String title, ColorScheme cs) {
    final bool isSelected = _selectedProfile == profile;
    final bool isFinished = isSelected && _isRedirecting;

    // Alpha conversions:
    // 0.1 opacity ≈ alpha 26
    // 0.2 opacity ≈ alpha 51
    const int alpha26 = 26;
    const int alpha51 = 51;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton(
              onPressed: _isRedirecting ? null : () => _selectProfile(profile),
              style: OutlinedButton.styleFrom(
                // FIX: Replaced .withOpacity(0.1) with .withAlpha(26)
                backgroundColor: isSelected ? cs.primary.withAlpha(alpha26) : cs.surface,
                foregroundColor: cs.primary,
                side: BorderSide(
                  color: isSelected 
                    // FIX: Replaced .withOpacity(0.2) with .withAlpha(51)
                    ? cs.primary 
                    : cs.onSurface.withAlpha(alpha51),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          
          // Blue checkmark animation on selection
          if (isFinished)
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedOpacity(
                // This opacity value is 1.0, which is fine, but for consistency:
                opacity: isFinished ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    // FIX: Replaced cs.background with cs.surface
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Alpha conversion: 0.7 opacity ≈ alpha 179
    const int alpha179 = 179;

    return Scaffold(
      // FIX: Replaced cs.background with cs.surface
      backgroundColor: cs.surface,
      
      appBar: const OnboardingHeader(),
      
      bottomNavigationBar: const AuthFooter(),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Header Text
              Text(
                "Welcome to ZAPAC!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your Cebu commuting guide. How will you primarily use ZAPAC?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
                  color: cs.onSurface.withAlpha(alpha179),
                ),
              ),
              
              const SizedBox(height: 60),

              // Stacked Buttons
              _buildProfileButton(UserProfile.local, "Cebu Local", cs),
              _buildProfileButton(UserProfile.tourist, "Tourist", cs),
              _buildProfileButton(UserProfile.commuter, "Daily Commuter", cs),
            ],
          ),
        ),
      ),
    );
  }
}