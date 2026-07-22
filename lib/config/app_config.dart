import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/campus_location.dart';

class AppConfig {
  static const String googleMapsApiKey = 'AIzaSyCpMjOU83HIUWrZVG46mDf4p7I3Z4nxXrE';

  static const LatLng campusCenter = LatLng(7.3495, -2.3435);

  static const double northBound = 7.3550;
  static const double southBound = 7.3440;
  static const double westBound = -2.3480;
  static const double eastBound = -2.3380;

  static bool isWithinCampus(LatLng position) {
    return position.latitude >= southBound &&
        position.latitude <= northBound &&
        position.longitude >= westBound &&
        position.longitude <= eastBound;
  }

  static final List<CampusLocation> verifiedLocations = [
    const CampusLocation(
      id: 'sh',
      name: 'SH',
      category: 'Academic',
      latitude: 7.35016,
      longitude: -2.33994,
      description: 'School of Humanities',
    ),
    const CampusLocation(
      id: 'saw_mill',
      name: 'Saw Mill',
      category: 'Services',
      latitude: 7.35081,
      longitude: -2.34048,
      description: 'Campus Saw Mill',
    ),
    const CampusLocation(
      id: 'lt',
      name: 'LT',
      category: 'Academic',
      latitude: 7.35121,
      longitude: -2.34168,
      description: 'Lecture Theatre',
    ),
    const CampusLocation(
      id: 'app_lab_1',
      name: 'App Lab 1',
      category: 'Academic',
      latitude: 7.35112,
      longitude: -2.34210,
      description: 'Application Laboratory 1',
    ),
    const CampusLocation(
      id: 'uenr_school_field',
      name: 'UENR School Field',
      category: 'Amenities',
      latitude: 7.35102,
      longitude: -2.34264,
      description: 'Main School Field',
    ),
    const CampusLocation(
      id: 'basketball_court',
      name: 'Basketball Court',
      category: 'Amenities',
      latitude: 7.35072,
      longitude: -2.34357,
      description: 'Outdoor Basketball Court',
    ),
    const CampusLocation(
      id: 'hostel_campus_road',
      name: 'Hostel Campus Road',
      category: 'Services',
      latitude: 7.35072,
      longitude: -2.34357,
      description: 'Road to Hostels',
    ),
    const CampusLocation(
      id: 'odum_block',
      name: 'Odum Block',
      category: 'Academic',
      latitude: 7.34994,
      longitude: -2.34283,
      description: 'Odum Academic Block',
    ),
    const CampusLocation(
      id: 'school_of_graduate_studies',
      name: 'School of Graduate Studies',
      category: 'Academic',
      latitude: 7.34975,
      longitude: -2.34273,
      description: 'Graduate Studies Building',
    ),
    const CampusLocation(
      id: 'university_cafeteria',
      name: 'University Cafeteria',
      category: 'Amenities',
      latitude: 7.34971,
      longitude: -2.34238,
      description: 'Main Campus Cafeteria',
    ),
    const CampusLocation(
      id: 'french_lab',
      name: 'French Lab',
      category: 'Academic',
      latitude: 7.34962,
      longitude: -2.34286,
      description: 'French Language Laboratory',
    ),
    const CampusLocation(
      id: 'old_auditorium',
      name: 'Old Auditorium',
      category: 'Academic',
      latitude: 7.34944,
      longitude: -2.34278,
      description: 'Old Auditorium Building',
    ),
    const CampusLocation(
      id: 'academic_student_affairs',
      name: 'Academic & Student Affairs Division',
      category: 'Administration',
      latitude: 7.34939,
      longitude: -2.34298,
      description: 'Academic and Student Affairs',
    ),
    const CampusLocation(
      id: 'internal_audit',
      name: 'Internal Audit',
      category: 'Administration',
      latitude: 7.34951,
      longitude: -2.34330,
      description: 'Internal Audit Office',
    ),
    const CampusLocation(
      id: 'director_of_finance',
      name: 'Director of Finance',
      category: 'Administration',
      latitude: 7.34950,
      longitude: -2.34332,
      description: 'Finance Directorate',
    ),
    const CampusLocation(
      id: 'biochemistry_lab',
      name: 'Biochemistry Lab',
      category: 'Academic',
      latitude: 7.34950,
      longitude: -2.34332,
      description: 'Biochemistry Laboratory',
    ),
    const CampusLocation(
      id: 'school_clinic',
      name: 'School Clinic',
      category: 'Services',
      latitude: 7.34921,
      longitude: -2.34315,
      description: 'Campus Health Clinic',
    ),
  ];

