class Reservation {
  final String startTime;
  final String endTime;
  final String tableId;
  final int people;
  final String? course;
  final String? note;

  Reservation({
    required this.startTime,
    required this.endTime,
    required this.tableId,
    required this.people,
    this.course,
    this.note,
  });

  // APIから受け取ったJSONデータをDartのオブジェクトに変換
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      tableId: json['table_id'] as String? ?? '',
      people: json['people'] as int? ?? 0,
      course: json['course'] as String?, // 席のみ・不明の場合はnullが入る
      note: json['note'] as String?,
    );
  }
}