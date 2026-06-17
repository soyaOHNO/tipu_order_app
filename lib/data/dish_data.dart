import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/dish.dart';

List<Dish> dishes = [];

Future<void> loadDishes() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/みらんちぷ発注/マスタ/dishes.json');

  if (!await file.exists()) {
    // 現場のリアルなデータを個別レート構造に変換して初期配置
    dishes = [
      Dish(
        name: 'チョレギサラダ',
        calcType: 'proportion',
        memo: '3名基準で大皿提供。1名増減で±20g。ねぎ・レモンは1卓固定。8名以上で均一卓分割。',
        requiredItems: {
          26: DishItemRequirement(amountPerPerson: 50.0, yieldPerUnit: 1.0), // レタス(3人分50g)
          27: DishItemRequirement(amountPerPerson: 40.0, yieldPerUnit: 1.0), // サニー
          18: DishItemRequirement(amountPerPerson: 10.0, yieldPerUnit: 1.0), // 人参
          28: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0, isTableFixed: true), // ねぎ: 1卓1つ (1個から10等分)
          12: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 20.0, isTableFixed: true), // レモン: 1卓1つ (1箱から1/20)
        },
      ),
      Dish(
        name: 'サンチュ',
        calcType: 'per_person',
        memo: '人数と同じ枚数（1パック10枚）。2名のみ4枚の特例あり。',
        requiredItems: {
          14: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0), // 1パックから10枚取れる
        },
      ),
      Dish(
        name: '本日の焼き野菜',
        calcType: 'per_person',
        memo: '5種類それぞれ人数分。個別レートで発注単位に自動換算。',
        requiredItems: {
          20: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0), // 1個から10本仕込み
          22: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0), // 1袋から10本仕込み
          23: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 16.0), // 1個から16個仕込み
          24: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 9.0),  // 1本から9個仕込み
          15: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 8.0),  // 1パックから8個仕込み
        },
      ),
      Dish(
        name: '盛岡冷麺',
        calcType: 'step',
        memo: '3名基準。2名=0.5, 3-4名=1, 5名=1.5, 6-7名=2パック。',
        requiredItems: {
          60: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 1.0), // 冷麺パック
          41: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 1.0), // トマト
          29: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 20.0), // タレ(1/20)
        },
      ),
      Dish(
        name: '肉ケーキ',
        calcType: 'per_table',
        memo: '人数関係なく1テーブルにつき1個。',
        requiredItems: {
          23: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 1.0),
        },
      ),
    ];
    await saveDishesToLocal();
  } else {
    final jsonString = await file.readAsString();
    final List<dynamic> decodedList = jsonDecode(jsonString);
    dishes = decodedList.map((json) => Dish.fromJson(json)).toList();
  }
}

Future<void> saveDishesToLocal() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/みらんちぷ発注/マスタ/dishes.json');
  final List<Map<String, dynamic>> jsonList = dishes.map((d) => d.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonList));
}