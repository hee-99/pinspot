import 'dart:convert';

// 로그인한 사용자 정보를 표현하는 모델 — provider(카카오/네이버/구글/애플/이메일/게스트) 포함
class UserModel {
  final String id;
  final String name;
  final String? email;
  final String provider;
  final String? photoUrl;
  final String? localPhotoPath;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.provider,
    this.photoUrl,
    this.localPhotoPath,
  });

  String get displayName => name.isNotEmpty ? name : '핀스팟 유저';

  // 로컬 저장(SharedPreferences)을 위해 JSON 맵으로 직렬화
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'provider': provider,
    'photoUrl': photoUrl,
    'localPhotoPath': localPhotoPath,
  };

  // JSON 맵을 UserModel로 역직렬화
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    email: j['email'] as String?,
    provider: j['provider'] as String,
    photoUrl: j['photoUrl'] as String?,
    localPhotoPath: j['localPhotoPath'] as String?,
  );

  // 파싱 실패 시 예외 대신 null을 반환하는 안전한 파싱 헬퍼
  static UserModel? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      return UserModel.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
