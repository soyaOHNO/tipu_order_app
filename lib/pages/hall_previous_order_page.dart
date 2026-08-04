import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HallPreviousOrderPage extends StatefulWidget {
  const HallPreviousOrderPage({super.key});

  @override
  State<HallPreviousOrderPage> createState() => _HallPreviousOrderPageState();
}

class _HallPreviousOrderPageState extends State<HallPreviousOrderPage> {
  // 構造化した日付データ管理用: { '2026': { '06': ['15', '16'] } }
  Map<String, Map<String, List<String>>> dateStructure = {};

  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;

  List<Map<String, dynamic>> parsedOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFirestoreOrderList();
  }

  // Firestoreからホールの全履歴ドキュメントIDを取得して構造化する
  Future<void> loadFirestoreOrderList() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hall_order_history')
          .get();

      final Map<String, Map<String, List<String>>> structure = {};

      for (final doc in snapshot.docs) {
        final dateKey = doc.id; // 例: "2026-08-04"
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

      // 降順（最新順）にソート
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
        // デフォルト値の決定（昨日）
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
          isLoading = false;
        });

        await updateContent();
      } else {
        _clearState();
      }
    } catch (e) {
      debugPrint('ホール履歴リストの取得に失敗しました: $e');
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
      isLoading = false;
    });
  }

  // 選択された日付のデータを更新する
  Future<void> updateContent() async {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) return;
    final dateKey = '$selectedYear-$selectedMonth-$selectedDay';
    await loadFirestoreContent(dateKey);
  }

  // 指定日付のホール履歴をFirestoreから取得
  Future<void> loadFirestoreContent(String dateString) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hall_order_history')
          .doc(dateString)
          .get();

      if (!doc.exists) {
        setState(() {
          parsedOrders = [];
        });
        return;
      }

      final data = doc.data();
      if (data == null || data['orders'] == null) {
        setState(() {
          parsedOrders = [];
        });
        return;
      }

      final List<dynamic> ordersRaw = data['orders'];
      final List<Map<String, dynamic>> loadedOrders = [];

      for (final o in ordersRaw) {
        loadedOrders.add({
          'id': o['id'] ?? 0,
          'name': o['name'] ?? '',
          'quantity': o['quantity'] ?? 0,
          'is_supply': o['is_supply'] ?? false,
          'is_checked': o['is_checked'] ?? false,
          'user_memo': o['user_memo'] ?? '',
        });
      }

      setState(() {
        parsedOrders = loadedOrders;
      });
    } catch (e) {
      debugPrint('特定日付のホール履歴取得に失敗しました: $e');
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

    // グループ分け（確認画面と同様の振り分け）
    final kitchenItems = parsedOrders.where((item) => (item['name'] as String).contains('キッチン')).toList();
    final barItems = parsedOrders.where((item) => (item['name'] as String).contains('バー') && !kitchenItems.contains(item)).toList();
    final regularOrderItems = parsedOrders.where((item) => !kitchenItems.contains(item) && !barItems.contains(item)).toList();

    Widget buildSection(String title, List<Map<String, dynamic>> items) {
      if (items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
          ...items.map((item) {
            final String name = item['name'];
            final int quantity = item['quantity'];
            final bool isSupply = item['is_supply'];
            final String userMemo = item['user_memo'];

            String displayText = '';
            if (isSupply) {
              displayText = '$name × 1';
            } else if (quantity > 0) {
              displayText = '$name × $quantity';
            } else {
              displayText = name;
            }

            if (userMemo.isNotEmpty) {
              displayText += ' ($userMemo)';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayText,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('発注履歴'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (dateStructure.isNotEmpty)
                  Container(
                    color: Colors.indigo.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
                        const Text(' 年 ', style: TextStyle(fontWeight: FontWeight.bold)),

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
                        const Text(' 月 ', style: TextStyle(fontWeight: FontWeight.bold)),

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
                        const Text(' 日', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                if (dateStructure.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        '保存されたホール発注履歴はありません',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),

                if (dateStructure.isNotEmpty && parsedOrders.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'この日のホール発注データはありません',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),

                if (dateStructure.isNotEmpty && parsedOrders.isNotEmpty)
                  Expanded(
                    child: ListView(
                      children: [
                        buildSection('発注リスト', regularOrderItems),
                        buildSection('バーに報告', barItems),
                        buildSection('キッチンに報告', kitchenItems),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}