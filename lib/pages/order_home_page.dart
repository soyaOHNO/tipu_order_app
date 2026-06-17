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
import '../data/dish_data.dart';

class OrderHomePage extends StatefulWidget {
  const OrderHomePage({super.key});

  @override
  State<OrderHomePage> createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage> with WidgetsBindingObserver {
  late List<OrderItem> orders;
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
    await _calculateReservedItems();
  }

  // ★アップデート：名前ベースではなくIDベースの連携で動く自動計算
  Future<void> _calculateReservedItems() async {
    final todayReservations = await fetchTodayReservations();
    final Map<int, double> rawCounts = {};

    for (final res in todayReservations) {
      if (res.memo.isEmpty) continue;

      int courseIdx = -1;
      for (int i = 0; i < courseRecipes.length; i++) {
        // コース自体が論理削除されておらず、かつToretaのキーワードが含まれているか
        if (courseRecipes[i].alive && res.memo.contains(courseRecipes[i].toretaKeyword)) {
          courseIdx = i;
          break; 
        }
      }
      
      if (courseIdx == -1) continue; 
      final course = courseRecipes[courseIdx];

      int tCount = res.tableCount > 0 ? res.tableCount : 1; 
      int basePeople = res.peopleCount ~/ tCount;
      int remainder = res.peopleCount % tCount;

      List<int> tables = List.generate(tCount, (index) => basePeople);
      for (int i = 0; i < remainder; i++) {
        tables[i] += 1;
      }

      // ★変更：course.dishNames ではなく course.dishIds でループする
      for (final dishId in course.dishIds) {
        // IDで検索し、かつ論理削除されていない(alive: true)料理だけを計算に含める
        final dishIdx = dishes.indexWhere((d) => d.id == dishId && d.alive);
        if (dishIdx == -1) continue;
        final dish = dishes[dishIdx];

        for (final p in tables) {
          dish.requiredItems.forEach((itemId, req) {
            // もし食材自体が論理削除されていたらスキップする安全策
            final isItemAlive = items.any((i) => i.id == itemId && i.alive);
            if (!isItemAlive) return;

            double finalAmountForThisTable = 0.0;

            switch (dish.calcType) {
              case 'proportion':
                if (req.isTableFixed) {
                  finalAmountForThisTable = req.amountPerPerson / req.yieldPerUnit;
                } else {
                  double ratio = 1.0 + (p - 3) * 0.2;
                  if (ratio < 0) ratio = 0;
                  finalAmountForThisTable = (req.amountPerPerson * ratio) / req.yieldPerUnit;
                }
                break;

              case 'per_person':
                int pieces = p;
                if (dish.name == 'サンチュ' && p == 2) {
                  pieces = 4;
                }
                finalAmountForThisTable = (pieces * req.amountPerPerson) / req.yieldPerUnit;
                break;

              case 'step':
                double stepCount = 1.0;
                if (dish.name == '盛岡冷麺') {
                  if (p <= 2) stepCount = 0.5;
                  else if (p <= 4) stepCount = 1.0;
                  else if (p == 5) stepCount = 1.5;
                  else if (p <= 7) stepCount = 2.0;
                } else if (dish.name == 'クッパ') {
                  stepCount = (p >= 2 && p <= 4) ? 1.0 : 2.0;
                } else {
                  stepCount = p.toDouble();
                }
                finalAmountForThisTable = (stepCount * req.amountPerPerson) / req.yieldPerUnit;
                break;

              case 'per_table':
                finalAmountForThisTable = req.amountPerPerson / req.yieldPerUnit;
                break;
            }

            rawCounts[itemId] = (rawCounts[itemId] ?? 0.0) + finalAmountForThisTable;
          });
        }
      }
    }

    final Map<int, double> roundedCounts = {};
    rawCounts.forEach((itemId, totalAmount) {
      roundedCounts[itemId] = totalAmount.ceilToDouble();
    });

    setState(() {
      reservedItemCounts = roundedCounts;
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

    if (lastDate != currentDate && lastDate != null) {
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
    final quantities = [
      0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 
      9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 20.0, 30.0
    ];

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
        itemBuilder: (context, catIndex) {
          final category = categories[catIndex];
          final categoryItems = orders.where((order) => order.item.category == category).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  category,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...categoryItems.map((order) {
                final reserveAdd = reservedItemCounts[order.item.id];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Text(
                            order.item.name,
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black, 
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: '(最低数: '),
                                TextSpan(text: order.item.minimum),
                                
                                if (reserveAdd != null) ...[
                                  const TextSpan(text: '  '),
                                  TextSpan(
                                    text: '+予約分: ${reserveAdd == reserveAdd.toInt() ? reserveAdd.toInt() : reserveAdd}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const TextSpan(text: ')'),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          DropdownButton<double>(
                            value: order.quantity,
                            items: quantities.map((q) {
                              return DropdownMenuItem<double>(
                                value: q,
                                child: Text(q == 0.5 ? '1/2' : q.toStringAsFixed(q == q.toInt() ? 0 : 1)),
                              );
                            }).toList(),
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
                      ),
                    ),
                    const Divider(
                      height: 1, 
                      thickness: 0.5, 
                      indent: 16, 
                      endIndent: 16, 
                      color: Colors.black12,
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}