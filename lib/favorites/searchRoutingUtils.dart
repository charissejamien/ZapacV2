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
                    onChanged: (_) {}, 
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
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Text("Favorite Routes (${favoriteRoutes.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: predictions.isNotEmpty ? predictions.length : recentLocations.length,
              itemBuilder: (context, index) {
                if (predictions.isNotEmpty) {
                  final prediction = predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(prediction['description']),
                    onTap: () => onRoute({'place': prediction}),
                  );
                } else {
                  final recentLocation = recentLocations[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(recentLocation['name'] as String),
                    onTap: () => onRoute({'recent_location': recentLocation}),
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildRouteInfoSheetUtil({
  required Map<String, dynamic> routeInfo,
  required VoidCallback onClear,
}) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
