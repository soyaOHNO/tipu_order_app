import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/dish.dart';

List<Dish> dishes = [];

Future<void> loadDishes() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/みらんちぷ発注/マスタ/dishes.json');

  if (!await file.exists()) {
    dishes = [
      Dish(
        id: 1, // ★IDを付与
        name: 'チョレギサラダ',
        calcType: 'proportion',
        memo: '3名基準で大皿提供。1名増減で±20g。ねぎ・レモンは1卓固定。8名以上で均一卓分割。',
        requiredItems: {
          26: DishItemRequirement(amountPerPerson: 50.0, yieldPerUnit: 1.0),
          27: DishItemRequirement(amountPerPerson: 40.0, yieldPerUnit: 1.0),
          18: DishItemRequirement(amountPerPerson: 10.0, yieldPerUnit: 1.0),
          28: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0, isTableFixed: true),
          12: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 20.0, isTableFixed: true),
        },
      ),
      Dish(
        id: 2,
        name: 'サンチュ',
        calcType: 'per_person',
        memo: '人数と同じ枚数（1パック10枚）。2名のみ4枚の特例あり。',
        requiredItems: {
          14: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0),
        },
      ),
      Dish(
        id: 3,
        name: '本日の焼き野菜',
        calcType: 'per_person',
        memo: '5種類それぞれ人数分。個別レートで発注単位に自動換算。',
        requiredItems: {
          20: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0),
          22: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 10.0),
          23: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 16.0),
          24: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 9.0),
          15: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 8.0),
        },
      ),
      Dish(
        id: 4,
        name: '盛岡冷麺',
        calcType: 'step',
        memo: '3名基準。2名=0.5, 3-4名=1, 5名=1.5, 6-7名=2パック。',
        requiredItems: {
          60: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 1.0),
          41: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 1.0),
          29: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 20.0),
        },
      ),
      Dish(
        id: 5,
        name: '肉ケーキ',
        calcType: 'per_table',
        memo: '人数関係なく1テーブルにつき1個。',
        requiredItems: {
          23: DishItemRequirement(amountPerPerson: 1.0, yieldPerUnit: 1.0),
        },
      ),
      // ★ コースに含まれている料理のID枠（必要量は一旦空にしてあります）
      Dish(id: 6, name: 'しゃき混ぜキムチ', calcType: 'proportion', memo: '', requiredItems: {}),
      Dish(id: 7, name: 'キムチ3種盛り', calcType: 'proportion', memo: '', requiredItems: {}),
      Dish(id: 8, name: 'くらした火山ロース', calcType: 'per_person', memo: '', requiredItems: {}),
      Dish(id: 9, name: '大分のステーキしいたけ', calcType: 'per_person', memo: '', requiredItems: {}),
      Dish(id: 10, name: 'クッパ', calcType: 'step', memo: '', requiredItems: {}),
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