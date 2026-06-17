class Reservation {
  final String id;
  final String customerName; // お客様名
  final DateTime time;       // 予約時間
  final int peopleCount;     // 人数
  final int tableCount;      // 実際のテーブル数
  final String memo;         // 備考（コース名やアレルギーなど）

  Reservation({
    required this.id,
    required this.customerName,
    required this.time,
    required this.peopleCount,
    required this.tableCount,
    this.memo = '',
  });
}
