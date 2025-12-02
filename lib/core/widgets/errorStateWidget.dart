import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onTryAgain;

  // Placeholder for the custom illustration icon
  final Widget illustration;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onTryAgain,
    required this.illustration,
  });

  // Color matching the image (a soft, muted rose/pink)
  static const Color _cardColor = Color(0xFFF0D1D1);
  static const Color _buttonColor = Color(0xFFD38B8B); 
  static const Color _textColor = Color(0xFF333333); 
  static const Color _backgroundColor = Color(0xFF1F1F1F); // Dark background hint

  @override
  Widget build(BuildContext context) {
    // Determine background color based on overall app theme
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBg = isDarkMode ? _backgroundColor : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("No Signal"), // Matches the text in the image
        backgroundColor: scaffoldBg,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The Illustrated Card Section
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background shape (two overlapping semi-circles)
                    Positioned(
                      top: 0,
                      child: Container(
                        height: 200,
                        width: 300,
                        decoration: BoxDecoration(
                          color: _cardColor.withAlpha(102),
                          borderRadius: BorderRadius.circular(1000), // Large radius for semi-circle effect
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      child: Container(
                        height: 200,
                        width: 300,
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(1000),
                        ),
                      ),
                    ),
                    // The custom icon/illustration
                    Positioned(
                      top: 60,
                      child: illustration,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : _textColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : _textColor.withAlpha(204),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: onTryAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
