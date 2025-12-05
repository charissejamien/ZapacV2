import 'package:flutter/material.dart';
import 'package:zapac/core/widgets/onboardHeader.dart';
import 'package:zapac/core/widgets/onboardFooter.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

// === NEW IMPORT for Location Logic ===
import 'package:zapac/core/utils/map_utils.dart'; // Assuming map_utils.dart is in a sibling directory or adjust as needed.

class OnboardingTourPage extends StatefulWidget {

  final String userProfile;
  const OnboardingTourPage({super.key, required this.userProfile});

  @override
  State<OnboardingTourPage> createState() => _OnboardingTourPageState();
}

class _OnboardingTourPageState extends State<OnboardingTourPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // === MODIFIED: Increased page count from 3 to 4 ===
  final int _numPages = 4; //

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

  // Completes onboarding and navigates to the main app
  Future<void> _completeOnboardingAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    if (mounted) {
      // Navigate to the MainShell via '/app' route
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/app',
        (Route<dynamic> route) => false,
      );
    }
  }

  // === NEW FUNCTION: Triggers the OS location prompt and then navigates ===
  Future<void> _onEnableLocationPressed() async {
    // This function from map_utils handles the permission check and displays the OS prompt
    await MapUtils.getCurrentLocation(context); 

    // Regardless of whether permission was granted or denied, the user has completed this step.
    if (mounted) {
      await _completeOnboardingAndNavigate(); 
    }
  }

  void _onNextPressed() {
    // Only navigate to the next page if not on the new last page (index 3)
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } 
  }

  // === MODIFIED FUNCTION: Skips to the final location page (index 3) ===
  void _onSkipPressed() {
     _pageController.animateToPage(
       _numPages - 1, // Jump to the last page (index 3)
       duration: const Duration(milliseconds: 400),
       curve: Curves.easeInOut,
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
          height: 1.1,
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
            height: 240, 
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


  // === NEW PAGE FOR LOCATION PROMPT ===
  Widget _buildLocationPage(ColorScheme cs) { //
    // 0.8 opacity ≈ alpha 204
    final descriptionAlpha = 204;
    final greenColor = const Color(0xFF6CA89A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Placeholder Image or Icon for Location
          Image.asset(
            'assets/onboardingOne.png',
            height: 280, // Maintain original size constraint
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 30.0),
          
         // Title 1
        _buildGradientText(
          'Ready to \nZap around Cebu?', 
          36, 
          isTitle: true, 
        ),
          const SizedBox(height: 30.0),

          // Title 2 (Subtitle)
          Text(
            'Enable your location to find the nearest stops around you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: cs.onSurface.withAlpha(descriptionAlpha),
            ),
          ),

          const SizedBox(height: 10.0),
          
          // Description
          Text(
            'We prioritize your privacy and only use location for navigation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: cs.onSurface.withAlpha(descriptionAlpha),
            ),
          ),
          
          const SizedBox(height: 20.0),

          // Enable Locations Button
          ElevatedButton(
            onPressed: _onEnableLocationPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor, 
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Enable Locations",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
    
    // Check if it's the new second-to-last page
    final isPenultimatePage = _currentPage == _numPages - 2; 
    // Check if it's the new last page
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
                  
                  // Page 3 (Old last page, now second-to-last)
                  _buildTourPage(
                    title: 'Know Your "Plete"',
                    subtitle: 'Before You Hop On.',
                    description: 'No more guessing how much to pay. Get accurate fare estimates for Jeeps, Modern Jeeps, and Buses so you can prepare your coins.',
                    cs: cs,
                    imagePath: 'assets/onboardingThree.png',
                  ),

                  // === Page 4 (New last page) ===
                  _buildLocationPage(cs), //
                ],
              ),
            ),
            
            // The bottom row is only needed for the first three pages.
            if (!isLastPage)
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkipPressed, // Jumps to the location page
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
                    // The indicator includes the new 4th page
                    children: List.generate(_numPages, (index) => _buildPageIndicator(index, cs)),
                  ),

                  TextButton(
                    // On the second-to-last page, this navigates to the final location page.
                    onPressed: _onNextPressed, 
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 40),
                    ),
                    child: Text(
                      isPenultimatePage ? 'Get Started' : 'Next',
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
            // Still show the indicator on the last page for context
            if (isLastPage)
            Padding(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_numPages, (index) => _buildPageIndicator(index, cs)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}