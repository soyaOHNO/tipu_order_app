import 'item.dart';

class OrderItem {
  final Item item;
  double quantity;
  bool inStock; // ★前回追加した在庫チェック用フラグ

  OrderItem({
    required this.item,
    this.quantity = 0,
    this.inStock = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': item.id,
      'quantity': quantity,
      'inStock': inStock,
    };
  }
}

// ----------------------------------------------------------------------
// ★ 数値の表示ルールをここに一元化！
// ----------------------------------------------------------------------
extension QuantityFormat on double {
  String toDisplayString() {
    int integerPart = toInt();
    double decimalPart = this - integerPart;

    // 1.0 や 2.0 の場合は「1」「2」と整数にする
    if (decimalPart == 0) {
      return integerPart.toString(); 
    }

    // 0.5, 1.5 などの場合の表示ルール（現場に合うものを1つ選んでください）
    
    // 【案A：すべて小数に完全統一する（★誤発注ゼロで一番おすすめ）】
    // 0.5, 1.5, 2.5... と表示されます。
    return toStringAsFixed(1); 

    // 【案B：「と」を入れて読み間違いを防ぐ分数】
    // 0.5は「1/2」、1.5は「1と1/2」と表示されます。
    // if (decimalPart == 0.5) {
    //   return integerPart == 0 ? '1/2' : '$integerPartと1/2';
    // }
    // return toStringAsFixed(1);

    // 【案C：特殊文字（組み文字）の分数を使う】
    // 0.5は「½」、1.5は「1½」と表示されます。
    /*
    if (decimalPart == 0.5) {
      return integerPart == 0 ? '½' : '$integerPart ½';
    }
    return toStringAsFixed(1);
    */
  }
}