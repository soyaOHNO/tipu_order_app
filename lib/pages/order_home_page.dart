import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../data/item_data.dart';
import '../models/order_item.dart';
import 'board_page.dart';
import 'chief_page.dart';
import 'previous_order_page.dart';
import '../data/reservation_data.dart';
import '../data/course_data.dart';

class OrderHomePage extends StatefulWidget {
  const OrderHomePage({super.key});

  @override
  State<OrderHomePage> createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage> with WidgetsBindingObserver {
  late List<OrderItem> orders;
  
  // ★追加：アイテムIDごとの「予約による追加必要量」を保持するマップ
  Map<int, double> reservedItemCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  
    orders = items
        .where((item) => item.alive)
        .map((item) => OrderItem(item: item))
        .toList();
  
    initializeApp();
  }

  Future<void> initializeApp() async {
    await loadOrders();
    await checkBusinessDay();
    await _calculateReservedItems(); // ★追加：予約食材の計算を実行
  }

  // ★追加：今日の予約から必要な食材を計算する関数
  Future<void> _calculateReservedItems() async {
    final todayReservations = await fetchTodayReservations();
    final Map<int, double> counts = {};

    for (final res in todayReservations) {
      if (res.memo.isNotEmpty) {
        // メモ欄（コース名）と一致するレシピを探す
        final recipeIndex = courseRecipes.indexWhere((c) => c.courseName == res.memo);
        
        if (recipeIndex != -1) {
          final recipe = courseRecipes[recipeIndex];
          // 1人あたりの必要量 × 予約人数 を足し合わせる
          recipe.requiredItemsPerPerson.forEach((itemId, amountPerPerson) {
            final totalAmount = amountPerPerson * res.peopleCount;
            counts[itemId] = (counts[itemId] ?? 0.0) + totalAmount;
          });
        }
      }
    }

    setState(() {
      reservedItemCounts = counts;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkBusinessDay();
    }
  }

  Future<void> checkBusinessDay() async {
    final lastDate = await getLastBusinessDate();
    final businessDate = getBusinessDate();
    final currentDate =
        '${businessDate.year}-'
        '${businessDate.month.toString().padLeft(2, '0')}-'
        '${businessDate.day.toString().padLeft(2, '0')}';

    print('前回: $lastDate');
    print('今回: $currentDate');

    if (lastDate == null) {
      await saveLastBusinessDate();
      return;
    }

    if (lastDate != currentDate) {
      print('業務日が変わりました');
      await saveOrderLogAsCsv(lastDate);
      await savePreviousOrder();
      await clearOrders();
      await saveLastBusinessDate();
    }
  }

  DateTime getBusinessDate() {
    final now = DateTime.now();
    if (now.hour < 6) {
      return now.subtract(const Duration(days: 1));
    }
    return now;
  }

  Future<String?> getLastBusinessDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_business_date');
  }

  Future<void> saveLastBusinessDate() async {
    final prefs = await SharedPreferences.getInstance();
    final businessDate = getBusinessDate();
    final dateString =
        '${businessDate.year}-'
        '${businessDate.month.toString().padLeft(2, '0')}-'
        '${businessDate.day.toString().padLeft(2, '0')}';
    await prefs.setString('last_business_date', dateString);
  }

  Future<void> saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    for (final order in orders) {
      await prefs.setDouble('item_${order.item.id}', order.quantity);
    }
  }

  Future<void> savePreviousOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderedItems = orders
        .where((o) => o.quantity > 0)
        .map((o) => o.toJson())
        .toList();
    await prefs.setString('previous_order', jsonEncode(orderedItems));
    await prefs.setString('previous_order_date', DateTime.now().toIso8601String());
  }

  Future<void> saveOrderLogAsCsv(String targetDate) async {
    final orderedItems = orders.where((o) => o.quantity > 0).toList();
    if (orderedItems.isEmpty) return; 

    final buffer = StringBuffer();
    buffer.writeln('id,quantity');

    for (final order in orderedItems) {
      final quantityText = order.quantity == 0.5
          ? '1/2'
          : order.quantity.toStringAsFixed(
              order.quantity == order.quantity.toInt() ? 0 : 1,
            );
      buffer.writeln('${order.item.id},$quantityText');
    }

    final directory = await getApplicationDocumentsDirectory();
    final parts = targetDate.split('-');
    if (parts.length != 3) return;
    final year = parts[0];
    final month = parts[1];

    final targetDir = Directory('${directory.path}/みらんちぷ発注/$year/$month');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    final file = File('${targetDir.path}/$targetDate.csv');
    await file.writeAsString(buffer.toString());
    print('CSVログを保存しました: ${file.path}');
  }

  Future<void> clearOrders() async {
    for (final order in orders) {
      order.quantity = 0;
    }
    await saveOrders();
    setState(() {});
  }

  Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    for (final order in orders) {
      order.quantity = prefs.getDouble('item_${order.item.id}') ?? 0.0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = items.map((item) => item.category).toSet().toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('発注入力'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PreviousOrderPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BoardPage(orders: orders)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChiefPage(orders: orders)),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final List<double> quantities = [
            0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 
            9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 20.0, 30.0
          ];
          final categoryItems = orders.where((order) => order.item.category == category).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade300,
                child: Text(
                  category,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...categoryItems.map(
                (order) => Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: ListTile(
                    dense: true,
                    title: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(text: order.item.name),
                          TextSpan(
                            text: '  最低:${order.item.minimum}',
                            style: const TextStyle(color: Color.fromARGB(255, 91, 90, 90), fontSize: 13),
                          ),
                          // ★追加：もしこのアイテムが予約で必要なら、赤字で追加量を表示！
                          if (reservedItemCounts.containsKey(order.item.id))
                            TextSpan(
                              // 例: 「 +予約分: 1.0」と表示
                              text: '  +予約分: ${reservedItemCounts[order.item.id]!.toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    trailing: Builder(
                      builder: (context) {
                        List<double> displayQuantities = List.from(quantities);
                        if (!displayQuantities.contains(order.quantity)) {
                          displayQuantities.add(order.quantity);
                          displayQuantities.sort();
                        }

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.blueGrey,
                              onPressed: () {
                                if (order.quantity > 0) {
                                  setState(() {
                                    order.quantity = (order.quantity - 1.0).clamp(0.0, double.infinity);
                                  });
                                  saveOrders();
                                }
                              },
                            ),
                            DropdownButton<double>(
                              isDense: true,
                              value: order.quantity,
                              items: displayQuantities.map(
                                (quantity) => DropdownMenuItem<double>(
                                  value: quantity,
                                  child: Text(
                                    quantity == 0.5
                                        ? '1/2'
                                        : quantity.toStringAsFixed(
                                            quantity == quantity.toInt() ? 0 : 1,
                                          ),
                                  ),
                                ),
                              ).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    order.quantity = value;
                                  });
                                  saveOrders();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () {
                                setState(() {
                                  order.quantity += 1.0;
                                });
                                saveOrders();
                              },
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}