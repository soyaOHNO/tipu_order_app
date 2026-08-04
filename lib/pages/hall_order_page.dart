import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hall_item.dart';
import '../data/hall_item_data.dart';
import 'hall_confirm_page.dart';
import '../data/hall_order_data.dart';
import 'hall_previous_order_page.dart';

// ==========================================
// ホールスタッフ向け：発注メイン画面 (3タブ構成)
// ==========================================
class HallOrderHomePage extends StatefulWidget {
  const HallOrderHomePage({super.key});

  @override
  State<HallOrderHomePage> createState() => _HallOrderHomePageState();
}

class _HallOrderHomePageState extends State<HallOrderHomePage> {
  late Stream<DocumentSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    // 非同期処理を待たずに、まずStreamを初期化してエラーを防ぐ
    _stream = streamWorkingHallOrders();
    _initializeAndListen();
  }

  Future<void> _initializeAndListen() async {
    // 画面を開いた時に「朝6時を跨いでいるか」をチェックして履歴化
    await checkAndTransferHallHistory();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ホール発注'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: '発注履歴',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HallPreviousOrderPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: '発注確認リスト',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HallConfirmPage(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(icon: Icon(Icons.kitchen), text: '在庫入力'),
              Tab(icon: Icon(Icons.edit_document), text: '発注数管理'),
              Tab(icon: Icon(Icons.check_box), text: '補充'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _stream,
          builder: (context, snapshot) {
            // Firebaseからデータを受信したら、ローカルの `hallItems` に反映させる
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null && data['items'] != null) {
                final itemsData = data['items'] as Map<String, dynamic>;
                for (final item in hallItems) {
                  final itemState = itemsData[item.id.toString()];
                  if (itemState != null) {
                    item.opened = itemState['opened'] ?? item.opened;
                    item.unopened = itemState['unopened'] ?? item.unopened;
                    item.stock = itemState['stock'] ?? item.stock;
                    item.isChecked = itemState['is_checked'] ?? item.isChecked;
                    item.manualAdjustment = itemState['manual_adjustment'] ?? item.manualAdjustment;
                    item.userMemo = itemState['user_memo'] ?? item.userMemo;
                  }
                }
              }
            }

            return const TabBarView(
              children: [
                InventoryInputTab(),
                OrderManagementTab(),
                ReplenishmentTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// タブ①：在庫数入力 (Inventory Input)
// ==========================================
class InventoryInputTab extends StatefulWidget {
  const InventoryInputTab({super.key});

  @override
  State<InventoryInputTab> createState() => _InventoryInputTabState();
}

class _InventoryInputTabState extends State<InventoryInputTab> {
  @override
  Widget build(BuildContext context) {
    final categories = mockDrinkItems.map((e) => e.category).toSet().toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        // ワイン（name == 'ワイン'）は在庫入力画面から除外する
        final itemsInCategory = mockDrinkItems
            .where((e) => e.category == category && e.name != 'ワイン')
            .toList();

        if (itemsInCategory.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...itemsInCategory.map((item) {
              final isStockOnly = item.sameId != null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: isStockOnly
                            ? [
                                _buildCounter('ストック (目標:${item.targetStock})', item.stock, item, context, (val) => setState(() => item.stock = val)),
                              ]
                            : [
                                _buildCounter('開 (目標:${item.targetOpened})', item.opened, item, context, (val) => setState(() => item.opened = val)),
                                const SizedBox(width: 8),
                                _buildCounter('未 (目標:${item.targetUnopened})', item.unopened, item, context, (val) => setState(() => item.unopened = val)),
                              ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCounter(String label, int value, HallItem item, BuildContext context, Function(int) onChanged) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 4つのボタンを並べるためサイズを少し小さめに調整
    final double buttonSize = screenWidth * 0.055; 
    final double valueTextSize = screenWidth * 0.045; 
    final double labelTextSize = screenWidth * 0.025;

    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: labelTextSize, color: Colors.grey)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -5 ボタン
            IconButton(
              icon: Icon(Icons.keyboard_double_arrow_left, color: Colors.redAccent, size: buttonSize),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: value > 0 ? () {
                onChanged(value >= 5 ? value - 5 : 0);
                updateSingleHallItem(item);
              } : null,
            ),
            // -1 ボタン
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: buttonSize),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: value > 0 ? () {
                onChanged(value - 1);
                updateSingleHallItem(item);
              } : null,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
              child: Text('$value', style: TextStyle(fontSize: valueTextSize, fontWeight: FontWeight.bold)),
            ),
            // +1 ボタン
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: buttonSize),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                onChanged(value + 1);
                updateSingleHallItem(item);
              },
            ),
            // +5 ボタン
            IconButton(
              icon: Icon(Icons.keyboard_double_arrow_right, color: Colors.blueAccent, size: buttonSize),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                onChanged(value + 5);
                updateSingleHallItem(item);
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// タブ②：発注数管理 (Order Management)
// ==========================================
class OrderManagementTab extends StatefulWidget {
  const OrderManagementTab({super.key});

  @override
  State<OrderManagementTab> createState() => _OrderManagementTabState();
}

class _OrderManagementTabState extends State<OrderManagementTab> {
  @override
  Widget build(BuildContext context) {
    final mainDrinkItems = mockDrinkItems.where((e) => e.sameId == null).toList();
    final categories = mainDrinkItems.map((e) => e.category).toSet().toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final itemsInCategory = mainDrinkItems.where((e) => e.category == category).toList();

        if (itemsInCategory.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                category,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900]),
              ),
            ),
            ...itemsInCategory.map((item) {
              // ワイン専用UI（メモ入力のみ）
              if (item.name == 'ワイン') {
                final bool isZeroOrder = item.userMemo.isEmpty;
                return Opacity(
                  opacity: isZeroOrder ? 0.4 : 1.0, // メモがなければ薄くする
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  if (item.memo.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('⚠️ ${item.memo}', style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () async {
                                    String? newMemo = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        String tempMemo = item.userMemo;
                                        return AlertDialog(
                                          title: const Text('ワインの発注メモ'),
                                          content: TextField(
                                            autofocus: true,
                                            decoration: const InputDecoration(hintText: '例: 赤ワイン2本、白1本'),
                                            onChanged: (val) => tempMemo = val,
                                            controller: TextEditingController(text: item.userMemo),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, tempMemo),
                                              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (newMemo != null) {
                                      setState(() => item.userMemo = newMemo);
                                      updateSingleHallItem(item);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Text(
                                      item.userMemo.isEmpty ? '✏️ メモを追加' : '✏️ ${item.userMemo}',
                                      style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
                    ],
                  ),
                );
              }

              // --- 通常のドリンクアイテム ---
              int autoAmount = item.calculateTotalOrderAmount(mockDrinkItems);
              int finalOrderAmount = autoAmount + item.manualAdjustment;
              if (finalOrderAmount < 0) finalOrderAmount = 0;

              HallItem? pairedItem;
              try {
                pairedItem = mockDrinkItems.firstWhere((p) => p.sameId == item.id);
              } catch (_) {
                pairedItem = null;
              }

              // 発注数が0の場合は薄く表示する判定
              final bool isZeroOrder = finalOrderAmount == 0;

              return Opacity(
                opacity: isZeroOrder ? 0.4 : 1.0, // 0なら半透明(0.4)にする
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                if (item.memo.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('⚠️ ${item.memo}', style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '【開】${item.opened}/${item.targetOpened} 【未】${item.unopened}/${item.targetUnopened}'
                                  '${pairedItem != null ? " 【庫③】${pairedItem.stock}/${pairedItem.targetStock}" : ""}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 7, // ボタンが多いため、右側の幅を少し広めに確保
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // -5 ボタン
                                IconButton(
                                  icon: const Icon(Icons.keyboard_double_arrow_left, color: Colors.blueGrey),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: finalOrderAmount > 0 ? () {
                                    setState(() {
                                      int decrease = finalOrderAmount >= 5 ? 5 : finalOrderAmount;
                                      item.manualAdjustment -= decrease;
                                    });
                                    updateSingleHallItem(item);
                                  } : null,
                                ),
                                // -1 ボタン
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.blueGrey),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: finalOrderAmount > 0 ? () {
                                    setState(() {
                                      item.manualAdjustment--;
                                    });
                                    updateSingleHallItem(item);
                                  } : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '$finalOrderAmount',
                                    style: TextStyle(
                                      fontSize: 22, 
                                      fontWeight: FontWeight.bold,
                                      color: finalOrderAmount > 0 ? Colors.blueAccent : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                // +1 ボタン
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      item.manualAdjustment++;
                                    });
                                    updateSingleHallItem(item);
                                  },
                                ),
                                // +5 ボタン
                                IconButton(
                                  icon: const Icon(Icons.keyboard_double_arrow_right, color: Colors.blueAccent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      item.manualAdjustment += 5;
                                    });
                                    updateSingleHallItem(item);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ==========================================
// タブ③：補充 (Replenishment)
// ==========================================
class ReplenishmentTab extends StatefulWidget {
  const ReplenishmentTab({super.key});

  @override
  State<ReplenishmentTab> createState() => _ReplenishmentTabState();
}

class _ReplenishmentTabState extends State<ReplenishmentTab> {
  @override
  Widget build(BuildContext context) {
    final categories = mockSupplyItems.map((e) => e.category).toSet().toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final itemsInCategory = mockSupplyItems.where((e) => e.category == category).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
              ),
            ),
            ...itemsInCategory.map((item) => CheckboxListTile(
                  title: Text(item.name),
                  subtitle: const Text('発注が必要な場合はチェック'),
                  value: item.isChecked,
                  activeColor: Colors.deepOrange,
                  onChanged: (bool? value) {
                    setState(() {
                      item.isChecked = value ?? false;
                    });
                    updateSingleHallItem(item);
                  },
                )),
          ],
        );
      },
    );
  }
}