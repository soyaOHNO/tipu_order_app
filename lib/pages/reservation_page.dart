import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // クリップボード機能を使うため追加
import '../models/reservation.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  List<Reservation> reservations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchToretaData();
  }

  Future<void> _fetchToretaData() async {
    await Future.delayed(const Duration(seconds: 1));
    final today = DateTime.now();
    
    // ご指定のフォーマットをテストするためのダミーデータ
    setState(() {
      reservations = [
        Reservation(
          id: 'T001',
          customerName: '田中 様',
          time: DateTime(today.year, today.month, today.day, 19, 00),
          peopleCount: 4,
          memo: '', // 席のみ
        ),
        Reservation(
          id: 'T002',
          customerName: '佐藤 様',
          time: DateTime(today.year, today.month, today.day, 19, 00),
          peopleCount: 2,
          memo: 'コース名A', // コースあり
        ),
        Reservation(
          id: 'T003',
          customerName: '鈴木 様',
          time: DateTime(today.year, today.month, today.day, 19, 30),
          peopleCount: 5,
          memo: '',
        ),
        Reservation(
          id: 'T004',
          customerName: '高橋 様',
          time: DateTime(today.year, today.month, today.day, 19, 30),
          peopleCount: 2,
          memo: '',
        ),
        Reservation(
          id: 'T005',
          customerName: '伊藤 様',
          time: DateTime(today.year, today.month, today.day, 21, 00),
          peopleCount: 3,
          memo: 'コース名B',
        ),
      ];
      isLoading = false;
    });
  }

  // ★ 追加：予約リストをご指定のフォーマットのテキストに変換する関数
  String _generatePrintFormat() {
    // 1. 時間（"HH:mm"）をキーにして、同じ時間の予約をリストにまとめる
    final Map<String, List<Reservation>> grouped = {};
    for (final r in reservations) {
      final timeKey = '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(timeKey, () => []).add(r);
    }

    // 2. 時間順に並び替える
    final sortedKeys = grouped.keys.toList()..sort();

    final buffer = StringBuffer();

    // 3. テキストの組み立て
    for (final timeKey in sortedKeys) {
      final resList = grouped[timeKey]!;
      for (int i = 0; i < resList.length; i++) {
        final r = resList[i];
        
        // 人数とコース名の結合（メモがあれば "× コース名" を足す）
        String details = r.peopleCount.toString();
        if (r.memo.isNotEmpty) {
          details += '×${r.memo}'; // 例: "2×コース名A"
        }

        if (i == 0) {
          // その時間の1件目は時間を出力
          buffer.writeln('$timeKey : $details');
        } else {
          // 2件目以降は時間を空白(インデント)にして綺麗に揃える
          buffer.writeln('         : $details');
        }
      }
    }

    return buffer.toString();
  }

  // ★ 追加：印刷用プレビューダイアログを表示し、コピーする関数
  void _showPrintPreview() {
    final printText = _generatePrintFormat();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('伝票出力用フォーマット'),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100, // レシートっぽい背景色
            child: SingleChildScrollView(
              child: SelectableText(
                printText,
                style: const TextStyle(
                  fontFamily: 'monospace', // 等幅フォントで揃えを綺麗にする
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('コピーする'),
              onPressed: () async {
                // クリップボードにコピー
                await Clipboard.setData(ClipboardData(text: printText));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('伝票テキストをコピーしました！プリンターアプリに貼り付けてください。'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本日の予約 (トレタ連携)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // ★ 追加：伝票出力ボタン
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: '伝票テキストを作成',
            onPressed: isLoading ? null : _showPrintPreview,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchToretaData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final r = reservations[index];
                final timeString = '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text('${r.peopleCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${r.customerName}  ($timeString)'),
                    subtitle: r.memo.isNotEmpty ? Text(r.memo, style: const TextStyle(color: Colors.red)) : null,
                  ),
                );
              },
            ),
    );
  }
}