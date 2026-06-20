import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/order_item.dart';

class ChiefPage extends StatelessWidget {
  final List<OrderItem> orders;

  const ChiefPage({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final chiefOrders = orders.where(
      (o) =>
          o.quantity > 0 &&
          o.item.orderType == OrderType.chief,
    ).toList();

    final ownerOrders = orders.where(
      (o) =>
          o.quantity > 0 &&
          o.item.orderType == OrderType.owner,
    ).toList();

    // ★ 変更：仕入先名のハイフンより前をグループ名として抽出
    final chiefSupplierGroups = chiefOrders.map((o) {
      final rawSupplier = o.item.supplier.trim();
      final parts = rawSupplier.split('-');
      return parts[0].trim();
    }).toSet().toList();

    // グループ名で五十音順・アルファベット順にソート（空白は一番下）
    chiefSupplierGroups.sort((a, b) {
      if (a.isEmpty && b.isNotEmpty) return 1;
      if (a.isNotEmpty && b.isEmpty) return -1;
      return a.compareTo(b);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('発注確認'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '発注',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      
          // ★ 変更：グループ（ハイフンより前の名前）ごとに展開
          ...chiefSupplierGroups.expand((groupName) {
            // このグループに属する商品を抽出（ハイフンより前が一致するもの、または完全一致するもの）
            final supplierOrders = chiefOrders.where((o) {
              final rawSupplier = o.item.supplier.trim();
              final parts = rawSupplier.split('-');
              return parts[0].trim() == groupName;
            }).toList();

            // ★ 変更：グループ内でのソート処理
            // ハイフンの後の数字（ID）を取り出して、その数字の順番で並び替える
            supplierOrders.sort((a, b) {
              final partsA = a.item.supplier.trim().split('-');
              final partsB = b.item.supplier.trim().split('-');
              
              // ハイフンの後に文字があれば数字に変換を試みる、無ければ非常に大きな数字（一番下）にする
              int sortIdA = partsA.length > 1 ? int.tryParse(partsA[1].trim()) ?? 999999 : 999999;
              int sortIdB = partsB.length > 1 ? int.tryParse(partsB[1].trim()) ?? 999999 : 999999;
              
              int comp = sortIdA.compareTo(sortIdB);
              
              // もしハイフンの後の数字が同じだった場合（または両方数字が無かった場合）は、念のため商品の元のID順にする
              if (comp != 0) {
                return comp;
              } else {
                return a.item.id.compareTo(b.item.id);
              }
            });
            
            final displayTitle = groupName.isEmpty ? '未設定' : groupName;

            return [
              // 仕入先（グループ）の見出し
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '【 $displayTitle 】',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: groupName.isEmpty ? Colors.grey.shade700 : Colors.indigo,
                  ),
                ),
              ),
              // その仕入先の商品リスト
              ...supplierOrders.map(
                (order) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Text(
                    '${order.item.name} × ${order.quantity.toDisplayString()}', // ★変更
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ];
          }),
      
          const Divider(height: 32, thickness: 1),
      
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'とも兄さんにお願いするもの',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      
          ...ownerOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Text(
                '${order.item.name} × ${order.quantity.toDisplayString()}', // ★変更
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}