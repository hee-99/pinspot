import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String? email;
  final String provider;
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.provider,
    this.photoUrl,
  });

  String get displayName => name.isNotEmpty ? name : '핀스팟 유저';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'provider': provider,
    'photoUrl': photoUrl,
  };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    email: j['email'] as String?,
    provider: j['provider'] as String,
    photoUrl: j['photoUrl'] as String?,
  );

  static UserModel? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      return UserModel.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
