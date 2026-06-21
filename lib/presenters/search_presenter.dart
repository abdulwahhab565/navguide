import '../models/campus_location.dart';
import '../config/app_config.dart';

abstract class SearchViewContract {
  void updateSuggestions(List<CampusLocation> suggestions);
  void onLocationSelected(CampusLocation location);
}

class SearchPresenter {
  final SearchViewContract _view;
  final List<CampusLocation> _allLocations;
  final List<CampusLocation> _searchHistory = [];

  SearchPresenter(this._view, {List<CampusLocation>? mockLocations})
      : _allLocations = mockLocations ?? AppConfig.prePopulatedLocations;

  List<CampusLocation> get searchHistory => _searchHistory;

  // Filters locations by search query (checks name, category, and description)
  void search(String query) {
    if (query.trim().isEmpty) {
      // Show search history or default recommendations if search query is empty
      _view.updateSuggestions(_searchHistory.isNotEmpty
          ? _searchHistory
          : _allLocations.take(5).toList());
      return;
    }

    final String cleanQuery = query.toLowerCase().trim();

    final List<CampusLocation> matches = _allLocations.where((loc) {
      final bool matchesName = loc.name.toLowerCase().contains(cleanQuery);
      final bool matchesCategory =
          loc.category.toLowerCase().contains(cleanQuery);
      final bool matchesDesc =
          loc.description.toLowerCase().contains(cleanQuery);
      return matchesName || matchesCategory || matchesDesc;
    }).toList();

    _view.updateSuggestions(matches);
  }

  // Handle location selection
  void selectLocation(CampusLocation location) {
    // Add to history if not already present
    if (!_searchHistory.any((loc) => loc.id == location.id)) {
      _searchHistory.insert(0, location);
      if (_searchHistory.length > 5) {
        _searchHistory.removeLast(); // Keep history size small
      }
    }
    _view.onLocationSelected(location);
  }

  void clearHistory() {
    _searchHistory.clear();
    search('');
  }
}
