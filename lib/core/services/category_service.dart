import 'package:shared_preferences/shared_preferences.dart';

// 핀 카테고리 목록을 관리하는 서비스 (기본 카테고리 + 사용자 추가/삭제)
class CategoryService {
  static const _key = 'user_categories';

  static const defaultCategories = [
    '등산/명산', '계곡/자연', '캠핑장', '맛집', '관광명소',
    '사진 명소', '폐허/어반', '조각상/공공예술', '⚠️ 위험 지역',
  ];

  // 저장된 카테고리 목록을 반환, 없으면 기본 카테고리로 초기화
  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null || saved.isEmpty) {
      await prefs.setStringList(_key, defaultCategories);
      return List.from(defaultCategories);
    }
    return saved;
  }

  // 새 카테고리를 추가 (중복이면 무시)
  static Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? List.from(defaultCategories);
    if (!list.contains(trimmed)) {
      list.add(trimmed);
      await prefs.setStringList(_key, list);
    }
  }

  // 카테고리를 목록에서 제거
  static Future<void> removeCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? List.from(defaultCategories);
    list.remove(name);
    await prefs.setStringList(_key, list);
  }
}
