class HallItem {
  final int id; // 1000番台〜
  final int? sameId; // 重複アイテムの場合、メイン側（冷蔵庫①など）のIDを入れる
  final String name;
  final String category;
  
  final int targetOpened;
  final int targetUnopened;
  final int targetStock;

  final int? orderThreshold; 
  final int orderUnit;       
  final String memo;         
  
  final bool isSupply; // 補充・消耗品フラグ

  int opened;     
  int unopened;   
  int stock;      
  bool isChecked; 
  int manualAdjustment; 

  HallItem({
    required this.id,
    this.sameId,
    required this.name,
    required this.category,
    this.targetOpened = 0,
    this.targetUnopened = 0,
    this.targetStock = 0,
    this.orderThreshold, 
    this.orderUnit = 1, 
    this.memo = '',
    this.isSupply = false,
    this.isChecked = false,
    this.manualAdjustment = 0,
  }) : 
       opened = targetOpened,
       unopened = targetUnopened,
       stock = targetStock;

  // ★ sameId連携も含めた「本当の発注数」を計算するメソッド
  int calculateTotalOrderAmount(List<HallItem> allItems) {
    if (isSupply) return 0;
    
    // 自分自身が「重複側（冷蔵庫③など）」の場合はメイン側にまとめるため、ここでは発注数0（非表示）とする
    if (sameId != null) return 0;

    // 自分と同じ sameId を持つペアアイテム（冷蔵庫③など）を探す
    HallItem? pairedStockItem;
    try {
      pairedStockItem = allItems.firstWhere((item) => item.sameId == id);
    } catch (_) {
      pairedStockItem = null;
    }

    // メイン＋ペアの合算目標数と現在数
    int totalTarget = targetOpened + targetUnopened + targetStock;
    int totalCurrent = opened + unopened + stock;

    if (pairedStockItem != null) {
      totalTarget += pairedStockItem.targetOpened + pairedStockItem.targetUnopened + pairedStockItem.targetStock;
      totalCurrent += pairedStockItem.opened + pairedStockItem.unopened + pairedStockItem.stock;
    }

    // 発注ライン(orderThreshold)の判定
    if (orderThreshold != null && totalCurrent > orderThreshold!) {
      return 0;
    }

    int shortage = totalTarget - totalCurrent;
    if (shortage <= 0) return 0;

    // ケース単位（切り下げ）計算
    return (shortage ~/ orderUnit) * orderUnit;
  }

  factory HallItem.fromJson(Map<String, dynamic> json) {
    return HallItem(
      id: json['id'] as int,
      sameId: json['sameId'] as int?,
      name: json['name'] as String,
      category: json['category'] as String,
      targetOpened: json['targetOpened'] as int? ?? 0,
      targetUnopened: json['targetUnopened'] as int? ?? 0,
      targetStock: json['targetStock'] as int? ?? 0,
      orderThreshold: json['orderThreshold'] as int?,
      orderUnit: json['orderUnit'] as int? ?? 1,
      memo: json['memo'] as String? ?? '',
      isSupply: json['isSupply'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sameId': sameId,
      'name': name,
      'category': category,
      'targetOpened': targetOpened,
      'targetUnopened': targetUnopened,
      'targetStock': targetStock,
      'orderThreshold': orderThreshold,
      'orderUnit': orderUnit,
      'memo': memo,
      'isSupply': isSupply,
    };
  }
}