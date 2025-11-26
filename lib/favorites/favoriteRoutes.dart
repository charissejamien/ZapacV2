import 'package:flutter/material.dart';
import 'addNewRoute.dart';
import 'package:zapac/favorites/favorite_route.dart';
import 'routeDetail.dart';
import 'favoriteRouteData.dart';
import 'package:zapac/core/widgets/bottomNavBar.dart';
import 'package:zapac/dashboard/dashboard.dart'; 
import 'package:zapac/settings/settings_page.dart'; 

class FavoriteRoutesPage extends StatefulWidget {
  const FavoriteRoutesPage({super.key});

  @override
  State<FavoriteRoutesPage> createState() => _FavoriteRoutesPageState();
}

class _FavoriteRoutesPageState extends State<FavoriteRoutesPage> {
  final List<FavoriteRoute> _favoriteRoutes = favoriteRoutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNewRoutePage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _favoriteRoutes.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, size: 60, color: cs.primary.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite routes saved yet.',
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _favoriteRoutes.length,
                itemBuilder: (context, index) {
                  final route = _favoriteRoutes[index];
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
                          // The problematic 'Estimated Fare' text has been removed here.
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
              ),
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
}