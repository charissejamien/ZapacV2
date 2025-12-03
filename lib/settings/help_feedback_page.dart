import 'package:flutter/material.dart';

// --- Data Structure for Help Content ---
class FAQCategory {
  final String title;
  final List<FAQItem> questions;
  final IconData icon;

  const FAQCategory({required this.title, required this.questions, required this.icon});
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}

const List<FAQCategory> faqData = [
  FAQCategory(
    title: 'Getting Started',
    icon: Icons.directions_bus,
    questions: [
      FAQItem(
        question: 'How do I search for a route?',
        answer: 'Use the search bar at the top of the map. Type in your starting point and destination, and Zapac will provide the fastest/cheapest routes. You can then select a route to view details on the map.'
      ),
      FAQItem(
        question: 'How do I save a route as a Favorite?',
        answer: 'After viewing a route, tap the heart icon (♡) on the Route Details Overlay to save it to your Favorites tab in the bottom navigation bar.'
      ),
    ]
  ),
  FAQCategory(
    title: 'Map Features and Filters',
    icon: Icons.filter_alt,
    questions: [
      FAQItem(
        question: 'How do I change the map filter (e.g., Terminal to Mall)?',
        answer: 'At the bottom of the map, tap the "Filter" button (which shows the current filter name, e.g., "Terminal"). Select a category chip to update the map pins and filter label.'
      ),
      FAQItem(
        question: 'How do I reset my current location on the map?',
        answer: 'Tap the Floating Action Button (FAB) at the bottom right of the map screen. If it shows the location icon, it will center the map back to your GPS location.'
      ),
    ]
  ),
  FAQCategory(
    title: 'Community Insights',
    icon: Icons.lightbulb_outline,
    questions: [
      FAQItem(
        question: 'What are Community Insights and how do they work?',
        answer: 'Community Insights are real-time, user-submitted notes about traffic, road conditions, fare tips, and driver behavior along specific routes in Cebu.'
      ),
      FAQItem(
        question: 'How do I add a new insight?',
        answer: 'When the community insights view is active, tap the "+" button on the floating action button (FAB). You can then share your message and tag it to a specific route.'
      ),
    ]
  ),
];

// --- CONVERTED TO STATEFUL WIDGET ---

class HelpAndFeedbackPage extends StatefulWidget {
  const HelpAndFeedbackPage({super.key});

  @override
  State<HelpAndFeedbackPage> createState() => _HelpAndFeedbackPageState();
}

class _HelpAndFeedbackPageState extends State<HelpAndFeedbackPage> {
  // State to hold the selected rating (1 to 5)
  // *** FIX: Initialized to 0 so no stars are highlighted by default ***
  int _currentRating = 0; 

  // Helper to build the interactive star rating component
  Widget _buildStarRating() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starValue = index + 1;
          const Color selectedColor = Color(0xFFFFCC00); // Gold/Yellow
          const Color unselectedColor = Colors.grey;

          return GestureDetector(
            onTap: () {
              setState(() {
                // Set the current rating to the value of the star tapped (1 to 5)
                _currentRating = starValue;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: Icon(
                // Full star if its value is less than or equal to the current rating
                _currentRating >= starValue ? Icons.star_rounded : Icons.star_border_rounded,
                color: _currentRating >= starValue ? selectedColor : unselectedColor,
                size: 30, 
              ),
            ),
          );
        }),
      ),
    );
  }

  // Helper to build the top-level FAQ category tile (with dropshadow)
  Widget _buildCategoryTile(BuildContext context, ColorScheme cs, FAQCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          // *** DROPSHADOW FOR EACH TILE ***
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ExpansionTile(
            key: PageStorageKey(category.title),
            title: Text(
              category.title,
              style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16),
            ),
            leading: Icon(category.icon, color: cs.primary),
            collapsedIconColor: cs.onSurface.withOpacity(0.6),
            iconColor: cs.primary,
            children: category.questions.map((item) => _buildQuestionDropdown(context, cs, item)).toList(),
          ),
        ),
      ),
    );
  }

  // Helper to build the nested question dropdown (the inner dropdown)
  Widget _buildQuestionDropdown(BuildContext context, ColorScheme cs, FAQItem item) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 8.0),
      child: ExpansionTile(
        key: PageStorageKey(item.question),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(
          item.question,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: cs.onSurface),
        ),
        leading: Icon(Icons.help_outline, size: 20, color: cs.secondary),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 55.0, right: 16.0, bottom: 12.0),
            child: Text(
              item.answer,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the text box for feedback
  Widget _buildFeedbackBox(ColorScheme cs) {
    return TextFormField(
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'e.g., I would like to suggest a feature for route tracking...',
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.5)),
        fillColor: cs.surface,
        filled: true,
        // BORDER ADDED TO TEXT BOX
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: cs.onSurface, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.5), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: cs.primary, width: 2.0),
        ),
      ),
      style: TextStyle(color: cs.onSurface),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Feedback'),
        backgroundColor: cs.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Nested FAQs (with Dropshadow Tiles) ---
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            ...faqData.map((category) => _buildCategoryTile(context, cs, category)).toList(),

            const Divider(height: 30),

            // --- Section 2: Feedback and Contact ---
            Text(
              'Share Your Thoughts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // *** INTERACTIVE STAR RATING ***
            _buildStarRating(),

            // Text box for user feedback with border
            _buildFeedbackBox(cs),

            const SizedBox(height: 20),
            
            // Submit Button (Placeholder)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Display the selected rating in the SnackBar upon submission
                  String ratingText = _currentRating > 0 ? 'Rating: $_currentRating stars' : 'No rating provided';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Feedback Submitted! $ratingText'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('SUBMIT', style: TextStyle(color: cs.onPrimary)),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}