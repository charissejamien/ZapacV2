import 'package:flutter/material.dart';
import 'package:zapac/dashboard/dashboard.dart';

class OnboardingTourPage extends StatefulWidget {
  // A place to store the selected profile, if needed later
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
        setState(() {
          _currentPage = _pageController.page!.round();
        });
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Dashboard()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildPageIndicator(int index, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? cs.primary : cs.primary.withOpacity(0.3),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Placeholder for image/illustration here
          SizedBox(
            height: 200,
            child: Icon(
              Icons.directions_bus, 
              size: 100, 
              color: cs.primary.withOpacity(0.5)
            ),
          ),
          const SizedBox(height: 50.0),
          
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onBackground,
            ),
          ),
          // Subtitle (or second line of title)
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onBackground,
            ),
          ),
          const SizedBox(height: 20.0),
          
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: cs.onSurface.withOpacity(0.8),
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
      backgroundColor: cs.background,
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