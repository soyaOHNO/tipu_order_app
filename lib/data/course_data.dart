import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/course_recipe.dart';

List<CourseRecipe> courseRecipes = [];

Future<void> loadCourseRecipes() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/みらんちぷ発注/マスタ/course_recipes.json');

  if (!await file.exists()) {
    courseRecipes = [
      // ★ dishNames ではなく、料理の「ID(数値)」で紐付ける
      CourseRecipe(id: 1, courseName: '赤天', toretaKeyword: '赤身天国コース', dishIds: [1, 6, 3, 4]),
      CourseRecipe(id: 2, courseName: 'みらん', toretaKeyword: 'ミランコース', dishIds: [7, 1, 8, 2, 9, 10]),
      CourseRecipe(id: 3, courseName: 'スペシャル', toretaKeyword: 'スペシャルコース', dishIds: [1, 6, 8, 2, 9, 4]),
      CourseRecipe(id: 4, courseName: 'アニバ', toretaKeyword: 'アニバーサリープレミアムコース', dishIds: [5, 3, 4]),
      CourseRecipe(id: 5, courseName: 'ロイヤル(赤さし)', toretaKeyword: 'ロイヤルプレミアムコース', dishIds: [1, 6, 3, 4]),
      CourseRecipe(id: 6, courseName: '赤くら', toretaKeyword: '赤身天国くらした火山コース', dishIds: [1, 6, 8, 2, 3, 4]),
      CourseRecipe(id: 7, courseName: '赤さし', toretaKeyword: '赤身天国刺身コース', dishIds: [1, 6, 3, 4]),
    ];
    await saveCourseRecipesToLocal();
  } else {
    final jsonString = await file.readAsString();
    final List<dynamic> decodedList = jsonDecode(jsonString);
    courseRecipes = decodedList.map((json) => CourseRecipe.fromJson(json)).toList();
  }
}

Future<void> saveCourseRecipesToLocal() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/みらんちぷ発注/マスタ/course_recipes.json');
  final List<Map<String, dynamic>> jsonList = courseRecipes.map((c) => c.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonList));
}