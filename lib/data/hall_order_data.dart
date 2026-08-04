import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/hall_item.dart';
import 'hall_item_data.dart';

// 営業日の取得（朝6時切り替え）
String getBusinessDateString() {
  final now = DateTime.now();
  final businessDate = now.hour < 6 ? now.subtract(const Duration(days: 1)) : now;
  return "${businessDate.year}-${businessDate.month.toString().padLeft(2, '0')}-${businessDate.day.toString().padLeft(2, '0')}";
}

// リアルタイム同期用ストリーム
Stream<DocumentSnapshot> streamWorkingHallOrders() {
  return FirebaseFirestore.instance.collection('working_hall_orders').doc('current').snapshots();
}

// 個別のアイテム更新（+ボタンやチェックを押したときに発火）
Future<void> updateSingleHallItem(HallItem item) async {
  final db = FirebaseFirestore.instance;
  final today = getBusinessDateString();

  await db.collection('working_hall_orders').doc('current').set({
    'business_date': today,
    'items': {
      item.id.toString(): {
        'opened': item.opened,
        'unopened': item.unopened,
        'stock': item.stock,
        'is_checked': item.isChecked,
        'manual_adjustment': item.manualAdjustment,
        'user_memo': item.userMemo, // ★追加：メモを保存
      }
    }
  }, SetOptions(merge: true));
}

// 内部処理：履歴コレクションへの保存
Future<void> _transferToHistory(String targetDate, Map<String, dynamic> rawData) async {
  final itemsData = rawData['items'] as Map<String, dynamic>? ?? {};
  final List<Map<String, dynamic>> orderData = [];

  for (final item in hallItems) {
    final itemState = itemsData[item.id.toString()];
    if (itemState != null) {
      item.opened = itemState['opened'] ?? item.targetOpened;
      item.unopened = itemState['unopened'] ?? item.targetUnopened;
      item.stock = itemState['stock'] ?? item.targetStock;
      item.isChecked = itemState['is_checked'] ?? false;
      item.manualAdjustment = itemState['manual_adjustment'] ?? 0;
      item.userMemo = itemState['user_memo'] ?? ''; // ★追加：メモを復元
    }

    int finalAmount = item.calculateTotalOrderAmount(hallItems) + item.manualAdjustment;

    // ★変更：発注数がある、チェックがある、またはメモが書かれているものを履歴に残す
    if (finalAmount > 0 || item.isChecked || item.userMemo.isNotEmpty) {
      orderData.add({
        'id': item.id,
        'name': item.name,
        'quantity': finalAmount,
        'is_supply': item.isSupply,
        'is_checked': item.isChecked,
        'opened': item.opened,
        'unopened': item.unopened,
        'stock': item.stock,
        'user_memo': item.userMemo, // ★追加：履歴にメモを残す
      });
    }
    
    // 次の日のためにリセット
    item.opened = item.targetOpened;
    item.unopened = item.targetUnopened;
    item.stock = item.targetStock;
    item.isChecked = false;
    item.manualAdjustment = 0;
    item.userMemo = ''; // ★追加：メモを空にする
  }

  if (orderData.isEmpty) return;

  try {
    await FirebaseFirestore.instance
        .collection('hall_order_history')
        .doc(targetDate)
        .set({
          'date': targetDate,
          'timestamp': FieldValue.serverTimestamp(),
          'total_items': orderData.length,
          'orders': orderData,
        });
    debugPrint('Firebaseにホール発注履歴を保存しました: $targetDate');
  } catch (e) {
    debugPrint('Firebaseへのホール履歴保存に失敗しました: $e');
  }
}

// 履歴への転送とリセット（アプリ起動時などに呼び出して、朝6時を跨いだかチェック）
Future<void> checkAndTransferHallHistory() async {
  final db = FirebaseFirestore.instance;
  final doc = await db.collection('working_hall_orders').doc('current').get();
  final today = getBusinessDateString();

  if (doc.exists) {
    final data = doc.data()!;
    final savedDate = data['business_date'] as String?;

    // 日付が変わっていたら履歴へ移行し、現在のデータをリセット
    if (savedDate != null && savedDate != today) {
      await _transferToHistory(savedDate, data);
      await db.collection('working_hall_orders').doc('current').set({
        'business_date': today,
        'items': {}
      });
    }
  } else {
    // 存在しない場合は今日の日付で初期化
    await db.collection('working_hall_orders').doc('current').set({
      'business_date': today,
      'items': {}
    });
  }
}
