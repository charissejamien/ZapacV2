import 'package:flutter/material.dart';
// Note: Assuming these external pages exist in your new project structure
// Original imports were messy, updating to consistent relative path:
import 'package:zapac/settings/profile_page.dart'; 
import 'package:zapac/favorites/searchDestination.dart'; 

class SearchBar extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final Function(dynamic)? onPlaceSelected; // Changed type to dynamic to accept general result maps

  const SearchBar({super.key, this.onProfileTap, this.onPlaceSelected});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearchPage() async {
    // FIX: This code is now UNCOMMENTED and performs navigation.
    // It passes the current search text (if any) and expects a result back.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchDestinationPage(initialSearchText: _searchController.text),
      ),
    );

    if (result != null && widget.onPlaceSelected != null) {
      _handleSearchResult(result);
      widget.onPlaceSelected!(result);
    } else {
        // We no longer need the mock Snackbar since navigation is enabled.
    }
  }

  void _handleSearchResult(Map<String, dynamic> result) {
    if (result.containsKey('place')) {
      // Result from Google Places Autocomplete prediction
      _searchController.text = result['place']['description'];
    } else if (result.containsKey('route')) {
      // Result from a favorited route button on SearchDestinationPage
      _searchController.text = result['route']['routeName'] ?? 'Selected Route';
    } else if (result.containsKey('recent_location')) {
      // Result from a recent location selection
      _searchController.text = result['recent_location']['name'] ?? 'Selected Location';
    } else {
       _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: ShapeDecoration(
        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFD9E0EA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(70)),
        shadows: [
          BoxShadow(
            color: const Color(0xFF4A6FA5).withOpacity(0.4),
            blurRadius: 6.8,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: isDark ? Colors.white70 : const Color(0xFF6CA89A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    readOnly: true,
                    // FIX: This now calls the method that pushes the SearchDestinationPage
                    onTap: _openSearchPage,
                    decoration: const InputDecoration(
                      hintText: 'Where to?',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    cursorColor: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Profile Icon button
          GestureDetector(
            onTap: () {
              widget.onProfileTap?.call();
              Navigator.push(
                context,
                // Assuming this path is correct based on your existing structure
                MaterialPageRoute(builder: (context) => const ProfilePage()), 
              );
            },
            child: Container(
              width: 34,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF6CA89A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}