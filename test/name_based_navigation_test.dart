import 'package:flutter_test/flutter_test.dart';
import 'package:navguide/models/campus_location.dart';
import 'package:navguide/services/location_resolution_service.dart';

void main() {
  group('Name-based campus lookups', () {
    test('resolves UENR Cafeteria by hidden plus code', () {
      final service = LocationResolutionService();
      final location = service.resolveByName('UENR Cafeteria');

      expect(location, isNotNull);
      expect(location!.name, 'UENR Cafeteria');
      expect(location.plusCode, '8MX5+R3C');
      expect(location.latitude, isNotNaN);
      expect(location.longitude, isNotNaN);
    });

    test('searches by partial name using the campus name only', () {
      final service = LocationResolutionService();
      final results = service.searchByName('cafe');

      expect(results, isNotEmpty);
      expect(results.any((location) => location.name.toLowerCase().contains('cafeteria')), isTrue);
      expect(results.every((location) => location.name.isNotEmpty), isTrue);
    });

    test('supports campus names and aliases', () {
      final service = LocationResolutionService();
      final admin = service.resolveByName('Administration');
      final field = service.resolveByName('school field');
      final app = service.resolveByName('pavilion');

      expect(admin, isNotNull);
      expect(field, isNotNull);
      expect(app, isNotNull);
    });

    test('uses the Plus Code coordinates when resolving a location', () async {
      final service = LocationResolutionService();
      const location = CampusLocation(
        id: 'cafeteria',
        name: 'UENR Cafeteria',
        category: 'Food',
        latitude: 0,
        longitude: 0,
        description: 'UENR Cafeteria',
        plusCode: '8MX5+R3C',
        city: 'Sunyani',
        country: 'Ghana',
      );

      final expected = await service.resolvePlusCodeToLatLng(
        location.plusCode,
        city: location.city,
      );
      final resolved = await service.resolveLocation(location);

      expect(expected, isNotNull);
      expect(resolved.latitude, expected!.latitude);
      expect(resolved.longitude, expected.longitude);
    });
  });

  test('CampusLocation keeps a hidden plus code value internally', () {
    const location = CampusLocation(
      id: 'cafeteria',
      name: 'UENR Cafeteria',
      category: 'Food',
      latitude: 7.34971,
      longitude: -2.34238,
      description: 'UENR Cafeteria',
      plusCode: '8MX5+R3C',
      city: 'Sunyani',
      country: 'Ghana',
    );

    expect(location.plusCode, '8MX5+R3C');
    expect(location.name, 'UENR Cafeteria');
    expect(location.toMap()['plusCode'], '8MX5+R3C');
  });
}
