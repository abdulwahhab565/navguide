import 'package:flutter/material.dart';
import '../main.dart' show AppTheme;
import '../models/campus_location.dart';
import '../services/places_service.dart';

class CampusSearchDelegate extends SearchDelegate<CampusLocation?> {
  final PlacesService _placesService = PlacesService();

  @override
  String get searchFieldLabel => 'Search UENR buildings, halls...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E2030),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppTheme.onSurface, fontSize: 16),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: Colors.white70),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResultsList(context);
  }

  Widget _buildSearchResultsList(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: FutureBuilder<List<CampusLocation>>(
        future: _placesService.searchCampusPlaces(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error searching locations: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'No campus locations found for "$query"',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withValues(alpha: 0.05),
              height: 1,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final loc = results[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    _iconForCategory(loc.category),
                    color: AppTheme.primaryLight,
                    size: 22,
                  ),
                ),
                title: Text(
                  loc.name,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  '${loc.category}${loc.buildingCode != null ? ' • ${loc.buildingCode}' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(Icons.north_west_rounded, color: Colors.white30, size: 18),
                onTap: () => close(context, loc),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'academic': return Icons.school_rounded;
      case 'administration': return Icons.account_balance_rounded;
      case 'services': return Icons.support_agent_rounded;
      case 'amenities': return Icons.restaurant_rounded;
      case 'restrooms': return Icons.wc_rounded;
      default: return Icons.location_on_rounded;
    }
  }
}