import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/item_data.dart';
import 'package:flutter/material.dart';

class PreviousOrderPage extends StatefulWidget {
  const PreviousOrderPage({super.key});

  @override
  State<PreviousOrderPage> createState() => _PreviousOrderPageState();
}

class _PreviousOrderPageState extends State<PreviousOrderPage> {
  // 構造化した日付データ管理用: { '2026': { '06': ['15', '16'] } }
  Map<String, Map<String, List<String>>> dateStructure = {};
  Map<String, String> filePaths = {}; // '2026-06-16' -> 実際のフルパス

  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;

  List<Map<String, dynamic>> parsedOrders = [];

  @override
  void initState() {
    super.initState();
    loadCsvFileList();
  }

  // フォルダ内のファイルを走査して構造化する
  Future<void> loadCsvFileList() async {
    final directory = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${directory.path}/みらんちぷ発注');

    final Map<String, Map<String, List<String>>> structure = {};
    final Map<String, String> paths = {};

    if (await baseDir.exists()) {
      final List<FileSystemEntity> files = baseDir.listSync(recursive: true);
      for (final file in files) {
        if (file is File && file.path.endsWith('.csv')) {
          final fileName = file.uri.pathSegments.last.replaceAll('.csv', '');
          final parts = fileName.split('-');
          
          if (parts.length == 3) {
            final year = parts[0];
            final month = parts[1];
            final day = parts[2];

            structure.putIfAbsent(year, () => {});
            structure[year]!.putIfAbsent(month, () => []);
            if (!structure[year]![month]!.contains(day)) {
              structure[year]![month]!.add(day);
            }

            paths[fileName] = file.path;
          }
        }
      }
    }

    // 選択しやすいように、年・月・日すべてを降順（新しい順）に並び替える
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

      // 昨日のデータがあればそれを第一候補に、なければ存在する最新のデータを取る
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
        filePaths = paths;
        selectedYear = year;
        selectedMonth = month;
        selectedDay = day;
      });

      await updateContent();
    } else {
      setState(() {
        dateStructure = {};
        filePaths = {};
        selectedYear = null;
        selectedMonth = null;
        selectedDay = null;
        parsedOrders = [];
      });
    }
  }

  // 選択された年・月・日からデータを更新する
  Future<void> updateContent() async {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) return;
    final dateKey = '$selectedYear-$selectedMonth-$selectedDay';
    await loadCsvContent(dateKey);
  }

  Future<void> loadCsvContent(String dateString) async {
    final filePath = filePaths[dateString];
    if (filePath == null) {
      setState(() {
        parsedOrders = [];
      });
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) return;

    final csvString = await file.readAsString();
    final lines = csvString.split('\n');
    final List<Map<String, dynamic>> loadedOrders = [];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cells = line.split(',');
      if (cells.length >= 2) {
        final id = int.tryParse(cells[0]);
        final quantityText = cells[1];

        if (id != null) {
          double quantity = 0.0;
          if (quantityText == '1/2') {
            quantity = 0.5;
          } else {
            quantity = double.tryParse(quantityText) ?? 0.0;
          }

          loadedOrders.add({
            'id': id,
            'quantity': quantity,
          });
        }
      }
    }

    setState(() {
      parsedOrders = loadedOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 選択された年に存在する月の選択肢
    List<String> months = [];
    if (selectedYear != null && dateStructure.containsKey(selectedYear)) {
      months = dateStructure[selectedYear]!.keys.toList();
    }

    // 選択された年・月に存在する日の選択肢
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
                        // 年が変わったら、その年にある最新の月・日へ連動安全切り替え
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
                      // 見栄えのために '06' を '6' にして表示
                      final displayMonth = int.tryParse(month)?.toString() ?? month;
                      return DropdownMenuItem(value: month, child: Text(displayMonth));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        // 月が変わったら、その月にある最新の日へ連動安全切り替え
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
                      // 見栄えのために '09' を '9' にして表示
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      '${item.name} × '
                      '${quantity == 0.5 ? '1/2' : quantity.toStringAsFixed(
                          quantity == quantity.toInt() ? 0 : 1,
                        )}',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
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