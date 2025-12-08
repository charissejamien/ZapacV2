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

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OnboardingTourPage(
              userProfile: profile.toString().split('.').last,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  Widget _buildProfileButton(
    UserProfile profile, String title, ColorScheme cs) {
  final bool isSelected = _selectedProfile == profile;
  final bool isFinished = isSelected && _isRedirecting;

  const gradientStart = Color(0xFF6CA89A);
  const gradientEnd = Color(0xFF4A6FA5);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: _isRedirecting ? null : () => _selectProfile(profile),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),

              border: isSelected
                  ? null
                  : Border.all(
                      width: 2,
                      color: Colors.transparent,
                    ),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),

            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: !isSelected
                    ? const LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),

              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? Colors.transparent : cs.surface,
                ),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (isFinished)
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedOpacity(
              opacity: isFinished ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.black),
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

    const int alpha179 = 179;

    return Scaffold(
      backgroundColor: cs.surface,

      appBar: const OnboardingHeader(),

      bottomNavigationBar: const AuthFooter(),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              Center(
                child: Image.asset(
                  "assets/Logo.png",
                  height: 130,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 30),

              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6CA89A),
                      Color(0xFF4A6FA5),
                    ],
                  ).createShader(bounds);
                },
                child: const Text(
                  "Welcome",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              Text(
                "Which best describes you?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: cs.onSurface.withAlpha(alpha179),
                ),
              ),

              const SizedBox(height: 30),

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
