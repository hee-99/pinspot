// 사용자가 등록한 핀(장소) 정보를 표현하는 모델 — 위치/카테고리/사진/평점 등
class PinModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final double lat;
  final double lng;
  final String? photoPath;
  final DateTime createdAt;
  final Map<String, double>? ratings;

  const PinModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.lat,
    required this.lng,
    this.photoPath,
    required this.createdAt,
    this.ratings,
  });

  // 로컬 저장(SharedPreferences)을 위해 JSON 맵으로 직렬화
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'lat': lat,
    'lng': lng,
    'photoPath': photoPath,
    'createdAt': createdAt.toIso8601String(),
    if (ratings != null) 'ratings': ratings,
  };

  // JSON 맵을 PinModel로 역직렬화
  factory PinModel.fromJson(Map<String, dynamic> j) => PinModel(
    id: j['id'] as String,
    title: j['title'] as String,
    category: j['category'] as String,
    description: j['description'] as String,
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    photoPath: j['photoPath'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    ratings: j['ratings'] != null
        ? Map<String, double>.from(
            (j['ratings'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())))
        : null,
  );
}
