import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const _key = 'user_categories';

  static const defaultCategories = [
    '등산/명산', '조각상/공공예술', '사진 명소', '폐허/어반', '계곡/자연',
  ];

  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null || saved.isEmpty) {
      await prefs.setStringList(_key, defaultCategories);
      return List.from(defaultCategories);
    }
    return saved;
  }

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

  static Future<void> removeCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? List.from(defaultCategories);
    list.remove(name);
    await prefs.setStringList(_key, list);
  }
}
