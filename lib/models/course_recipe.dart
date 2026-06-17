class CourseRecipe {
  String courseName;
  List<String> dishNames; // ★食材ではなく、料理名のリストに変更！

  CourseRecipe({
    required this.courseName,
    required this.dishNames,
  });

  factory CourseRecipe.fromJson(Map<String, dynamic> json) {
    return CourseRecipe(
      courseName: json['courseName'] ?? '',
      dishNames: List<String>.from(json['dishNames'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'dishNames': dishNames,
    };
  }
}