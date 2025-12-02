import 'package:flutter/material.dart';
import 'package:zapac/dashboard/dashboard.dart';
import 'package:zapac/core/widgets/onboardHeader.dart';
import 'package:zapac/core/widgets/onboardFooter.dart';

class OnboardingTourPage extends StatefulWidget {

  final String userProfile;
  const OnboardingTourPage({super.key, required this.userProfile});

  @override
  State<OnboardingTourPage> createState() => _OnboardingTourPageState();
}

class _OnboardingTourPageState extends State<OnboardingTourPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        if (mounted) {
          setState(() {
            _currentPage = _pageController.page!.round();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Dashboard()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Helper function for navigating directly to Dashboard
  void _onSkipPressed() {
     Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Dashboard()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildPageIndicator(int index, ColorScheme cs) {
    final inactiveAlpha = 77;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? cs.primary : cs.primary.withAlpha(inactiveAlpha),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildGradientText(String text, double fontSize, {required bool isTitle}) {
    final Color gradientStart = const Color(0xFF6CA89A);
    final Color gradientEnd = const Color(0xFF4A6FA5);

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [gradientStart, gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, 
        ),
      ),
    );
  }

  Widget _buildTourPage({
    required String? title,
    required String subtitle,
    required String description,
    required ColorScheme cs,
    required String imagePath,
  }) {
    // 0.8 opacity ≈ alpha 204
    final descriptionAlpha = 204;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 50.0),

          Image.asset(
            imagePath, 
            height: 280, 
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 30.0),
          
          // Title
          if (title != null && title.isNotEmpty) ...[
            _buildGradientText(title, 32, isTitle: true),
          ],
          
          // Subtitle
          _buildGradientText(subtitle, 32, isTitle: false),

          const SizedBox(height: 20.0),
          
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: cs.onSurface.withAlpha(descriptionAlpha),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLastPage = _currentPage == _numPages - 1;

    return Scaffold(
      backgroundColor: cs.surface,
      
      appBar: const OnboardingHeader(),
      
      bottomNavigationBar: const AuthFooter(),
      
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: <Widget>[
                  // Page 1
                  _buildTourPage(
                    title: null, 
                    subtitle: 'Commuting in Cebu, Simplified.',
                    description: 'Navigating the city shouldn\'t be a guessing game. Ditch the confusion and ride like a local.',
                    cs: cs,
                    imagePath: 'assets/onboardingOne.png',
                  ),
                  
                  // Page 2
                  _buildTourPage(
                    title: null,
                    subtitle: 'Never ask "Asa ni Muagi?" Again.',
                    description: 'Confused by Jeepney codes? Just type your destination. We’ll show you exactly which Jeep or Bus to take and where to say "Para!" (Stop).',
                    cs: cs,
                    imagePath: 'assets/onboardingTwo.png',
                  ),
                  
                  // Page 3
                  _buildTourPage(
                    title: 'Know Your "Plete"',
                    subtitle: 'Before You Hop On.',
                    description: 'No more guessing how much to pay. Get accurate fare estimates for Jeeps, Modern Jeeps, and Buses so you can prepare your coins.',
                    cs: cs,
                    imagePath: 'assets/onboardingThree.png',
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkipPressed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 40),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: cs.onSurface.withAlpha(204),
                        fontSize: 18,
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_numPages, (index) => _buildPageIndicator(index, cs)),
                  ),

                  TextButton(
                    onPressed: _onNextPressed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 40),
                    ),
                    child: Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}