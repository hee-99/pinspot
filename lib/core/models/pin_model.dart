class PinModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final double lat;
  final double lng;
  final String? photoPath;
  final DateTime createdAt;

  const PinModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.lat,
    required this.lng,
    this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'lat': lat,
    'lng': lng,
    'photoPath': photoPath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PinModel.fromJson(Map<String, dynamic> j) => PinModel(
    id: j['id'] as String,
    title: j['title'] as String,
    category: j['category'] as String,
    description: j['description'] as String,
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    photoPath: j['photoPath'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
