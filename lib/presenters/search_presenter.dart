import '../services/places_service.dart';
import '../models/campus_location.dart';

abstract class SearchViewContract {
  void showLoading();
  void hideLoading();
  void onSearchResultsLoaded(List<CampusLocation> results);
  void onSearchError(String message);
}

class SearchPresenter {
  final PlacesService _placesService = PlacesService();
  SearchViewContract? _view;

  void attachView(SearchViewContract view) {
    _view = view;
  }

  void detachView() {
    _view = null;
  }

  Future<void> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      _view?.onSearchResultsLoaded(_placesService.getAllVerifiedLocations());
      return;
    }

    _view?.showLoading();
    try {
      final results = await _placesService.searchCampusPlaces(query);
      _view?.hideLoading();
      _view?.onSearchResultsLoaded(results);
    } catch (e) {
      _view?.hideLoading();
      _view?.onSearchError('Search failed: ${e.toString()}');
    }
  }

  void filterByCategory(String category) {
    _view?.showLoading();
    try {
      final results = _placesService.searchByCategory(category);
      _view?.hideLoading();
      _view?.onSearchResultsLoaded(results);
    } catch (e) {
      _view?.hideLoading();
      _view?.onSearchError('Filtering failed: ${e.toString()}');
    }
  }

  Future<void> getLocationDetails(String placeId) async {
    _view?.showLoading();
    try {
      final location = await _placesService.getPlaceDetails(placeId);
      _view?.hideLoading();
      if (location != null) {
        _view?.onSearchResultsLoaded([location]);
      } else {
        _view?.onSearchError('Location details not found');
      }
    } catch (e) {
      _view?.hideLoading();
      _view?.onSearchError('Failed to get location details: ${e.toString()}');
    }
  }

  List<CampusLocation> getAllVerifiedLocations() {
    return _placesService.getAllVerifiedLocations();
  }

  Map<String, int> getCategoryCounts() {
    return _placesService.getCategoryCounts();
  }

  List<String> getAllCategories() {
    return _placesService.getAllCategories();
  }

  CampusLocation? getNearestLocation(double lat, double lng) {
    return _placesService.getNearestVerifiedLocation(lat, lng);
  }

  CampusLocation? getLocationByName(String name) {
    return _placesService.getLocationByName(name);
  }
}