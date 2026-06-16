import '../models/reservation.dart';

Future<List<Reservation>> fetchTodayReservations() async {
  // 実際のAPI通信の代わり（1秒待機）
  await Future.delayed(const Duration(seconds: 1));
  final today = DateTime.now();
  
  return [
    Reservation(id: 'T001', customerName: '田中 様', time: DateTime(today.year, today.month, today.day, 19, 00), peopleCount: 4, memo: ''),
    Reservation(id: 'T002', customerName: '佐藤 様', time: DateTime(today.year, today.month, today.day, 19, 00), peopleCount: 2, memo: '赤身天国コース'),
    Reservation(id: 'T003', customerName: '鈴木 様', time: DateTime(today.year, today.month, today.day, 19, 30), peopleCount: 5, memo: ''),
    Reservation(id: 'T004', customerName: '高橋 様', time: DateTime(today.year, today.month, today.day, 19, 30), peopleCount: 2, memo: ''),
    Reservation(id: 'T005', customerName: '伊藤 様', time: DateTime(today.year, today.month, today.day, 21, 00), peopleCount: 3, memo: 'ミランコース'),
  ];
}