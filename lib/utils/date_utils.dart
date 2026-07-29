// lib/utils/date_utils.dart
DateTime getBusinessDate() {
  final now = DateTime.now();
  // 朝6時前なら、前日の日付を営業日とする
  if (now.hour < 6) {
    return now.subtract(const Duration(days: 1));
  }
  return now;
}

String getBusinessDateString() {
  final date = getBusinessDate();
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}