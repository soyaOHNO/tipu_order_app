import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

List<Item> items = [];

String orderTypeToString(OrderType type) {
  return type.name;
}

OrderType stringToOrderType(String str) {
  return OrderType.values.firstWhere(
    (e) => e.name == str,
    orElse: () => OrderType.chief,
  );
}

Future<void> loadItemMaster() async {
  final snapshot = await FirebaseFirestore.instance.collection('master_items').get();

  items = snapshot.docs.map((doc) {
    final data = doc.data();
    
    // 古いデータ構造からの自動移行ロジック（カテゴリ）
    String kitchenCat = data['kitchen_category'] ?? '';
    String backCat = data['back_category'] ?? '';
    if (kitchenCat.isEmpty && backCat.isEmpty && data['category'] != null) {
      String oldCat = data['category'];
      if (oldCat == '裏') {
        backCat = '裏';
      } else {
        kitchenCat = oldCat;
      }
    }

    // ★追加：古いデータ構造からの自動移行ロジック（最低数）
    String kitchenMin = data['kitchen_minimum'] ?? '';
    String backMin = data['back_minimum'] ?? '';
    if (kitchenMin.isEmpty && backMin.isEmpty && data['minimum'] != null) {
      String oldMin = data['minimum'];
      // 古いデータを両方にコピーしておく
      kitchenMin = oldMin;
      backMin = oldMin;
    }

    return Item(
      id: data['id'] ?? 0,
      name: data['name'] ?? '',
      kitchen_minimum: kitchenMin, // ★変更
      back_minimum: backMin,       // ★変更
      kitchen_category: kitchenCat,
      back_category: backCat,
      supplier: data['supplier'] ?? '',
      orderType: stringToOrderType(data['orderType'] ?? 'chief'),
      alive: data['alive'] ?? true,
    );
  }).toList();
  items.sort((a, b) => a.id.compareTo(b.id)); // ID順にソートしてUIの崩れを防ぐ
}

Future<void> saveItemMasterToLocal() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  final collection = db.collection('master_items');
  
  for (final item in items) {
    batch.set(collection.doc(item.id.toString()), {
      'id': item.id,
      'name': item.name,
      'kitchen_minimum': item.kitchen_minimum, // ★変更
      'back_minimum': item.back_minimum,       // ★変更
      'kitchen_category': item.kitchen_category,
      'back_category': item.back_category,
      'supplier': item.supplier,
      'orderType': orderTypeToString(item.orderType),
      'alive': item.alive,
    });
  }
  await batch.commit();
}