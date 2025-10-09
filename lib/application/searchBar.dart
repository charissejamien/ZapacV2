import 'package:flutter/material.dart';
// Note: Assuming these external pages exist in your new project structure
// import 'package:zapac/profile_page.dart'; 
// import 'package:zapac/search_destination_page.dart'; 
import 'package:zapac/account/profile.dart'; // Assuming this path

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
    // FIX: Placeholder for navigation to a dedicated search page (SearchDestinationPage)
    // Since SearchDestinationPage definition wasn't provided, we mock the result handling.
    
    // Simulate navigation/result acquisition:
    final result = null; 

    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) =>
    //         const SearchDestinationPage(initialSearchText: ''),
    //   ),
    // );

    if (result != null && widget.onPlaceSelected != null) {
      _handleSearchResult(result);
      widget.onPlaceSelected!(result);
    } else {
        // Mock scenario if no search page is defined yet
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Search functionality coming soon.')),
        );
    }
  }

  void _handleSearchResult(Map<String, dynamic> result) {
    if (result.containsKey('place')) {
      _searchController.text = result['place']['description'];
    } else if (result.containsKey('route')) {
      // Assuming 'route' item has a 'routeName' property
      _searchController.text = result['route']['routeName'] ?? 'Selected Route';
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
                // Navigate to the correct ProfilePage path
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
