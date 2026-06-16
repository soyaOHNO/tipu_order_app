class CourseRecipe {
  final String courseName;
  // ItemのIDをキーにして、1人あたりの必要量を設定する
  final Map<int, double> requiredItemsPerPerson;

  CourseRecipe({
    required this.courseName,
    required this.requiredItemsPerPerson,
  });
}