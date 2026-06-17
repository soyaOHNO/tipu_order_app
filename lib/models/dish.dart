class DishItemRequirement {
  double amountPerPerson;
  double yieldPerUnit;
  bool isTableFixed;

  DishItemRequirement({
    required this.amountPerPerson,
    required this.yieldPerUnit,
    this.isTableFixed = false,
  });

  factory DishItemRequirement.fromJson(Map<String, dynamic> json) {
    return DishItemRequirement(
      amountPerPerson: (json['amountPerPerson'] ?? 0.0).toDouble(),
      yieldPerUnit: (json['yieldPerUnit'] ?? 1.0).toDouble(),
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
  final int id; // ★追加：名前が変わっても追跡できる一意のID
  String name;
  String calcType;
  String memo;
  Map<int, DishItemRequirement> requiredItems;
  bool alive; // ★追加：論理削除フラグ（過去のデータを消さずに隠す）

  Dish({
    required this.id,
    required this.name,
    required this.calcType,
    required this.memo,
    required this.requiredItems,
    this.alive = true, // デフォルトは有効
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
      id: json['id'] ?? 0, // ★追加
      name: json['name'] ?? '',
      calcType: json['calcType'] ?? 'proportion',
      memo: json['memo'] ?? '',
      requiredItems: itemsMap,
      alive: json['alive'] ?? true, // ★追加
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> itemsJson = {};
    requiredItems.forEach((key, value) {
      itemsJson[key.toString()] = value.toJson();
    });
    return {
      'id': id, // ★追加
      'name': name,
      'calcType': calcType,
      'memo': memo,
      'requiredItems': itemsJson,
      'alive': alive, // ★追加
    };
  }
}