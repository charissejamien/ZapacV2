import 'package:flutter/material.dart';
import 'addNewRoute.dart';
import 'package:zapac/favorites/favorite_route.dart';
import 'routeDetail.dart';
// import 'favoriteRouteData.dart'; // REMOVED: No longer using local data
import 'package:zapac/core/widgets/bottomNavBar.dart';
import 'package:zapac/dashboard/dashboard.dart'; 
import 'package:zapac/settings/settings_page.dart'; 
// NEW IMPORTS
import 'package:zapac/favorites/favorite_routes_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FavoriteRoutesPage extends StatefulWidget {
  const FavoriteRoutesPage({super.key});

  @override
  State<FavoriteRoutesPage> createState() => _FavoriteRoutesPageState();
}

class _FavoriteRoutesPageState extends State<FavoriteRoutesPage> {
  // final List<FavoriteRoute> _favoriteRoutes = favoriteRoutes; // REMOVED
  
  // NEW: Instantiate the service
  final FavoriteRoutesService _routesService = FavoriteRoutesService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // Check if a user is logged in
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Favorite Routes',
          style: TextStyle(color: cs.onPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: cs.onPrimary,
            // Disable Add button if no user is logged in
            onPressed: user == null ? null : () { 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNewRoutePage()),
              );
            },
          ),
        ],
      ),
      body: user == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 60, color: cs.secondary.withOpacity(0.6)),
                const SizedBox(height: 16),
                Text(
                  'Please log in to view your favorite routes.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : StreamBuilder<List<FavoriteRoute>>(
            // Listen to the stream from the Firebase service
            stream: _routesService.favoriteRoutesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching routes: ${snapshot.error}',
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final favoriteRoutes = snapshot.data ?? [];

              if (favoriteRoutes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus, size: 60, color: cs.primary.withOpacity(0.6)),
                      const SizedBox(height: 16),
                      Text(
                        'No favorite routes saved yet.',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the "+" icon to add a new route.',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: favoriteRoutes.length,
                itemBuilder: (context, index) {
                  final route = favoriteRoutes[index];
                  return Card(
                    color: cs.surface,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Icon(Icons.route, color: cs.secondary),
                      title: Text(route.routeName, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From: ${route.startAddress.split(',').first}', style: TextStyle(color: cs.onSurface.withOpacity(0.8), fontSize: 13)),
                          Text('To: ${route.endAddress.split(',').first}', style: TextStyle(color: cs.onSurface.withOpacity(0.8), fontSize: 13)),
                          Text(
                            '${route.distance} | ${route.duration}',
                            style: TextStyle(color: cs.onSurface.withOpacity(0.8), fontSize: 12),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteDetailPage(route: route),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onItemTapped: (int index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }
        },
      ),
    );
  }
  
  // NEW: Helper function to show a confirmation dialog before deleting
  void _confirmDeleteRoute(BuildContext context, FavoriteRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${route.routeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (route.id != null) {
                _routesService.deleteFavoriteRoute(route.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${route.routeName} deleted.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}