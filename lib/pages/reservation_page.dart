import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reservation.dart';
import '../data/reservation_data.dart';
import '../data/course_data.dart'; // ★追加：コースマスタを参照する

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
    final fetchedData = await fetchTodayReservations();
    setState(() {
      reservations = fetchedData;
      isLoading = false;
    });
  }

  // ★新設：汚いメモ欄から登録されているコース名だけを自動で抜き出す魔法の関数
  String _extractCourseName(String memo) {
    for (final course in courseRecipes) {
      if (memo.contains(course.courseName)) {
        return course.courseName; // マスタのコース名が含まれていたらそれを返す
      }
    }
    return ''; // なければ単品扱い
  }

  // 予約リストを伝票出力用フォーマットに変換
  String _generatePrintFormat() {
    final Map<String, List<Reservation>> grouped = {};
    for (final r in reservations) {
      final timeKey = '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(timeKey, () => []).add(r);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final buffer = StringBuffer();

    for (final timeKey in sortedKeys) {
      final resList = grouped[timeKey]!;
      for (int i = 0; i < resList.length; i++) {
        final r = resList[i];
        
        // ★変更：生メモではなく、抜き出した綺麗なコース名だけをドッキング！
        String details = r.peopleCount.toString();
        final courseName = _extractCourseName(r.memo);
        if (courseName.isNotEmpty) {
          details += '×$courseName'; // 例: "9×スペシャル"
        }

        if (i == 0) {
          buffer.writeln('$timeKey : $details');
        } else {
          buffer.writeln('         : $details');
        }
      }
    }

    return buffer.toString();
  }

  void _showPrintPreview() {
    final printText = _generatePrintFormat();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('伝票出力プレビュー'),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              child: SelectableText(
                printText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('コピーする'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: printText));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('伝票テキストをコピーしました！'),
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
        title: const Text('明日の予約状況'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
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
                
                // ★追加：コース名の抜き出し
                final courseName = _extractCourseName(r.memo);
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text('${r.peopleCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${r.customerName}  ($timeString)'),
                    // ★デモ専用UI：システムが自動抽出したコース名と、実際のToretaメモを並べて見せる
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (courseName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text(courseName, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                            )
                          else
                            const Text('単品', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('メモ: ${r.memo.isEmpty ? "なし" : r.memo}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}