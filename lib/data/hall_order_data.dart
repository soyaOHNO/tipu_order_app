import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart';

// ホールの現在の発注データを取得・監視する
Stream<DocumentSnapshot> streamHallOrders() {
  return FirebaseFirestore.instance
      .collection('working_hall_orders')
      .doc('current')
      .snapshots();
}

// 確定した発注を履歴に保存する
Future<void> transferHallOrdersToHistory(Map<String, dynamic> data) async {
  final historyDate = getBusinessDateString();
  await FirebaseFirestore.instance
      .collection('hall_order_history')
      .doc(historyDate)
      .set(data);
  
  // 保存後、現在のデータをリセット
  await FirebaseFirestore.instance
      .collection('working_hall_orders')
      .doc('current')
      .set({'items': {}}); 
}