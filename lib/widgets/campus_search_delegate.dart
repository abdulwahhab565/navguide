import 'package:flutter/material.dart';
import '../../main.dart' show AppTheme;
import '../../models/campus_location.dart';
import '../../presenters/search_presenter.dart';

/// Full-screen search delegate for campus facilities.
/// Implements [SearchViewContract] from SearchPresenter.
class CampusSearchDelegate extends SearchDelegate<CampusLocation?>
    implements SearchViewContract {
  final List<CampusLocation> allLocations;
  late final SearchPresenter _presenter;
  List<CampusLocation> _suggestions = [];
  BuildContext? _context;

  CampusSearchDelegate({required this.allLocations}) {
    _presenter = SearchPresenter(this, mockLocations: allLocations);
    _suggestions = allLocations.take(5).toList();
  }

  // ── SearchViewContract ────────────────────────────────────────
  @override
  void updateSuggestions(List<CampusLocation> suggestions) {
    _suggestions = suggestions;
  }

  @override
  void onLocationSelected(CampusLocation location) {
    if (_context != null) close(_context!, location);
  }

  // ── SearchDelegate overrides ──────────────────────────────────
  @override
  String get searchFieldLabel => 'Search buildings, halls, services…';

  @override
  TextStyle get searchFieldStyle => const TextStyle(
        color: AppTheme.onSurface,
        fontSize: 15,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E),
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Color(0xFF6B7080)),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _context = context;
    _presenter.search(query);
    return _buildList(context, isResults: true);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _context = context;
    _presenter.search(query);
    return _buildList(context, isResults: false);
  }

  Widget _buildList(BuildContext context, {required bool isResults}) {
    final items = _suggestions;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        color: Colors.white.withValues(alpha: 0.06),
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final loc = items[index];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _catColor(loc.category).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _catColor(loc.category).withValues(alpha: 0.4),
                  width: 1),
            ),
            child: Icon(_catIcon(loc.category),
                color: _catColor(loc.category), size: 22),
          ),
          title: Text(
            loc.name,
            style: const TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14.5),
          ),
          subtitle: Text(
            loc.category,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: Colors.white38, size: 20),
          onTap: () => _presenter.selectLocation(loc),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  static IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'academic':
        return Icons.school_rounded;
      case 'administration':
        return Icons.account_balance_rounded;
      case 'services':
        return Icons.support_agent_rounded;
      case 'amenities':
        return Icons.restaurant_rounded;
      case 'restrooms':
        return Icons.wc_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  static Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'academic':
        return Colors.blue.shade400;
      case 'administration':
        return Colors.purple.shade300;
      case 'services':
        return Colors.teal.shade300;
      case 'amenities':
        return Colors.orange.shade400;
      case 'restrooms':
        return Colors.cyan.shade300;
      default:
        return AppTheme.primaryLight;
    }
  }
}
