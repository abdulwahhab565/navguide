import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navguide/config/app_config.dart';
import 'package:navguide/services/navigation_service.dart';

void main() {
  test('uses the campus graph for on-campus navigation', () async {
    final service = NavigationService();
    final origin = const LatLng(7.34930, -2.33980);
    final destination = const LatLng(7.35121, -2.34168);

    final route = await service.getRoute(origin: origin, destination: destination);

    expect(route.polylinePoints, isNotEmpty);
    expect(
      route.polylinePoints.any((point) => _matchesNode(point, 'n1')),
      isTrue,
      reason: 'Route should include the nearest campus node for the start point.',
    );
    expect(
      route.polylinePoints.any((point) => _matchesNode(point, 'n5')),
      isTrue,
      reason: 'Route should include the campus graph node for the destination.',
    );
  });
}

bool _matchesNode(LatLng point, String nodeId) {
  final node = AppConfig.getNodeById(nodeId);
  if (node == null) return false;

  final latDelta = (point.latitude - node.position.latitude).abs();
  final lngDelta = (point.longitude - node.position.longitude).abs();
  return latDelta < 1e-8 && lngDelta < 1e-8;
}
