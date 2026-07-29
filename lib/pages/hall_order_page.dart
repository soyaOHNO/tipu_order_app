import 'package:flutter/material.dart';
import '../models/hall_item.dart';
import '../data/hall_item_data.dart';
import 'hall_confirm_page.dart';

class HallOrderHomePage extends StatelessWidget {
  const HallOrderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ホール発注'),
          actions: [
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
        body: const TabBarView(
          children: [
            InventoryInputTab(),
            OrderManagementTab(),
            ReplenishmentTab(),
          ],
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
        final itemsInCategory = mockDrinkItems.where((e) => e.category == category).toList();

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
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: isStockOnly
                            ? [
                                // 冷蔵庫③等の重複ストックアイテムは「ストック」のみを表示
                                _buildCounter('ストック (目標:${item.targetStock})', item.stock, (val) => setState(() => item.stock = val)),
                              ]
                            : [
                                // メインアイテムは開栓・未開栓を表示
                                _buildCounter('開 (目標:${item.targetOpened})', item.opened, (val) => setState(() => item.opened = val)),
                                const SizedBox(width: 8),
                                _buildCounter('未 (目標:${item.targetUnopened})', item.unopened, (val) => setState(() => item.unopened = val)),
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

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () => onChanged(value + 1),
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
    // ★ sameId != null の重複品（冷蔵庫③側）を除外したメインリスト
    final mainDrinkItems = mockDrinkItems.where((e) => e.sameId == null).toList();
    final categories = mainDrinkItems.map((e) => e.category).toSet().toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final itemsInCategory = mainDrinkItems.where((e) => e.category == category).toList();

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
              // ★ sameId連携も含めた「合算発注数」を計算
              int autoAmount = item.calculateTotalOrderAmount(mockDrinkItems);
              int finalOrderAmount = autoAmount + item.manualAdjustment;
              if (finalOrderAmount < 0) finalOrderAmount = 0;

              // ペアになっている冷蔵庫③等のストック数を探す
              HallItem? pairedItem;
              try {
                pairedItem = mockDrinkItems.firstWhere((p) => p.sameId == item.id);
              } catch (_) {
                pairedItem = null;
              }

              return Column(
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
                              const SizedBox(height: 4),
                              // ★ 内訳と全体の状況を表示
                              Text(
                                '【開】${item.opened}/${item.targetOpened} 【未】${item.unopened}/${item.targetUnopened}'
                                '${pairedItem != null ? " 【庫③】${pairedItem.stock}/${pairedItem.targetStock}" : ""}',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.blueGrey),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: finalOrderAmount > 0 ? () {
                                  setState(() {
                                    item.manualAdjustment--;
                                  });
                                } : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '$finalOrderAmount',
                                  style: TextStyle(
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold,
                                    color: finalOrderAmount > 0 ? Colors.blueAccent : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    item.manualAdjustment++;
                                  });
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
                  },
                )),
          ],
        );
      },
    );
  }
}