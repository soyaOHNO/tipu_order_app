import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ★ dart:io の代わりにFirestoreを導入
import '../data/item_data.dart';

class PreviousOrderPage extends StatefulWidget {
  const PreviousOrderPage({super.key});

  @override
  State<PreviousOrderPage> createState() => _PreviousOrderPageState();
}

class _PreviousOrderPageState extends State<PreviousOrderPage> {
  // 構造化した日付データ管理用: { '2026': { '06': ['15', '16'] } }
  Map<String, Map<String, List<String>>> dateStructure = {};

  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;

  List<Map<String, dynamic>> parsedOrders = [];

  @override
  void initState() {
    super.initState();
    loadFirestoreOrderList(); // ★起動時にFirestoreから履歴リストを読み込む
  }

  // ★ フォルダ走査の代わりに、Firestoreから全履歴のドキュメントIDを取得して構造化する
  Future<void> loadFirestoreOrderList() async {
    try {
      // 履歴一覧をFirestoreから取得
      final snapshot = await FirebaseFirestore.instance
          .collection('order_history')
          .get();

      final Map<String, Map<String, List<String>>> structure = {};

      for (final doc in snapshot.docs) {
        // ドキュメントIDが "2026-06-18" のような文字列になっている
        final dateKey = doc.id;
        final parts = dateKey.split('-');
        
        if (parts.length == 3) {
          final year = parts[0];
          final month = parts[1];
          final day = parts[2];

          structure.putIfAbsent(year, () => {});
          structure[year]!.putIfAbsent(month, () => []);
          if (!structure[year]![month]!.contains(day)) {
            structure[year]![month]!.add(day);
          }
        }
      }

      // 選択しやすいように、年・月・日すべてを降順（新しい順）に並び替える（既存の優秀なロジックをそのまま流用）
      final sortedYears = structure.keys.toList()..sort((a, b) => b.compareTo(a));
      final Map<String, Map<String, List<String>>> sortedStructure = {};
      
      for (final year in sortedYears) {
        final months = structure[year]!.keys.toList()..sort((a, b) => b.compareTo(a));
        sortedStructure[year] = {};
        for (final month in months) {
          final days = structure[year]![month]!..sort((a, b) => b.compareTo(a));
          sortedStructure[year]![month] = days;
        }
      }

      if (sortedStructure.isNotEmpty) {
        // デフォルト値の決定（現在の1日前 = 昨日）
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final defaultYear = yesterday.year.toString();
        final defaultMonth = yesterday.month.toString().padLeft(2, '0');
        final defaultDay = yesterday.day.toString().padLeft(2, '0');

        String year = sortedStructure.keys.first;
        if (sortedStructure.containsKey(defaultYear)) {
          year = defaultYear;
        }

        String month = sortedStructure[year]!.keys.first;
        if (sortedStructure[year]!.containsKey(defaultMonth)) {
          month = defaultMonth;
        }

        String day = sortedStructure[year]![month]!.first;
        if (sortedStructure[year]![month]!.contains(defaultDay)) {
          day = defaultDay;
        }

        setState(() {
          dateStructure = sortedStructure;
          selectedYear = year;
          selectedMonth = month;
          selectedDay = day;
        });

        await updateContent();
      } else {
        _clearState();
      }
    } catch (e) {
      debugPrint('履歴リストの取得に失敗しました: $e');
      _clearState();
    }
  }

  void _clearState() {
    setState(() {
      dateStructure = {};
      selectedYear = null;
      selectedMonth = null;
      selectedDay = null;
      parsedOrders = [];
    });
  }

  // 選択された年・月・日からデータを更新する
  Future<void> updateContent() async {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) return;
    final dateKey = '$selectedYear-$selectedMonth-$selectedDay';
    await loadFirestoreContent(dateKey);
  }

  // ★ 指定された日付のドキュメントをFirestoreから1発で引いてくる関数
  Future<void> loadFirestoreContent(String dateString) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('order_history')
          .doc(dateString)
          .get();

      if (!doc.exists) {
        setState(() {
          parsedOrders = [];
        });
        return;
      }

      final data = doc.data();
      if (data == null || data['orders'] == null) return;

      final List<dynamic> ordersRaw = data['orders'];
      final List<Map<String, dynamic>> loadedOrders = [];

      for (final o in ordersRaw) {
        loadedOrders.add({
          'id': o['id'] ?? 0,
          'quantity': (o['quantity'] as num?)?.toDouble() ?? 0.0,
        });
      }

      setState(() {
        parsedOrders = loadedOrders;
      });
    } catch (e) {
      debugPrint('特定日付の履歴取得に失敗しました: $e');
      setState(() {
        parsedOrders = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> months = [];
    if (selectedYear != null && dateStructure.containsKey(selectedYear)) {
      months = dateStructure[selectedYear]!.keys.toList();
    }

    List<String> days = [];
    if (selectedYear != null && selectedMonth != null && 
        dateStructure[selectedYear]?.containsKey(selectedMonth) == true) {
      days = dateStructure[selectedYear]![selectedMonth]!;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('発注履歴選択'),
      ),
      body: Column(
        children: [
          if (dateStructure.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 年選択
                  DropdownButton<String>(
                    value: selectedYear,
                    items: dateStructure.keys.map((year) {
                      return DropdownMenuItem(value: year, child: Text(year));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final nextMonths = dateStructure[value]!.keys.toList();
                        final nextMonth = nextMonths.first;
                        final nextDays = dateStructure[value]![nextMonth]!;
                        final nextDay = nextDays.first;
                        setState(() {
                          selectedYear = value;
                          selectedMonth = nextMonth;
                          selectedDay = nextDay;
                        });
                        updateContent();
                      }
                    },
                  ),
                  const Text(' 年 '),
                  
                  // 月選択
                  DropdownButton<String>(
                    value: selectedMonth,
                    items: months.map((month) {
                      final displayMonth = int.tryParse(month)?.toString() ?? month;
                      return DropdownMenuItem(value: month, child: Text(displayMonth));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final nextDays = dateStructure[selectedYear]![value]!;
                        final nextDay = nextDays.first;
                        setState(() {
                          selectedMonth = value;
                          selectedDay = nextDay;
                        });
                        updateContent();
                      }
                    },
                  ),
                  const Text(' 月 '),

                  // 日選択
                  DropdownButton<String>(
                    value: selectedDay,
                    items: days.map((day) {
                      final displayDay = int.tryParse(day)?.toString() ?? day;
                      return DropdownMenuItem(value: day, child: Text(displayDay));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedDay = value;
                        });
                        updateContent();
                      }
                    },
                  ),
                  const Text(' 日'),
                ],
              ),
            ),

          if (dateStructure.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  '保存された発注履歴はありません',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),

          if (dateStructure.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: parsedOrders.length,
                itemBuilder: (context, index) {
                  final order = parsedOrders[index];
                  final itemIndex = items.indexWhere((i) => i.id == order['id']);
                  if (itemIndex == -1) return const SizedBox.shrink();
                  
                  final item = items[itemIndex];
                  final quantity = order['quantity'] as double;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '${item.name} × '
                      '${quantity == 0.5 ? '1/2' : quantity.toStringAsFixed(
                          quantity == quantity.toInt() ? 0 : 1,
                        )}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}