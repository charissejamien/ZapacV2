import 'package:flutter/material.dart';
import 'package:zapac/favorites/favoriteRouteData.dart';
import 'package:zapac/core/utils/map_utils.dart';

Future<List<dynamic>> getPredictionsUtil(String input, String apiKey) async {
  return await getPredictions(input, apiKey);
}

Widget buildSearchViewUtil({
  required TextEditingController searchController,
  required List<dynamic> predictions,
  required List<Map<String, dynamic>> recentLocations,
  required Function(Map<String, dynamic>) onRoute,
  required VoidCallback onClose,
}) {
  return Container(
    color: Colors.white,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (_) {}, // Handled externally
                    decoration: const InputDecoration.collapsed(
                      hintText: "Where to?",
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (favoriteRoutes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: favoriteRoutes
                    .map(
                      (route) => ElevatedButton(
                        onPressed: () => onRoute({'route': route}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6CA89A),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(route.routeName),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (favoriteRoutes.isNotEmpty) const Divider(height: 1),
          Expanded(
            child: searchController.text.isEmpty
                ? buildListUtil(recentLocations, Icons.history, onRoute)
                : buildListUtil(predictions, Icons.location_on_outlined, onRoute),
          ),
        ],
      ),
    ),
  );
}

Widget buildListUtil(List<dynamic> items, IconData icon, Function(Map<String, dynamic>) onRoute) {
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(items[index]['description']),
        onTap: () => onRoute({'place': items[index]}),
      );
    },
  );
}

Widget buildRouteDetailsSheetUtil(Map<String, dynamic> routeInfo, VoidCallback onClear) {
  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Route to Destination",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Distance", style: TextStyle(color: Colors.grey)),
                    Text(
                      routeInfo['distance'] ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Duration", style: TextStyle(color: Colors.grey)),
                    Text(
                      routeInfo['duration'] ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE97C7C),
                foregroundColor: Colors.white,
              ),
              child: const Text("Clear Route"),
            ),
          ],
        ),
      ),
    ),
  );
}
