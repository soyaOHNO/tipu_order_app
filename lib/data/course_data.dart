import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/course_recipe.dart';

// アプリ全体で使う動的なコースレシピリスト
List<CourseRecipe> courseRecipes = [];

// ① コースレシピの読み込み
Future<void> loadCourseRecipes() async {
  final directory = await getApplicationDocumentsDirectory();
  final masterDir = Directory('${directory.path}/みらんちぷ発注/マスタ');
  if (!await masterDir.exists()) {
    await masterDir.create(recursive: true);
  }

  final file = File('${masterDir.path}/course_recipes.json');

  if (!await file.exists()) {
    // ファイルがない場合はデフォルトの初期データをJSONにして保存
    courseRecipes = List.from(defaultCourseRecipes);
    await saveCourseRecipesToLocal();
    print('デフォルトのコースレシピ(JSON)を作成しました');
  } else {
    // ファイルがある場合は読み込んでパース
    final jsonString = await file.readAsString();
    final List<dynamic> decodedList = jsonDecode(jsonString);
    courseRecipes = decodedList.map((json) => CourseRecipe.fromJson(json)).toList();
    print('コースレシピをJSONから読み込みました: ${courseRecipes.length}件');
  }
}

// ② コースレシピのローカル保存
Future<void> saveCourseRecipesToLocal() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/みらんちぷ発注/マスタ/course_recipes.json');

  final List<Map<String, dynamic>> jsonList = courseRecipes.map((c) => c.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonList));
  print('コースレシピをJSONファイルに保存しました');
}

// 初期データの定義
final List<CourseRecipe> defaultCourseRecipes = [
  CourseRecipe(
    courseName: 'コース名A',
    dishNames: ['特製サラダ', 'おつまみセット'], // ★料理名を指定
  ),
  CourseRecipe(
    courseName: 'コース名B',
    dishNames: ['特製サラダ', 'たまごスープ'], // ★料理名を指定
  ),
];