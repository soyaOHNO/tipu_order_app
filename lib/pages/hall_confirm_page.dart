import 'package:flutter/material.dart';
import '../models/hall_item.dart';
import '../data/hall_item_data.dart';

class HallConfirmPage extends StatelessWidget {
  const HallConfirmPage({super.key});

@override
  Widget build(BuildContext context) {
    // ★変更：発注数1以上、またはメモが書かれているアイテムを抽出
    final activeDrinks = mockDrinkItems.where((item) {
      final finalAmount = item.calculateTotalOrderAmount(mockDrinkItems) + item.manualAdjustment;
      return finalAmount > 0 || item.userMemo.isNotEmpty;
    }).toList();

    final activeSupplies = mockSupplyItems.where((item) => item.isChecked).toList();

    final allActiveItems = [...activeDrinks, ...activeSupplies];

    // 2. 3つのグループに振り分け
    final kitchenItems = allActiveItems
        .where((item) => item.name.contains('キッチン'))
        .toList();

    final barItems = allActiveItems
        .where((item) => item.category.contains('バー') && !kitchenItems.contains(item))
        .toList();

    final regularOrderItems = allActiveItems
        .where((item) => !kitchenItems.contains(item) && !barItems.contains(item))
        .toList();

    Widget buildSection(String title, List<HallItem> items) {
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ...items.map((item) {
            String displayText = '';
            if (activeSupplies.contains(item)) {
              displayText = '${item.name} × 1'; // 補充はチェックマークなので×1扱い
            } else {
              int amount = item.calculateTotalOrderAmount(mockDrinkItems) + item.manualAdjustment;
              if (amount > 0) {
                displayText = '${item.name} × $amount';
              } else {
                displayText = item.name; // 個数が0でもメモのために表示する場合
              }
            }

            if (item.userMemo.isNotEmpty) {
              displayText += ' (${item.userMemo})';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 18),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('発注確認'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: allActiveItems.isEmpty
          ? const Center(
              child: Text(
                '発注・報告が必要なアイテムはありません',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView(
              children: [
                buildSection('発注', regularOrderItems),
                buildSection('バーに報告', barItems),
                buildSection('キッチンに報告', kitchenItems),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}