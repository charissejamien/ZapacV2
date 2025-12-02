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
        // FIX: Added mounted check before setState, although generally safe here, it's good practice.
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
      // Last page: Navigate to Dashboard
      // FIX: The context usage here is before an await, but since it's navigating away, it's generally safe.
      // However, we ensure the context is still available for the MaterialPageRoute builder.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Dashboard()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildPageIndicator(int index, ColorScheme cs) {
    // 0.3 opacity ≈ alpha 77
    final inactiveAlpha = 77;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        // FIX: Replaced .withOpacity(0.3) with .withAlpha(77)
        color: _currentPage == index ? cs.primary : cs.primary.withAlpha(inactiveAlpha),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildTourPage({
    required String title,
    required String subtitle,
    required String description,
    required ColorScheme cs,
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
          
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              // FIX: Replaced cs.onBackground with cs.onSurface
              color: cs.onSurface,
            ),
          ),
          // Subtitle (or second line of title)
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              // FIX: Replaced cs.onBackground with cs.onSurface
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20.0),
          
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              // FIX: Replaced .withOpacity(0.8) with .withAlpha(204)
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
      // FIX: Replaced cs.background with cs.surface
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
                  // Page 1: Cebuano Buddy
                  _buildTourPage(
                    title: 'Your Cebuano Buddy',
                    subtitle: 'Commuting in Cebu, Simplified.',
                    description: 'Navigating the city shouldn\'t be a guessing game. Ditch the confusion and ride like a local.',
                    cs: cs,
                  ),
                  
                  // Page 2: Asa ni Muagi
                  _buildTourPage(
                    title: 'Never Ask "Asa ni Muagi?"',
                    subtitle: 'Again.',
                    description: 'Confused by Jeepney codes? Just type your destination. We’ll show you exactly which Jeep or Bus to take and where to say "Para!" (Stop).',
                    cs: cs,
                  ),
                  
                  // Page 3: Know Your Plete
                  _buildTourPage(
                    title: 'Know Your "Plete"',
                    subtitle: 'Before You Hop On.',
                    description: 'No more guessing how much to pay. Get accurate fare estimates for Jeeps, Modern Jeeps, and Buses so you can prepare your coins.',
                    cs: cs,
                  ),
                ],
              ),
            ),
            
            // Bottom UI (Indicators and Button)
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_numPages, (index) => _buildPageIndicator(index, cs)),
                  ),
                  const SizedBox(height: 30),
                  
                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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