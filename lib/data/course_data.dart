import '../models/course_recipe.dart';

final List<CourseRecipe> courseRecipes = [
  CourseRecipe(
    courseName: '赤身天国コース',
    requiredItemsPerPerson: {
      15: 1/8, // エリンギ
      20: 1/10, // 赤パプリカ
      22: 1/10, // 甘とうがらし
      23: 1/10, // 玉ねぎ
      24: 1/12, // 水煮コーン
      41: 1/2,  // トマト
    },
  ),
  CourseRecipe(
    courseName: 'ミランコース',
    requiredItemsPerPerson: {
      1: 1/8,  // 1: ステーキしいたけ
      14: 1.0, // 14: サンチュ
    },
  ),
];