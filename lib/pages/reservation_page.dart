import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reservation.dart';
import '../data/reservation_data.dart';
import 'dart:io';
import 'dart:convert';
import 'package:charset_converter/charset_converter.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  List<Reservation> reservations = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

  // ★ 1. 伝票出力用のアラートキーワード（うっすらオレンジになる）
  final List<String> slipKeyword = [
    'プレート',
    'ガラス箱',
    // 'お祝い',  // ← 後からこうして追加できます
  ];

  // ★ 2. ネット予約のコメント欄を判定するための開始キーワード
  final List<String> commentPrefixes = [
    '要望・コメント：',
    '要望・相談：',
    // 'レストランへのご要望：', // ← 別のサイト用に追加可能
  ];

  // ★ 3. コメント欄が「空」のときに直下に来るシステム項目のキーワード
  // （要望・コメント：のすぐ後にこれらの言葉が来たら「コメントなし」と判定します）
  final List<String> systemNextFields = [
    '利用するVポイント：',
    'クーポン：',
    '予約更新履歴：',
    '特典：',
    // '来店回数：', // ← 別のサイト用に追加可能
  ];
  // ★ 4. 追加：ネット予約システム特有の目印キーワード
  // （これらが含まれる場合は、スタッフの手打ちメモではなく「ネット予約」と判定して厳密にチェックします）
  final List<String> webSignatures = [
    '媒体名：',
    '予約番号：',
    '--- Yahoo!リザベーションマネージャー ---',
    '[国]',
    '一休',
    // '来店回数：', // ← 必要に応じて追加可能
  ];

  @override
  void initState() {
    super.initState();
    _fetchToretaData();
  }

  Future<void> _fetchToretaData() async {
    setState(() => isLoading = true);
    
    final dateString = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    final fetchedData = await fetchTodayReservations(dateString);
    setState(() {
      reservations = fetchedData;
      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchToretaData();
    }
  }

  // 💡 人数とメモ（子供・小・コース人数乖離）のチェック関数
  bool _hasPeopleMismatch(Reservation r) {
    final note = r.note ?? '';
    if (note.isEmpty) return false;

    // ① 子供・子ども・お子様が含まれるか
    if (note.contains('子供') || note.contains('子ども') || note.contains('お子様')) {
      return true;
    }

    // ② 「小1」「小 1」「小1名」「小 2人」などの「小＋数字」パターンがあるか
    final childPattern = RegExp(r'小\s*\d+');
    if (childPattern.hasMatch(note)) {
      return true;
    }

    // ③ ★【コース予約がある場合のみ判定】メモ内の数字（〇名・〇人）と予約総人数(r.people)の乖離をチェック
    if (r.course != null) {
      final regExp = RegExp(r'(\d+)\s*(?:名|人)');
      final matches = regExp.allMatches(note);

      for (final match in matches) {
        final numberStr = match.group(1);
        if (numberStr != null) {
          final num = int.tryParse(numberStr);
          if (num != null && num != r.people) {
            return true;
          }
        }
      }
    }

    return false;
  }

  String _generatePrintFormat() {
    final Map<String, List<Reservation>> grouped = {};
    for (final r in reservations) {
      grouped.putIfAbsent(r.startTime, () => []).add(r);
    }

    final sortedKeys = grouped.keys.toList();
    sortedKeys.sort();

    final buffer = StringBuffer();
    buffer.writeln('【${selectedDate.month}/${selectedDate.day} の予約一覧】\n');

    for (final timeKey in sortedKeys) {
      final resList = grouped[timeKey]!;
      for (int i = 0; i < resList.length; i++) {
        final r = resList[i];
        
        String details = '${r.people}名';
        
        if (r.course != null) {
          String shortCourseName;
          if (r.course!.contains('赤身天国コース')) {
            shortCourseName = '赤天';
          } else if (r.course!.contains('赤身天国＋クラシタ火山コース')) {
            shortCourseName = '赤k';
          } else if (r.course!.contains('赤身天国＋刺身スペシャルnew')) {
            shortCourseName = '赤さし';
          } else if (r.course!.contains('赤身天国＋刺身スペシャル')) {
            shortCourseName = '赤さし';
          } else if (r.course!.contains('アニバーサリーコース')) {
            shortCourseName = 'アニバ';
          } else if (r.course!.contains('ロイヤルコース')) {
            shortCourseName = 'ロイヤル(赤さし)';
          } else if (r.course!.contains('スペシャルコース')) {
            shortCourseName = 'スぺ';
          } else if (r.course!.contains('みらんコース')) {
            shortCourseName = 'みらん';
          } else if (r.course!.contains('旧みらんコース')) {
            shortCourseName = 'みらん';
          } else {
            shortCourseName = r.course!.replaceAll('コース', '');
          } 
          details += '×$shortCourseName'; 
        }

        if (r.note != null && r.note!.isNotEmpty) {
          for (final keyword in slipKeyword) {
            if (r.note!.contains(keyword)) {
              String displayKeyword = keyword == 'ガラス箱' ? 'プレート' : keyword;
              details += '【$displayKeyword】';
              break;
            }
          }
        }
        if (i == 0) {
          buffer.writeln('$timeKey : $details');
        } else {
          buffer.writeln('          : $details');
        }
      }
    }
    return buffer.toString();
  }

  // ★ 追加：キッチンプリンタへ直接データを送る関数
  Future<void> _printToKitchenPrinter(BuildContext context, String printText) async {
    // 送信中のスナックバー表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('プリンタへ送信中...')),
    );

    // 仕様書で確認したIPとポート
    final String ip = '192.168.32.202'; // 動かなければ 203 に変更してください
    final int port = 9100;

    try {
      Socket socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

      // 1. プリンタ初期化コマンド (ESC @)
      socket.add([0x1B, 0x40]);

      // 2. 文字サイズ設定（予約一覧なので少し見やすくする）
      // 標準サイズにしたい場合はこの行をコメントアウトしてください
      // socket.add([0x1B, 0x21, 0x00]); 

      // 3. テキストデータの送信
      // パッケージを使って Shift-JIS に変換！
      final encodedText = await CharsetConverter.encode("Shift_JIS", printText);
      socket.add(encodedText);

      // 4. 余白のための改行（紙を少し送る）
      socket.add(utf8.encode('\n\n\n\n\n'));

      // 5. 用紙カットコマンド (GS V 0)
      socket.add([0x1D, 0x56, 0x00]);

      await socket.flush();
      socket.destroy();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('印刷が完了しました！', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('印刷エラー: プリンタとの通信に失敗しました ($e)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePrintAction(BuildContext context) async {
    final printText = _generatePrintFormat();
    if (!context.mounted) return;
    _showPrintPreview(context, printText);
  }

  void _showReservationDetails(BuildContext context, Reservation r, String tableId) {
    final bool isMismatch = _hasPeopleMismatch(r);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$tableId卓 - ${r.startTime}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMismatch)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.redAccent),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'お子様・小の指定、またはコース人数の内訳記載があります。メモを確認してください。',
                            style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                Text('👥 人数: ${r.people}名', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                const Text('🍽 コース:', style: TextStyle(fontSize: 16)),
                if (r.course != null)
                  Text(r.course!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))
                else
                  const Text('席のみ', style: TextStyle(color: Colors.blueGrey, fontSize: 18)),
                const SizedBox(height: 12),
                const Text('📝 メモ:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.note?.isNotEmpty == true ? r.note! : 'なし', 
                    style: const TextStyle(fontSize: 14)
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showPrintPreview(BuildContext context, String printText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('伝票出力用フォーマット'),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              child: SelectableText(
                printText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18, height: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('閉じる')
            ),
            // ★ 追加：キッチンプリンタへの直接印刷ボタン
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.print),
              label: const Text('印刷'),
              onPressed: () async {
                Navigator.pop(context); // ダイアログを閉じる
                await _printToKitchenPrinter(context, printText); // 印刷実行！
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Reservation>> groupedByTable = {};
    for (final r in reservations) {
      groupedByTable.putIfAbsent(r.tableId, () => []).add(r);
    }

    final sortedTables = groupedByTable.keys.toList()..sort();
    final dateStr = '${selectedDate.month}/${selectedDate.day}';

    return Scaffold(
      appBar: AppBar(
        title: Text('$dateStr の予約'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), tooltip: '日付を選択', onPressed: () => _selectDate(context)),
          IconButton(
            icon: const Icon(Icons.print), 
            tooltip: '伝票出力', 
            onPressed: isLoading ? null : () => _handlePrintAction(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchToretaData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedTables.isEmpty
              ? const Center(child: Text('この日の予約はありません', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  itemCount: sortedTables.length,
                  itemBuilder: (context, index) {
                    final tableId = sortedTables[index];
                    
                    final tableReservations = groupedByTable[tableId]!;
                    tableReservations.sort((a, b) => a.startTime.compareTo(b.startTime));

                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black12)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 60,
                              color: Colors.blue.shade50,
                              alignment: Alignment.center,
                              child: Text(
                                tableId,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                child: Row(
                                  children: tableReservations.map((r) {
                                    
                                    final note = r.note ?? '';
                                    final bool hasKeyword = slipKeyword.any((keyword) => note.contains(keyword));
                                    
                                    bool hasActualComment = false;
                                    
                                    if (note.trim().isNotEmpty) {
                                      bool isWebReservation = webSignatures.any((sig) => note.contains(sig));
                                      
                                      if (!isWebReservation) {
                                        hasActualComment = true;
                                      } else {
                                        for (final prefix in commentPrefixes) {
                                          final index = note.indexOf(prefix);
                                          if (index != -1) {
                                            String afterPrefix = note.substring(index + prefix.length).trimLeft();
                                            bool isFollowedBySystemField = systemNextFields.any((field) => afterPrefix.startsWith(field));
                                            
                                            if (afterPrefix.isNotEmpty && !isFollowedBySystemField) {
                                              hasActualComment = true;
                                              break;
                                            }
                                          }
                                        }
                                      }
                                    }

                                    Color cardBgColor = Colors.white;
                                    Color borderColor = Colors.grey.shade300;
                                    double borderWidth = 1.0;

                                    if (hasKeyword) {
                                      cardBgColor = Colors.orange.shade50;
                                      borderColor = Colors.orangeAccent;
                                      borderWidth = 1.5;
                                    } else if (hasActualComment) {
                                      cardBgColor = Colors.yellow.shade50;
                                      borderColor = Colors.amber;
                                      borderWidth = 1.5;
                                    }

                                    final bool isPeopleMismatch = _hasPeopleMismatch(r);

                                    return Card(
                                      color: cardBgColor,
                                      elevation: 2,
                                      margin: const EdgeInsets.only(right: 12.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: borderColor, width: borderWidth),
                                      ),
                                      child: InkWell(
                                        onTap: () => _showReservationDetails(context, r, tableId),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 160,
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(r.startTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.person, size: 14, color: Colors.grey),
                                                      Text('${r.people}名', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      
                                                      if (isPeopleMismatch) ...[
                                                        const SizedBox(width: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red.shade100,
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.red, width: 0.8),
                                                          ),
                                                          child: const Text(
                                                            '⚠️人数',
                                                            style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 12),
                                              if (r.course != null)
                                                Text(r.course!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
                                              else
                                                const Text('席のみ', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                                              if (r.note != null && r.note!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Text(r.note!, style: const TextStyle(color: Colors.black87, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}