  static final List<GraphNode> roadNodes = [
    const GraphNode(id: 'n1', lat: 7.34930, lng: -2.33980, label: 'Main Entrance'),
    const GraphNode(id: 'n2', lat: 7.34970, lng: -2.34030, label: 'Junction A'),
    const GraphNode(id: 'n3', lat: 7.35020, lng: -2.34060, label: 'Junction B'),
    const GraphNode(id: 'n4', lat: 7.35060, lng: -2.34100, label: 'Junction C'),
    const GraphNode(id: 'n5', lat: 7.35100, lng: -2.34140, label: 'Junction D'),
    const GraphNode(id: 'n6', lat: 7.34970, lng: -2.34150, label: 'Junction E'),
    const GraphNode(id: 'n7', lat: 7.34960, lng: -2.34200, label: 'Junction F'),
    const GraphNode(id: 'n8', lat: 7.34990, lng: -2.34250, label: 'Junction G'),
    const GraphNode(id: 'n9', lat: 7.35030, lng: -2.34280, label: 'Junction H'),
    const GraphNode(id: 'n10', lat: 7.35070, lng: -2.34310, label: 'Junction I'),
    const GraphNode(id: 'n11', lat: 7.34900, lng: -2.34250, label: 'Junction J'),
    const GraphNode(id: 'n12', lat: 7.34920, lng: -2.34300, label: 'Junction K'),
    const GraphNode(id: 'n13', lat: 7.34940, lng: -2.34340, label: 'Junction L'),
    const GraphNode(id: 'n14', lat: 7.34960, lng: -2.34360, label: 'Junction M'),
    const GraphNode(id: 'n15', lat: 7.35000, lng: -2.34380, label: 'Junction N'),
    const GraphNode(id: 'n16', lat: 7.35050, lng: -2.34250, label: 'Junction O'),
    const GraphNode(id: 'n17', lat: 7.35100, lng: -2.34290, label: 'Junction P'),
    const GraphNode(id: 'n18', lat: 7.35120, lng: -2.34330, label: 'Junction Q'),
    const GraphNode(id: 'n19', lat: 7.35110, lng: -2.34370, label: 'Junction R'),
    const GraphNode(id: 'n20', lat: 7.34980, lng: -2.34180, label: 'Walkway A'),
    const GraphNode(id: 'n21', lat: 7.35010, lng: -2.34220, label: 'Walkway B'),
    const GraphNode(id: 'n22', lat: 7.35040, lng: -2.34230, label: 'Walkway C'),
    const GraphNode(id: 'n23', lat: 7.34950, lng: -2.34260, label: 'Walkway D'),
  ];

