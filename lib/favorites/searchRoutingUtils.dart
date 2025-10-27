import 'package:flutter/material.dart';
import 'package:zapac/favorites/favoriteRouteData.dart';
import 'package:zapac/core/utils/map_utils.dart'; 
import 'dart:async';

// Fixed: Calls MapUtils.getPredictions
Future<List<dynamic>> getPredictionsUtil(String input, String apiKey) async {
  return await MapUtils.getPredictions(input, apiKey);
}

Widget buildSearchViewUtil({
  required BuildContext context, // FIX: Added context
  required TextEditingController searchController,
  required List<dynamic> predictions,
  required List<Map<String, dynamic>> recentLocations,
  required Function(Map<String, dynamic>) onRoute,
  required VoidCallback onClose,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  
  return Container(
    color: theme.scaffoldBackgroundColor,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: onClose,
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (_) {}, 
                    decoration: InputDecoration.collapsed(
                      hintText: "Where to?",
                      hintStyle: TextStyle(color: theme.hintColor),
                    ),
                    style: TextStyle(color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
          if (favoriteRoutes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Text(
                "Favorite Routes (${favoriteRoutes.length})", 
                style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: predictions.isNotEmpty ? predictions.length : recentLocations.length,
              itemBuilder: (context, index) {
                if (predictions.isNotEmpty) {
                  final prediction = predictions[index];
                  return ListTile(
                    leading: Icon(Icons.location_on, color: cs.secondary),
                    title: Text(prediction['description'], style: TextStyle(color: cs.onSurface)),
                    onTap: () => onRoute({'place': prediction}),
                  );
                } else {
                  final recentLocation = recentLocations[index];
                  return ListTile(
                    leading: Icon(Icons.history, color: cs.secondary),
                    title: Text(recentLocation['name'] as String, style: TextStyle(color: cs.onSurface)),
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
  required BuildContext context, // FIX: Added context
  required Map<String, dynamic> routeInfo,
  required VoidCallback onClear,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  
  return Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Route to Destination",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("Distance", style: TextStyle(color: theme.hintColor)),
                    Text(
                      routeInfo['distance'] ?? 'N/A',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text("Duration", style: TextStyle(color: theme.hintColor)),
                    Text(
                      routeInfo['duration'] ?? 'N/A',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
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