import 'package:flutter/material.dart';
// Note: Assuming these external pages exist in your new project structure
import 'package:zapac/settings/profile_page.dart'; 
import 'package:zapac/favorites/searchDestination.dart'; 

class SearchBar extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final Function(dynamic)? onPlaceSelected; // Changed type to dynamic to accept general result maps
  final VoidCallback? onSearchCleared; 

  const SearchBar({
    super.key, 
    this.onProfileTap, 
    this.onPlaceSelected,
    this.onSearchCleared, 
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen for text changes to update the icon (Profile vs. X)
    _searchController.addListener(_onSearchTextChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChange);
    _searchController.dispose();
    super.dispose();
  }

  // Triggers a state change when text is entered/cleared to rebuild the widget
  void _onSearchTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearSearch() {
    // 1. Clear the text field
    _searchController.clear();
    // 2. Notify the parent (Dashboard) that the search is cleared
    widget.onSearchCleared?.call(); 
    // The listener handles the icon reversion via setState()
  }

  void _openSearchPage() async {
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
  
  // NEW: Encapsulated logic for the right-side button tap
  void _onActionButtonTap(bool hasSearchText) {
    if (hasSearchText) {
      // Action when text is present: Clear search
      _clearSearch();
    } else {
      // Action when text is empty: Navigate to Profile
      widget.onProfileTap?.call();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()), 
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine which icon and action to use
    final bool hasSearchText = _searchController.text.isNotEmpty;
    final IconData actionIcon = hasSearchText ? Icons.close : Icons.account_circle;
    
    // Define the color for the icon button background
    const Color iconBackgroundColor = Color(0xFF6CA89A);

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
                    decoration: InputDecoration(
                      hintText: 'Where to?',
                      // Hint color set to gray for contrast
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 99, 99, 99), 
                        fontWeight: FontWeight.w400,
                      ),
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
          // Profile/Exit Icon button (Dynamically switched)
          GestureDetector(
            onTap: () => _onActionButtonTap(hasSearchText), // Use unified tap handler
            child: Container(
              width: 34,
              height: 32,
              decoration: const BoxDecoration(
                color: iconBackgroundColor, // Retain the existing button color
                shape: BoxShape.circle,
              ),
              child: Icon(
                actionIcon, 
                color: Colors.white,
                size: actionIcon == Icons.close ? 20 : 24, // Smaller 'X' looks better
              ),
            ),
          ),
        ],
      ),
    );
  }
}