  static final List<GraphEdge> roadEdges = [
    const GraphEdge(sourceId: 'n1', targetId: 'n2', distance: 65.0),
    const GraphEdge(sourceId: 'n2', targetId: 'n3', distance: 70.0),
    const GraphEdge(sourceId: 'n3', targetId: 'n4', distance: 55.0),
    const GraphEdge(sourceId: 'n4', targetId: 'n5', distance: 60.0),
    const GraphEdge(sourceId: 'n2', targetId: 'n6', distance: 80.0),
    const GraphEdge(sourceId: 'n6', targetId: 'n7', distance: 55.0),
    const GraphEdge(sourceId: 'n7', targetId: 'n8', distance: 60.0),
    const GraphEdge(sourceId: 'n8', targetId: 'n9', distance: 50.0),
    const GraphEdge(sourceId: 'n9', targetId: 'n10', distance: 55.0),
    const GraphEdge(sourceId: 'n7', targetId: 'n11', distance: 45.0),
    const GraphEdge(sourceId: 'n11', targetId: 'n12', distance: 55.0),
    const GraphEdge(sourceId: 'n12', targetId: 'n13', distance: 50.0),
    const GraphEdge(sourceId: 'n13', targetId: 'n14', distance: 40.0),
    const GraphEdge(sourceId: 'n14', targetId: 'n15', distance: 50.0),
    const GraphEdge(sourceId: 'n8', targetId: 'n16', distance: 60.0),
    const GraphEdge(sourceId: 'n16', targetId: 'n17', distance: 65.0),
    const GraphEdge(sourceId: 'n17', targetId: 'n18', distance: 55.0),
    const GraphEdge(sourceId: 'n18', targetId: 'n19', distance: 50.0),
    const GraphEdge(sourceId: 'n6', targetId: 'n20', distance: 35.0),
    const GraphEdge(sourceId: 'n20', targetId: 'n21', distance: 40.0),
    const GraphEdge(sourceId: 'n21', targetId: 'n22', distance: 35.0),
    const GraphEdge(sourceId: 'n22', targetId: 'n9', distance: 30.0),
    const GraphEdge(sourceId: 'n7', targetId: 'n23', distance: 30.0),
    const GraphEdge(sourceId: 'n23', targetId: 'n12', distance: 35.0),
    const GraphEdge(sourceId: 'n3', targetId: 'n20', distance: 50.0),
    const GraphEdge(sourceId: 'n5', targetId: 'n22', distance: 45.0),
    const GraphEdge(sourceId: 'n10', targetId: 'n15', distance: 40.0),
    const GraphEdge(sourceId: 'n10', targetId: 'n17', distance: 45.0),
    const GraphEdge(sourceId: 'n13', targetId: 'n23', distance: 40.0),
    const GraphEdge(sourceId: 'n14', targetId: 'n19', distance: 55.0),
    const GraphEdge(sourceId: 'n4', targetId: 'n21', distance: 40.0),
    const GraphEdge(sourceId: 'n15', targetId: 'n18', distance: 50.0),
    const GraphEdge(sourceId: 'n11', targetId: 'n16', distance: 60.0),
  ];

  static const Map<String, String> locationToNearestNode = {
    'sh': 'n1',
    'saw_mill': 'n3',
    'lt': 'n5',
    'app_lab_1': 'n9',
    'uenr_school_field': 'n10',
    'basketball_court': 'n15',
    'hostel_campus_road': 'n15',
    'odum_block': 'n8',
    'school_of_graduate_studies': 'n8',
    'university_cafeteria': 'n7',
    'french_lab': 'n12',
    'old_auditorium': 'n12',
    'academic_student_affairs': 'n13',
    'internal_audit': 'n13',
    'director_of_finance': 'n14',
    'biochemistry_lab': 'n14',
    'school_clinic': 'n11',
  };

  static String? getNearestNodeId(String locationId) {
    return locationToNearestNode[locationId];
  }

  static GraphNode? getNodeById(String id) {
    try {
      return roadNodes.firstWhere((node) => node.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<GraphEdge> getEdgesForNode(String nodeId) {
    return roadEdges.where((edge) =>
    edge.sourceId == nodeId || edge.targetId == nodeId
    ).toList();
  }

  static List<String> getNeighbors(String nodeId) {
    final edges = getEdgesForNode(nodeId);
    final neighbors = <String>[];
    for (final edge in edges) {
      if (edge.sourceId == nodeId) {
        neighbors.add(edge.targetId);
      } else if (edge.targetId == nodeId) {
        neighbors.add(edge.sourceId);
      }
    }
    return neighbors;
  }

  static double? getEdgeDistance(String nodeId1, String nodeId2) {
    final edge = roadEdges.firstWhere(
          (e) =>
      (e.sourceId == nodeId1 && e.targetId == nodeId2) ||
          (e.sourceId == nodeId2 && e.targetId == nodeId1),
      orElse: () => const GraphEdge(sourceId: '', targetId: '', distance: 0),
    );
    return edge.distance > 0 ? edge.distance : null;
  }

  static List<String> getVerifiedLocationNames() {
    return verifiedLocations.map((loc) => loc.name).toList();
  }

  static CampusLocation? findLocationByName(String name) {
    try {
      return verifiedLocations.firstWhere(
            (loc) => loc.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static CampusLocation? findLocationById(String id) {
    try {
      return verifiedLocations.firstWhere(
            (loc) => loc.id.toLowerCase() == id.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

class GraphNode {
  final String id;
  final double lat;
  final double lng;
  final String label;

  const GraphNode({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
  });

  LatLng get position => LatLng(lat, lng);

  @override
  String toString() => 'GraphNode(id: $id, label: $label, pos: $lat, $lng)';
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final double distance;

  const GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.distance,
  });

  @override
  String toString() => 'GraphEdge($sourceId -> $targetId, ${distance}m)';
}