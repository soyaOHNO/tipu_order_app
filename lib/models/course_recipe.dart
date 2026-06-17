class CourseRecipe {
  final int id; // ★追加：一意のID
  String courseName;
  String toretaKeyword;
  List<int> dishIds; // ★超重要：名前(String)ではなく、料理のID(int)で紐付ける！
  bool alive; // ★追加：論理削除フラグ

  CourseRecipe({
    required this.id,
    required this.courseName,
    required this.toretaKeyword,
    required this.dishIds,
    this.alive = true,
  });

  factory CourseRecipe.fromJson(Map<String, dynamic> json) {
    return CourseRecipe(
      id: json['id'] ?? 0, // ★追加
      courseName: json['courseName'] ?? '',
      toretaKeyword: json['toretaKeyword'] ?? '',
      dishIds: List<int>.from(json['dishIds'] ?? []), // ★変更
      alive: json['alive'] ?? true, // ★追加
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // ★追加
      'courseName': courseName,
      'toretaKeyword': toretaKeyword,
      'dishIds': dishIds, // ★変更
      'alive': alive, // ★追加
    };
  }
}