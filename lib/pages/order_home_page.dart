import 'dart:async';
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
  StreamSubscription<DocumentSnapshot>? _orderStream; // ★追加：リアルタイム同期用の監視

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
    // 1. まず日付チェックとリセット処理を確定させる
    await checkBusinessDay();
    // 2. その後、Firestoreのリアルタイム監視を開始
    _listenToOrders();
    // 3. トレタ連携（デモ）の計算
    await _calculateReservedItems();
  }

  // ★追加：Firestoreからのリアルタイム受信
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
            
            // 自分の端末以外から変更があった場合のみUIを更新する
            if (order.quantity != newQ || order.inStock != newS) {
              order.quantity = newQ;
              order.inStock = newS;
              needsRebuild = true;
            }
          }
        }
        if (needsRebuild && mounted) {
          setState(() {}); // 外部からの変更があった時だけ全体を再描画
        }
      }
    });
  }

  @override
  void dispose() {
    _orderStream?.cancel(); // 画面を閉じる時に監視を解除
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkBusinessDay();
    }
  }

  // ★修正：ハードコードを排除し specialRule で計算
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
    if (snapshot.exists && snapshot.data() != null) {
      lastDate = snapshot.data()!['business_date'] as String?;
    }

    final businessDate = getBusinessDate();
    final currentDate =
        '${businessDate.year}-'
        '${businessDate.month.toString().padLeft(2, '0')}-'
        '${businessDate.day.toString().padLeft(2, '0')}';

    if (lastDate == null) {
      await clearOrders(); 
      debugPrint('Firestore初回設定：営業日を $currentDate に設定しました');
    } else if (lastDate != currentDate) {
      await saveOrderLogToFirebase(lastDate); 
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

  Future<void> saveOrderLogToFirebase(String targetDate) async {
    final orderedItems = orders.where((o) => o.quantity > 0).toList();
    if (orderedItems.isEmpty) return; 

    final List<Map<String, dynamic>> orderData = orderedItems.map((order) {
      return {
        'id': order.item.id,
        'name': order.item.name,
        'quantity': order.quantity,
      };
    }).toList();

    try {
      await FirebaseFirestore.instance
          .collection('order_history')
          .doc(targetDate)
          .set({
            'date': targetDate,
            'timestamp': FieldValue.serverTimestamp(),
            'total_items': orderedItems.length,
            'orders': orderData,
          });
      debugPrint('Firebaseに発注履歴を保存しました: $targetDate');
    } catch (e) {
      debugPrint('Firebaseへの保存に失敗しました: $e');
    }
  }

  // ★追加：変更があった商品１つだけをピンポイントでFirestoreに保存する（通信量激減）
  Future<void> updateSingleOrder(int itemId, double quantity, bool inStock) async {
    final docRef = FirebaseFirestore.instance.collection('working_orders').doc('current');
    
    // SetOptions(merge: true) を使うことで、他の商品のデータを消さずに特定の項目だけを安全に更新・追加します
    await docRef.set({
      itemId.toString(): {
        'quantity': quantity,
        'inStock': inStock,
      }
    }, SetOptions(merge: true));
  }

  // ★変更：すべてゼロにリセットして全体保存（強制リセットや日次更新時のみ呼ばれる）
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
    setState(() {}); // 画面全体をリセット
  }

  @override
  Widget build(BuildContext context) {
    final categories = items.map((item) => item.category).toSet().toList();
    if (categories.contains('裏')) {
      categories.remove('裏');
      categories.add('裏');
    }
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
      // ★ 描画の最適化により、外側のリストが再描画されることはほぼ無くなります
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, catIndex) {
          final category = categories[catIndex];
          final categoryItems = orders.where((order) => order.item.category == category).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 2, thickness: 1.5, indent: 0, endIndent: 0, color: Colors.black),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(category, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 2, thickness: 1.5, indent: 0, endIndent: 0, color: Colors.black),
              
              // ★変更：中身の行を専用の独立したWidget（OrderItemRow）に切り出し！
              ...categoryItems.map((order) {
                final reserveAdd = reservedItemCounts[order.item.id];
                return OrderItemRow(
                  key: ValueKey(order.item.id), // 一意のキーを持たせて描画バグを防ぐ
                  order: order,
                  reserveAdd: reserveAdd,
                  quantities: quantities,
                  onUpdate: updateSingleOrder, // ピンポイント保存関数を渡す
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// ★ 大改革の要：商品の1行分だけを独立して描画・管理する専用Widget
// ----------------------------------------------------------------------
class OrderItemRow extends StatefulWidget {
  final OrderItem order;
  final double? reserveAdd;
  final List<double> quantities;
  final Future<void> Function(int, double, bool) onUpdate;

  const OrderItemRow({
    super.key,
    required this.order,
    this.reserveAdd,
    required this.quantities,
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
      print('Updated item ${widget.order.item.name}: quantity=${widget.order.quantity}, inStock=${widget.order.inStock}');
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

    // 現在の数量(order.quantity)がリストに存在しない場合（例: 16）、
    // エラーにならないよう、動的にリストへ追加して綺麗に並び替えます。
    List<double> displayQuantities = List.from(widget.quantities);
    if (!displayQuantities.contains(order.quantity)) {
      displayQuantities.add(order.quantity);
      displayQuantities.sort();
    }

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
                          TextSpan(text: order.item.minimum),
                          if (widget.reserveAdd != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: '+予約分: ${widget.reserveAdd == widget.reserveAdd!.toInt() ? widget.reserveAdd!.toInt() : widget.reserveAdd!.toDisplayString()}',
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
                            q.toDisplayString(), // ★ 変更：さっき作った拡張メソッドでスッキリ！
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