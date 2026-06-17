// ★新設：食材ごとの個別レートと条件を管理するクラス
class DishItemRequirement {
  double amountPerPerson; // 1人あたり（または1卓あたり）の必要量
  double yieldPerUnit;    // 食材1単位（1箱/1パック/1個）から取れる仕込み量（個別レート）
  bool isTableFixed;      // テーブルごとに固定の食材か（例：サラダのねぎ・レモンなど）

  DishItemRequirement({
    required this.amountPerPerson,
    required this.yieldPerUnit,
    this.isTableFixed = false,
  });

  factory DishItemRequirement.fromJson(Map<String, dynamic> json) {
    return DishItemRequirement(
      amountPerPerson: (json['amountPerPerson'] ?? 0.0).toDouble(),
      yieldPerUnit: (json['yieldPerUnit'] ?? 1.0).toDouble(), // 0割防止でデフォルト1.0
      isTableFixed: json['isTableFixed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amountPerPerson': amountPerPerson,
      'yieldPerUnit': yieldPerUnit,
      'isTableFixed': isTableFixed,
    };
  }
}

class Dish {
  String name;
  String calcType; // ★追加：'proportion'(比例), 'per_person'(個数), 'step'(段階), 'per_table'(卓固定)
  String memo;
  Map<int, DishItemRequirement> requiredItems; // ★変更：Stringから専用クラスへ

  Dish({
    required this.name,
    required this.calcType,
    required this.memo,
    required this.requiredItems,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    final Map<int, DishItemRequirement> itemsMap = {};
    if (json['requiredItems'] != null) {
      (json['requiredItems'] as Map<String, dynamic>).forEach((key, value) {
        final itemId = int.tryParse(key);
        if (itemId != null) {
          itemsMap[itemId] = DishItemRequirement.fromJson(value as Map<String, dynamic>);
        }
      });
    }
    return Dish(
      name: json['name'] ?? '',
      calcType: json['calcType'] ?? 'proportion',
      memo: json['memo'] ?? '',
      requiredItems: itemsMap,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> itemsJson = {};
    requiredItems.forEach((key, value) {
      itemsJson[key.toString()] = value.toJson();
    });
    return {
      'name': name,
      'calcType': calcType,
      'memo': memo,
      'requiredItems': itemsJson,
    };
  }
}