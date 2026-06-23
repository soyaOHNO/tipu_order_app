import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/item_data.dart';
import '../models/order_item.dart';
import 'board_page.dart';
import 'chief_page.dart';
import 'previous_order_page.dart';
import '../data/reservation_data.dart';
import '../data/course_data.dart';
import '../data/dish_data.dart';
import 'memo_page.dart';

class OrderHomePage extends StatefulWidget {
  const OrderHomePage({super.key});

  @override
  State<OrderHomePage> createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage> with WidgetsBindingObserver {
  late List<OrderItem> orders;
  Map<int, double> reservedItemCounts = {};
  StreamSubscription<DocumentSnapshot>? _orderStream; 
  
  bool isKitchenView = true; // ★追加：キッチンビューか裏ビューかの判定用

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
    await checkBusinessDay();
    _listenToOrders();
    await _calculateReservedItems();
  }

  void _listenToOrders() {
    _orderStream = FirebaseFirestore.instance.collection('working_orders').doc('current').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        bool needsRebuild = false;

        for (final order in orders) {
          final itemData = data[order.item.id.toString()];
          if (itemData != null) {
            final newQ = (itemData['quantity'] as num?)?.toDouble() ?? 0.0;
            final newS = itemData['inStock'] ?? false;
            
            if (order.quantity != newQ || order.inStock != newS) {
              order.quantity = newQ;
              order.inStock = newS;
              needsRebuild = true;
            }
          }
        }
        if (needsRebuild && mounted) {
          setState(() {}); 
        }
      }
    });
  }

  @override
  void dispose() {
    _orderStream?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkBusinessDay();
    }
  }

  Future<void> _calculateReservedItems() async {
    final todayReservations = await fetchTodayReservations();
    final Map<int, double> rawCounts = {};

    for (final res in todayReservations) {
      if (res.memo.isEmpty) continue;

      int courseIdx = -1;
      for (int i = 0; i < courseRecipes.length; i++) {
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

      for (final dishId in course.dishIds) {
        final dishIdx = dishes.indexWhere((d) => d.id == dishId && d.alive);
        if (dishIdx == -1) continue;
        final dish = dishes[dishIdx];

        for (final p in tables) {
          dish.requiredItems.forEach((itemId, req) {
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
                if (dish.specialRule == 'sanchu_2p' && p == 2) {
                  pieces = 4;
                }
                finalAmountForThisTable = (pieces * req.amountPerPerson) / req.yieldPerUnit;
                break;

              case 'step':
                double stepCount = 1.0;
                if (dish.specialRule == 'reimen_step') {
                  if (p <= 2) stepCount = 0.5;
                  else if (p <= 4) stepCount = 1.0;
                  else if (p == 5) stepCount = 1.5;
                  else if (p <= 7) stepCount = 2.0;
                } else if (dish.specialRule == 'kuppa_step') {
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

  Future<void> checkBusinessDay() async {
    final docRef = FirebaseFirestore.instance.collection('working_orders').doc('current');
    final snapshot = await docRef.get();
    
    String? lastDate;
    Map<String, dynamic>? lastData;
    
    if (snapshot.exists && snapshot.data() != null) {
      lastData = snapshot.data()!;
      lastDate = lastData['business_date'] as String?;
    }

    final businessDate = getBusinessDate();
    final currentDate =
        '${businessDate.year}-'
        '${businessDate.month.toString().padLeft(2, '0')}-'
        '${businessDate.day.toString().padLeft(2, '0')}';

    if (lastDate == null) {
      await clearOrders(); 
      debugPrint('Firestore初回設定：営業日を $currentDate に設定しました');
    } else if (lastDate != currentDate && lastData != null) {
      await transferToHistory(lastDate, lastData); 
      await clearOrders(); 
      debugPrint('日付更新：$lastDate のデータを確定履歴に送信し、$currentDate にリセットしました');
    }
  }

  DateTime getBusinessDate() {
    final now = DateTime.now();
    if (now.hour < 6) {
      return now.subtract(const Duration(days: 1));
    }
    return now;
  }

  Future<void> transferToHistory(String targetDate, Map<String, dynamic> rawData) async {
    final List<Map<String, dynamic>> orderData = [];
    
    rawData.forEach((key, value) {
      if (key == 'business_date') return;
      
      final itemId = int.tryParse(key);
      if (itemId == null) return;

      final quantity = (value['quantity'] as num?)?.toDouble() ?? 0.0;
      if (quantity > 0) {
        final itemIndex = items.indexWhere((i) => i.id == itemId);
        final itemName = itemIndex != -1 ? items[itemIndex].name : '不明な商品(ID:$itemId)';

        orderData.add({
          'id': itemId,
          'name': itemName,
          'quantity': quantity,
        });
      }
    });

    if (orderData.isEmpty) return; 

    try {
      await FirebaseFirestore.instance
          .collection('order_history')
          .doc(targetDate)
          .set({
            'date': targetDate,
            'timestamp': FieldValue.serverTimestamp(),
            'total_items': orderData.length,
            'orders': orderData,
          });
      debugPrint('Firebaseに発注履歴を保存しました: $targetDate');
    } catch (e) {
      debugPrint('Firebaseへの保存に失敗しました: $e');
    }
  }

  Future<void> updateSingleOrder(int itemId, double quantity, bool inStock) async {
    final docRef = FirebaseFirestore.instance.collection('working_orders').doc('current');
    await docRef.set({
      itemId.toString(): {
        'quantity': quantity,
        'inStock': inStock,
      }
    }, SetOptions(merge: true));
  }

  Future<void> clearOrders() async {
    final docRef = FirebaseFirestore.instance.collection('working_orders').doc('current');
    final businessDate = getBusinessDate();
    final Map<String, dynamic> data = {
      'business_date': '${businessDate.year}-${businessDate.month.toString().padLeft(2, '0')}-${businessDate.day.toString().padLeft(2, '0')}',
    };

    for (final order in orders) {
      order.quantity = 0.0;
      order.inStock = false;
      data[order.item.id.toString()] = {
        'quantity': 0.0,
        'inStock': false,
      };
    }
    await docRef.set(data);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ★新ロジック：選択されたビューに応じて、動的に表示用カテゴリ一覧を組み立てる
    List<String> displayCategories = [];
    
    if (isKitchenView) {
      displayCategories = orders
          .where((o) => o.item.kitchen_category.isNotEmpty)
          .map((o) => o.item.kitchen_category)
          .toSet()
          .toList();
    } else {
      displayCategories = orders
          .where((o) => o.item.back_category.isNotEmpty)
          .map((o) => o.item.back_category)
          .toSet()
          .toList();
    }

    final List<String> kitchenCategoryOrder = [
      '冷蔵庫（左上）',
      '冷蔵庫（左下）',
      '冷蔵庫（右下）',
      '冷凍庫（右上）',
      '引き出し冷蔵庫',
      '調味料棚',
      'その他',
      'サイドテーブル下',
      'コンロ下'
    ];

    // 【設定】裏側の理想の並び順（上から順に表示されます）
    final List<String> backCategoryOrder = [
      '冷蔵庫（左上段）',
      '冷蔵庫（左中段）',
      '冷蔵庫（左下段）',
      '冷蔵庫（右上段）',
      '冷蔵庫（右中段）',
      '冷蔵庫（右下段）',
      '冷凍庫',
      '棚（上段）',
      '棚（中段）',
      '棚（下段）',
      '棚の下',
      '外'
    ];

    // 上記の設定リストに基づいて displayCategories を並び替え（ソート）する
    displayCategories.sort((a, b) {
      final orderList = isKitchenView ? kitchenCategoryOrder : backCategoryOrder;
      
      int indexA = orderList.indexOf(a);
      int indexB = orderList.indexOf(b);
      
      // リストに定義されていない「新しいカテゴリ」が追加された場合は一番下(999)に回す
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      
      return indexA.compareTo(indexB);
    });

    // ドロップダウンの指定値（5刻みスキップ）
    final quantities = [
      0.0, 0.5, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('発注入力'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PreviousOrderPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => BoardPage(orders: orders)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChiefPage(orders: orders)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 上部の切り替え用ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isKitchenView ? Colors.orange : Colors.grey.shade200,
                      foregroundColor: isKitchenView ? Colors.white : Colors.black87,
                      elevation: isKitchenView ? 2 : 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isKitchenView = true; 
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('キッチン側', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isKitchenView ? Colors.indigo : Colors.grey.shade200,
                      foregroundColor: !isKitchenView ? Colors.white : Colors.black87,
                      elevation: !isKitchenView ? 2 : 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isKitchenView = false; 
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('裏側', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          
          Expanded(
            child: displayCategories.isEmpty
                ? const Center(child: Text('表示する項目がありません', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: displayCategories.length,
                    itemBuilder: (context, catIndex) {
                      final category = displayCategories[catIndex];
                      
                      // ★新ロジック：選択されたビューのカテゴリと一致する商品を抽出
                      final categoryItems = orders.where((order) {
                        return isKitchenView 
                            ? order.item.kitchen_category == category 
                            : order.item.back_category == category;
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 2, thickness: 1.5, indent: 0, endIndent: 0, color: Colors.black),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(category, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                          const Divider(height: 2, thickness: 1.5, indent: 0, endIndent: 0, color: Colors.black),
                          
                          ...categoryItems.map((order) {
                            final reserveAdd = reservedItemCounts[order.item.id];
                            return OrderItemRow(
                              key: ValueKey(order.item.id), 
                              order: order,
                              reserveAdd: reserveAdd,
                              quantities: quantities,
                              isKitchenView: isKitchenView,
                              onUpdate: updateSingleOrder, 
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderItemRow extends StatefulWidget {
  final OrderItem order;
  final double? reserveAdd;
  final List<double> quantities;
  final bool isKitchenView; // ★追加：キッチン側かどうかのフラグ
  final Future<void> Function(int, double, bool) onUpdate;

  const OrderItemRow({
    super.key,
    required this.order,
    this.reserveAdd,
    required this.quantities,
    required this.isKitchenView, // ★追加
    required this.onUpdate,
  });

  @override
  State<OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<OrderItemRow> {
  Timer? _debounce;

  void _triggerUpdate() {
    setState(() {}); 
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onUpdate(widget.order.item.id, widget.order.quantity, widget.order.inStock);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    List<double> displayQuantities = List.from(widget.quantities);
    if (!displayQuantities.contains(order.quantity)) {
      displayQuantities.add(order.quantity);
      displayQuantities.sort();
    }

    // ★追加：見ている画面に応じて、表示する最低数を切り替える
    String displayMinimum = widget.isKitchenView 
        ? order.item.kitchen_minimum 
        : order.item.back_minimum;

    return Column(
      children: [
        Container(
          color: order.inStock ? Colors.grey.withOpacity(0.1) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Checkbox(
                value: order.inStock,
                activeColor: Colors.green,
                onChanged: (bool? value) {
                  order.inStock = value ?? false;
                  _triggerUpdate();
                },
              ),
              Expanded(
                child: RichText(
                  softWrap: true,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: order.item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: order.inStock ? Colors.grey : Colors.black,
                        ),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        style: TextStyle(
                          color: order.inStock ? Colors.grey : Colors.black, 
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        children: [
                          const TextSpan(text: '('),
                          TextSpan(text: displayMinimum), // ★変更：動的に切り替わった最低数を表示
                          if (widget.reserveAdd != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: '+予約分: ${widget.reserveAdd == widget.reserveAdd!.toInt() ? widget.reserveAdd!.toInt() : widget.reserveAdd}',
                              style: TextStyle(
                                color: order.inStock ? Colors.grey : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const TextSpan(text: ')'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 150, 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      iconSize: 32,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.blueGrey,
                      onPressed: order.quantity > 0 
                        ? () {
                            if (order.quantity >= 1.0) {
                              order.quantity -= 1.0;
                            } else {
                              order.quantity = 0.0;
                            }
                            _triggerUpdate();
                          }
                        : null,
                    ),
                    DropdownButton<double>(
                      value: order.quantity,
                      items: displayQuantities.map((q) {
                        return DropdownMenuItem<double>(
                          value: q,
                          child: Text(
                            q.toDisplayString(), 
                            style: const TextStyle(fontSize: 18), 
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          order.quantity = value;
                          _triggerUpdate();
                        }
                      },
                    ),
                    IconButton(
                      iconSize: 32,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.add_circle_outline),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        order.quantity += 1.0;
                        _triggerUpdate();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1, 
          thickness: 0.5, 
          indent: 16, 
          endIndent: 16, 
          color: Color.fromARGB(80, 0, 0, 0),
        ),
      ],
    );
  }
}