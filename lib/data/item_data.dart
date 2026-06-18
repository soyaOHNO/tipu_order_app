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

  if (snapshot.docs.isEmpty) {
    items = List.from(defaultItems);
    await saveItemMasterToLocal();
  } else {
    items = snapshot.docs.map((doc) {
      final data = doc.data();
      return Item(
        id: data['id'] ?? 0,
        name: data['name'] ?? '',
        minimum: data['minimum'] ?? '',
        category: data['category'] ?? '',
        supplier: data['supplier'] ?? '',
        orderType: stringToOrderType(data['orderType'] ?? 'chief'),
        alive: data['alive'] ?? true,
      );
    }).toList();
    items.sort((a, b) => a.id.compareTo(b.id)); // ID順にソートしてUIの崩れを防ぐ
  }
}

Future<void> saveItemMasterToLocal() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  final collection = db.collection('master_items');
  
  for (final item in items) {
    batch.set(collection.doc(item.id.toString()), {
      'id': item.id,
      'name': item.name,
      'minimum': item.minimum,
      'category': item.category,
      'supplier': item.supplier,
      'orderType': orderTypeToString(item.orderType),
      'alive': item.alive,
    });
  }
  await batch.commit();
}


// ③ 初回ファイル生成用のデフォルトデータ（これまでの固定データ）
const List<Item> defaultItems = [
  // 冷蔵庫（左上）
  Item(id: 1, name: 'ステーキしいたけ', minimum: '4パック', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 2, name: '温泉たまご', minimum: '1パック', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 3, name: '甘口ダレ', minimum: '2パック', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.owner, alive: true),
  Item(id: 4, name: 'ケジャン', minimum: '2パック', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.owner, alive: true),
  Item(id: 5, name: 'チャンジャ', minimum: '2パック', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 6, name: '白菜キムチ', minimum: 'タッパと1袋', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 7, name: 'オイキムチ', minimum: 'タッパと1袋', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 8, name: 'カクテキ', minimum: 'タッパと1袋', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 9, name: 'ぜんまい', minimum: 'タッパと1袋', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 10, name: 'とろけるチーズ', minimum: '2パック', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 11, name: 'シーザー用ドレッシング', minimum: '1本', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 79, name: 'スープ具', minimum: '10個', category: '冷蔵庫（左上）', supplier: '', orderType: OrderType.preparation, alive: true),
  Item(id: 80, name: 'しゃき混ぜ', minimum: '1箱', category: '冷蔵庫（左下）', supplier: '', orderType:OrderType.preparation, alive: true),
  Item(id: 81, name: 'べんり酢', minimum: '1本', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),

  // 冷蔵庫（左下）
  Item(id: 12, name: '白髪ねぎ', minimum: '2束', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 13, name: 'ニラ', minimum: '1束', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 14, name: 'サンチュ', minimum: '7パック', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 15, name: 'エリンギ', minimum: '3パック', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 16, name: '豆腐', minimum: '2個', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 17, name: 'カボチャ', minimum: '1/2個', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 18, name: '人参', minimum: '3本', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 19, name: 'ピーマン', minimum: '5パック', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 20, name: '赤パプリカ', minimum: '1個', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 21, name: 'リンゴ', minimum: '1個', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 22, name: '甘とうがらし', minimum: '3パック', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 23, name: '玉ねぎ', minimum: '3玉', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 24, name: '水煮コーン', minimum: '2本', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 25, name: '白菜', minimum: '1/2個', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 26, name: 'レタス', minimum: '2個', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 27, name: 'サニーレタス', minimum: '2個', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 28, name: 'レモン', minimum: '15個', category: '冷蔵庫（左下）', supplier:'', orderType: OrderType.chief, alive: true),
  Item(id: 29, name: '冷麺スープ', minimum: '裏含め3本', category: '冷蔵庫（左下）', supplier: '', orderType: OrderType.owner, alive: true),

  // 冷凍庫（右上）
  Item(id: 30, name: 'ゆずシャーベット', minimum: '2箱', category: '冷凍庫（右上）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 31, name: 'バニラアイス', minimum: '1箱', category: '冷凍庫（右上）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 32, name: '大手饅頭', minimum: '10個', category: '冷凍庫（右上）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 33, name: 'カタラーナ', minimum: '2箱', category: '冷凍庫（右上）', supplier: '', orderType: OrderType.chief, alive: true),

  // 冷蔵庫（右下）
  Item(id: 34, name: '生たまご', minimum: '30個', category: '冷蔵庫（右下）', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 35, name: 'しょうゆダレ', minimum: '1本', category: '冷蔵庫（右下）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 36, name: 'みそダレ', minimum: '1本', category: '冷蔵庫（右下）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 37, name: 'チョジャン', minimum: '1/2パック', category: '冷蔵庫（右下）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 38, name: 'サムジャン', minimum: '1/2パック', category: '冷蔵庫（右下）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 39, name: 'チョレギドレッシング', minimum: '1パック', category: '冷蔵庫（右下）', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 40, name: 'すりおろしにんにく', minimum: '1パック', category: '冷蔵庫（右下）', supplier: '', orderType: OrderType.chief, alive: true),

  // 引き出し冷蔵庫
  Item(id: 41, name: 'トマト', minimum: '10個', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 42, name: '大葉', minimum: '10枚', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 43, name: '冷麺もやし', minimum: '1缶', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.regular, alive: true),
  Item(id: 44, name: 'わかめ', minimum: '缶の1/3程度', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 45, name: '黄ニラ', minimum: '缶の1/3程度', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 46, name: 'ホワイトマッシュルーム', minimum: '2パック', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 47, name: '青ねぎ', minimum: '1袋', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.regular, alive: true),
  Item(id: 48, name: 'キャベツの千切り', minimum: '1袋', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.regular, alive: true),
  Item(id: 49, name: '高級にんにく', minimum: '1袋', category: '引き出し冷蔵庫', supplier: '', orderType: OrderType.chief, alive: true),

  // サイドテーブル下
  Item(id: 50, name: 'キミセ醤油', minimum: '1パック', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 51, name: 'はちみつ', minimum: '1本', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 52, name: 'オリーブオイル', minimum: '1缶', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 53, name: '韓国のり', minimum: '2袋', category: 'サイドテーブル下', supplier: '', orderType: OrderType.owner, alive: true),
  Item(id: 54, name: 'ビビン麺ダレ', minimum: '3袋', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 55, name: 'ホワイトペーパー', minimum: '1缶', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 56, name: 'もみのり', minimum: '1袋', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 57, name: '糸唐辛子', minimum: '1袋', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 58, name: 'クルトン', minimum: '1袋', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 59, name: 'BP(ホール)', minimum: '1袋', category: 'サイドテーブル下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 60, name: '冷麺セット', minimum: '6袋', category: 'サイドテーブル下', supplier: '', orderType: OrderType.owner, alive: true),

  // コンロ下
  Item(id: 61, name: '焼き塩', minimum: '1袋', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 62, name: 'グラニュー糖', minimum: '1袋', category: 'コンロ下', supplier: '', orderType: OrderType.owner, alive: true),
  Item(id: 63, name: 'ゴマ油', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 64, name: '白だし', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 65, name: 'めんつゆ', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 66, name: '香りの蔵', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 67, name: '穀物酢', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 68, name: '料理酒', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 69, name: '濃口しょうゆ', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.part, alive: true),
  Item(id: 70, name: '本みりん', minimum: '', category: 'コンロ下', supplier: '', orderType: OrderType.part, alive: true),

  // 裏
  Item(id: 71, name: 'コーン茶', minimum: '1袋', category: '裏', supplier: '', orderType: OrderType.chief, alive: true),

  // その他
  Item(id: 72, name: 'ウニ', minimum: '1パック', category: 'その他', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 73, name: 'アスパラ', minimum: '2束', category: 'その他', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 74, name: 'わさび', minimum: '裏1個', category: 'その他', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 75, name: 'カソナード', minimum: '1袋', category: 'その他', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 76, name: '銀カップ', minimum: '10個', category: 'その他', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 77, name: 'ボン・スター', minimum: '1個', category: 'その他', supplier: '', orderType: OrderType.chief, alive: true),
  Item(id: 78, name: 'ワンダフル', minimum: '1本', category: 'その他', supplier: '', orderType: OrderType.chief, alive: true),
];