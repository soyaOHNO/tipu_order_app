import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_recipe.dart';

List<CourseRecipe> courseRecipes = [];

Future<void> loadCourseRecipes() async {
  final snapshot = await FirebaseFirestore.instance.collection('master_courses').get();

  if (snapshot.docs.isEmpty) {
    // Firestoreが空の初回起動時は、初期データをセットしてFirestoreへ一括保存
    courseRecipes = [
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
    // Firestoreから取得し、ID順に並び替える（順不同対策）
    courseRecipes = snapshot.docs.map((doc) => CourseRecipe.fromJson(doc.data())).toList();
    courseRecipes.sort((a, b) => a.id.compareTo(b.id));
  }
}

Future<void> saveCourseRecipesToLocal() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch(); // ★高速一括保存（WriteBatch）を使用
  final collection = db.collection('master_courses');

  for (final course in courseRecipes) {
    // ドキュメントIDをコースのIDにして保存
    batch.set(collection.doc(course.id.toString()), course.toJson());
  }
  await batch.commit();
}