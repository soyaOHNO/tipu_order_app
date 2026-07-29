import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hall_item.dart';

List<HallItem> hallItems = [];
List<HallItem> mockDrinkItems = [];
List<HallItem> mockSupplyItems = [];

Future<void> loadHallItems() async {
  final snapshot = await FirebaseFirestore.instance.collection('master_hall_items').get();

  if (snapshot.docs.isEmpty) {
    hallItems = [
      // ==========================================
      // 【冷蔵庫①-上段】
      // ==========================================
      HallItem(id: 1001, name: 'ジンジャエール', category: '冷蔵庫①-上段', targetOpened: 1, targetUnopened: 12),
      HallItem(id: 1002, name: 'コーラ', category: '冷蔵庫①-上段', targetOpened: 1, targetUnopened: 10),
      HallItem(id: 1003, name: '生マッコリ(開)', category: '冷蔵庫①-上段', targetOpened: 1, orderThreshold: 2, orderUnit: 8, memo: '残り2本以下で注文。ケース単位(8本)・中2日'),
      HallItem(id: 1004, name: 'JINROマッコリ(開)', category: '冷蔵庫①-上段', targetOpened: 1),
      HallItem(id: 1005, name: '黒豆マッコリ(開)', category: '冷蔵庫①-上段', targetOpened: 1),

      // ==========================================
      // 【冷蔵庫①-下段】
      // ==========================================
      HallItem(id: 1006, name: 'アサヒスーパードライ', category: '冷蔵庫①-下段', targetUnopened: 7),
      HallItem(id: 1007, name: 'エビス', category: '冷蔵庫①-下段', targetUnopened: 6),
      HallItem(id: 1008, name: 'オールフリー', category: '冷蔵庫①-下段', targetUnopened: 8),
      HallItem(id: 1009, name: '独歩ピルスナー', category: '冷蔵庫①-下段', targetUnopened: 5),
      HallItem(id: 1010, name: 'マスカットピルス', category: '冷蔵庫①-下段', targetUnopened: 5),

      // ==========================================
      // 【冷蔵庫②-上段】
      // ==========================================
      HallItem(id: 1011, name: 'りんごスパークリング', category: '冷蔵庫②-上段', targetUnopened: 5),
      HallItem(id: 1012, name: 'レモネード', category: '冷蔵庫②-上段', targetUnopened: 8),

      // ==========================================
      // 【冷蔵庫②-下段】
      // ==========================================
      HallItem(id: 1013, name: 'ウーロン茶', category: '冷蔵庫②-下段', targetOpened: 1, targetUnopened: 2),
      HallItem(id: 1014, name: '黒ウーロン茶', category: '冷蔵庫②-下段', targetOpened: 1, targetUnopened: 2),
      HallItem(id: 1015, name: 'オレンジ', category: '冷蔵庫②-下段', targetOpened: 1, targetUnopened: 2),
      HallItem(id: 1016, name: '久保田(開)', category: '冷蔵庫②-下段', targetOpened: 1),
      HallItem(id: 1017, name: '奇跡のお酒(開)', category: '冷蔵庫②-下段', targetOpened: 1),
      HallItem(id: 1018, name: 'サンタヘレナ(開)', category: '冷蔵庫②-下段', targetOpened: 1),
      HallItem(id: 1019, name: 'ピーチシロップ', category: '冷蔵庫②-下段', targetOpened: 1),
      HallItem(id: 1020, name: 'ライムシロップ', category: '冷蔵庫②-下段', targetOpened: 1),
      HallItem(id: 1021, name: '白ぶどうシロップ', category: '冷蔵庫②-下段', targetOpened: 1),
      HallItem(id: 1022, name: '巨峰シロップ', category: '冷蔵庫②-下段', targetOpened: 1),

      // ==========================================
      // 【冷蔵庫③-1段目】(ストック・sameIdで連動)
      // ==========================================
      HallItem(id: 1023, sameId: 1001, name: 'ジンジャエール', category: '冷蔵庫③-1段目', targetStock: 14),
      HallItem(id: 1024, sameId: 1002, name: 'コーラ', category: '冷蔵庫③-1段目', targetStock: 6),
      HallItem(id: 1025, sameId: 1008, name: 'オールフリー', category: '冷蔵庫③-1段目', targetStock: 8),

      // ==========================================
      // 【冷蔵庫③-2段目】
      // ==========================================
      HallItem(id: 1026, sameId: 1013, name: 'ウーロン茶', category: '冷蔵庫③-2段目', targetStock: 2),
      HallItem(id: 1027, sameId: 1014, name: '黒ウーロン茶', category: '冷蔵庫③-2段目', targetStock: 2),
      HallItem(id: 1028, sameId: 1015, name: 'オレンジ', category: '冷蔵庫③-2段目', targetStock: 2),

      // ==========================================
      // 【冷蔵庫③-3段目】
      // ==========================================
      HallItem(id: 1029, sameId: 1006, name: 'アサヒスーパードライ', category: '冷蔵庫③-3段目', targetStock: 7),
      HallItem(id: 1030, sameId: 1003, name: '生マッコリ', category: '冷蔵庫③-3段目', targetStock: 3),
      HallItem(id: 1031, sameId: 1004, name: 'JINROマッコリ', category: '冷蔵庫③-3段目', targetStock: 2),
      HallItem(id: 1032, sameId: 1005, name: '黒豆マッコリ', category: '冷蔵庫③-3段目', targetStock: 2),
      HallItem(id: 1033, name: 'ジネステ', category: '冷蔵庫③-3段目', targetStock: 1),
      HallItem(id: 1034, name: 'アルベール', category: '冷蔵庫③-3段目', targetStock: 1),
      HallItem(id: 1035, name: 'ドゥルト', category: '冷蔵庫③-3段目', targetStock: 1),

      // ==========================================
      // 【冷蔵庫③-4段目】
      // ==========================================
      HallItem(id: 1036, sameId: 1016, name: '久保田', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1037, sameId: 1017, name: '奇跡のお酒', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1038, name: 'ボルサオ', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1039, name: 'ファウドアランチョ', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1040, sameId: 1018, name: 'サンタヘレナ', category: '冷蔵庫③-4段目', targetStock: 3),
      HallItem(id: 1041, name: 'リブランディ・チロ・ロッ', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1042, name: 'ガロ・カーニヴォ', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1043, name: 'カロン・セギュール', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1044, name: 'フレシネX', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1045, name: 'フェリスタス', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1046, name: 'カステル・ウエトロ', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1047, name: 'モエ・ブリュット', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1048, name: 'モエ・アイス', category: '冷蔵庫③-4段目', targetStock: 1),
      HallItem(id: 1049, name: 'ドンペリ', category: '冷蔵庫③-4段目', targetStock: 1),

      // ==========================================
      // 【ジョッキ冷蔵庫】
      // ==========================================
      HallItem(id: 1050, name: 'ゆずジャム', category: 'ジョッキ冷蔵庫', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1051, name: 'いちじくシロップ', category: 'ジョッキ冷蔵庫', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1052, name: 'いちごシロップ', category: 'ジョッキ冷蔵庫', targetOpened: 1),
      HallItem(id: 1053, name: '洋ナシシロップ', category: 'ジョッキ冷蔵庫', targetOpened: 1),
      HallItem(id: 1054, name: '巨峰シロップ(ジョッキ)', category: 'ジョッキ冷蔵庫', targetOpened: 1),
      HallItem(id: 1055, name: 'カルピス', category: 'ジョッキ冷蔵庫', targetOpened: 1, targetUnopened: 1),

      // ==========================================
      // 【ビール等】
      // ==========================================
      HallItem(id: 1056, name: 'ビール樽', category: 'ビール等', targetOpened: 2, targetUnopened: 2),
      HallItem(id: 1057, name: 'ガス', category: 'ビール等', targetOpened: 2, targetUnopened: 1),

      // ==========================================
      // 【バー等に報告】
      // ==========================================
      HallItem(id: 1058, name: '抹茶アイス(キッチン)', category: 'バー等に報告', targetUnopened: 1),
      HallItem(id: 1059, name: 'バニラアイス(キッチン)', category: 'バー等に報告', targetUnopened: 1),
      HallItem(id: 1060, name: '吉備団子', category: 'バー等に報告', targetUnopened: 1),
      HallItem(id: 1061, name: '大手まんじゅう', category: 'バー等に報告', targetUnopened: 1),
      HallItem(id: 1062, name: '白玉', category: 'バー等に報告', targetUnopened: 1),
      HallItem(id: 1063, name: '汎用あんこ', category: 'バー等に報告', targetUnopened: 1),
      HallItem(id: 1064, name: 'ホイップクリーム', category: 'バー等に報告', targetUnopened: 1),
      HallItem(id: 1065, name: 'ほうじ茶ラテ粉', category: 'バー等に報告', targetUnopened: 1),

      // ==========================================
      // 【棚】
      // ==========================================
      HallItem(id: 1066, name: 'レモンサワー', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1067, name: '知多ハイボール', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1068, name: '白州ハイボール', category: '棚', targetOpened: 1, targetUnopened: 2),
      HallItem(id: 1069, name: 'ジムビーム', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1070, name: 'カシスリキュール', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1071, name: 'すっきり梅酒', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1072, name: '黒霧島', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1073, name: '二階堂', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1074, name: '香春梅', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1075, name: '喜平', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1076, name: 'ハチミツしょうが', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1077, name: '中々', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1078, name: '白霧島', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1079, name: '桜島あらわざ', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1080, name: '㐂六', category: '棚', targetOpened: 1, targetUnopened: 1),
      HallItem(id: 1081, name: 'ウイスキー(5ℓ)', category: '棚', targetUnopened: 1),
      HallItem(id: 1082, name: '宝焼酎(酎ハイ用)', category: '棚', targetUnopened: 1),
      HallItem(id: 1083, name: '箸', category: '棚', targetUnopened: 1),
      HallItem(id: 1084, name: '箸袋', category: '棚', targetUnopened: 1),
      HallItem(id: 1085, name: '付けダレ', category: '棚', targetUnopened: 1),
      HallItem(id: 1086, name: 'ワイン', category: '棚', targetUnopened: 1, memo: '必要数になるまで発注しないこと'),

      // ==========================================
      // 【補充・毎日チェック】(isSupply = true)
      // ==========================================
      HallItem(id: 1087, name: 'ガム', category: '毎日チェック', isSupply: true),
      HallItem(id: 1088, name: 'アメ', category: '毎日チェック', isSupply: true),
      HallItem(id: 1089, name: 'ストロー', category: '毎日チェック', isSupply: true),
      HallItem(id: 1090, name: 'コチュジャン', category: '毎日チェック', isSupply: true),
      HallItem(id: 1091, name: 'にんにく', category: '毎日チェック', isSupply: true),
      HallItem(id: 1092, name: '付けダレ(補充)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1093, name: '塩ポン酢', category: '毎日チェック', isSupply: true),
      HallItem(id: 1094, name: 'ポンズ', category: '毎日チェック', isSupply: true),
      HallItem(id: 1095, name: '冷麺用お酢', category: '毎日チェック', isSupply: true),
      HallItem(id: 1096, name: '箸セット', category: '毎日チェック', isSupply: true),
      HallItem(id: 1097, name: '箸セット(テイクアウト)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1098, name: 'おしぼり', category: '毎日チェック', isSupply: true),
      HallItem(id: 1099, name: 'シロップ・焼酎類', category: '毎日チェック', isSupply: true),
      HallItem(id: 1100, name: 'ライズ(トイレ)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1101, name: '紙コップ(トイレ)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1102, name: '綿棒(トイレ)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1103, name: '爪楊枝(トイレ)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1104, name: '歯ブラシ(トイレ)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1105, name: 'ナプキン(トイレ)', category: '毎日チェック', isSupply: true),
      HallItem(id: 1106, name: 'ガム(トイレ)', category: '毎日チェック', isSupply: true),

      // ==========================================
      // 【補充・日曜日チェック】
      // ==========================================
      HallItem(id: 1107, name: 'ラムネ', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1108, name: '紙ナプキン', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1109, name: 'ブラックペッパー', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1110, name: '岩塩', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1111, name: '子ども用タレ', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1112, name: 'アルコール(掃除用)', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1113, name: 'アルコール(客席・裏)', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1114, name: 'マイペット(薄める)', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1115, name: 'ハンドソープ(薄める)', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1116, name: 'リセッシュ', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1117, name: '爪楊枝(補充)', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1118, name: 'コーヒーフレッシュ', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1119, name: 'コーヒーシュガー', category: '日曜日チェック', isSupply: true),
      HallItem(id: 1120, name: 'ホットウーロン', category: '日曜日チェック', isSupply: true),
    ];
    await saveHallItemsToLocal();
  } else {
    hallItems = snapshot.docs.map((doc) => HallItem.fromJson(doc.data())).toList();
    hallItems.sort((a, b) => a.id.compareTo(b.id));
  }

  mockDrinkItems = hallItems.where((item) => !item.isSupply).toList();
  mockSupplyItems = hallItems.where((item) => item.isSupply).toList();
}

Future<void> saveHallItemsToLocal() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  final collection = db.collection('master_hall_items');

  for (final item in hallItems) {
    batch.set(collection.doc(item.id.toString()), item.toJson());
  }
  await batch.commit();
}