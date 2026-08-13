import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/reservation.dart';
import '../data/reservation_data.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  List<Reservation> reservations = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

  final List<String> slipKeyword = [
    'プレート',
    'ガラス箱',
  ];

  final List<String> commentPrefixes = [
    '要望・コメント：',
    '要望・相談：',
  ];

  final List<String> systemNextFields = [
    '利用するVポイント：',
    'クーポン：',
    '予約更新履歴：',
    '特典：',
  ];

  final List<String> webSignatures = [
    '媒体名：',
    '予約番号：',
    '--- Yahoo!リザベーションマネージャー ---',
    '[国]',
    '一休',
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

  bool _hasPeopleMismatch(Reservation r) {
    final note = r.note ?? '';
    if (note.isEmpty) return false;

    if (note.contains('子供') || note.contains('子ども') || note.contains('お子様')) {
      return true;
    }

    final childPattern = RegExp(r'小\s*\d+');
    if (childPattern.hasMatch(note)) {
      return true;
    }

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

  // =========================================================================
  // 1. プレビュー用の「テキスト版」フォーマット生成
  // =========================================================================
  String _generatePrintFormat() {
    final Map<String, List<Reservation>> grouped = {};
    for (final r in reservations) {
      grouped.putIfAbsent(r.startTime, () => []).add(r);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    final buffer = StringBuffer();
    buffer.writeln('【${selectedDate.month}/${selectedDate.day} の予約一覧】\n');

    for (final timeKey in sortedKeys) {
      final resList = grouped[timeKey]!;
      for (int i = 0; i < resList.length; i++) {
        final r = resList[i];
        
        String details = '${r.people}名';
        if (r.course != null) {
          String shortCourseName;
          if (r.course!.contains('赤身天国コース')) shortCourseName = '赤天';
          else if (r.course!.contains('赤身天国＋クラシタ火山コース')) shortCourseName = '赤k';
          else if (r.course!.contains('赤身天国＋刺身スペシャルnew') || r.course!.contains('赤身天国＋刺身スペシャル')) shortCourseName = '赤さし';
          else if (r.course!.contains('アニバーサリーコース')) shortCourseName = 'アニバ';
          else if (r.course!.contains('ロイヤルコース')) shortCourseName = 'ロイヤル(赤さし)';
          else if (r.course!.contains('スペシャルコース')) shortCourseName = 'スぺ';
          else if (r.course!.contains('みらんコース') || r.course!.contains('旧みらんコース')) shortCourseName = 'みらん';
          else shortCourseName = r.course!.replaceAll('コース', '');
          
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
        if (i == 0) buffer.writeln('$timeKey : $details');
        else buffer.writeln('          : $details');
      }
    }
    return buffer.toString();
  }

  // =========================================================================
  // 2. Star PassPRNT用の「HTML版」フォーマット生成（レシートレイアウト）
  // =========================================================================
  String _generatePrintHtml() {
    final Map<String, List<Reservation>> grouped = {};
    for (final r in reservations) {
      grouped.putIfAbsent(r.startTime, () => []).add(r);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    final buffer = StringBuffer();
    buffer.writeln('<div style="font-family: sans-serif; width: 100%; color: #000; font-size: 1.4em; line-height: 1.3;">');
    buffer.writeln('<h2 style="text-align: center; border-bottom: 2px solid #000; padding-bottom: 8px; margin-bottom: 12px;">${selectedDate.month}/${selectedDate.day} 予約</h2>');
    buffer.writeln('<table style="width: 100%; border-collapse: collapse;">');

    for (final timeKey in sortedKeys) {
      final resList = grouped[timeKey]!;
      for (int i = 0; i < resList.length; i++) {
        final r = resList[i];
        
        String details = '${r.people}名';
        if (r.course != null) {
          String shortCourseName;
          if (r.course!.contains('赤身天国コース')) shortCourseName = '赤天';
          else if (r.course!.contains('赤身天国＋クラシタ火山コース')) shortCourseName = '赤k';
          else if (r.course!.contains('赤身天国＋刺身スペシャルnew') || r.course!.contains('赤身天国＋刺身スペシャル')) shortCourseName = '赤さし';
          else if (r.course!.contains('アニバーサリーコース')) shortCourseName = 'アニバ';
          else if (r.course!.contains('ロイヤルコース')) shortCourseName = 'ロイヤル(赤さし)';
          else if (r.course!.contains('スペシャルコース')) shortCourseName = 'スぺ';
          else if (r.course!.contains('みらんコース') || r.course!.contains('旧みらんコース')) shortCourseName = 'みらん';
          else shortCourseName = r.course!.replaceAll('コース', '');
          
          details += '<br>×$shortCourseName'; 
        }

        if (r.note != null && r.note!.isNotEmpty) {
          for (final keyword in slipKeyword) {
            if (r.note!.contains(keyword)) {
              String displayKeyword = keyword == 'ガラス箱' ? 'プレート' : keyword;
              details += '<br><span style="font-weight: bold; border: 1px solid #000; padding: 2px 4px;">$displayKeyword</span>';
              break;
            }
          }
        }
        
        buffer.writeln('<tr style="border-bottom: 1px dashed #666;">');
        if (i == 0) {
          buffer.writeln('<td style="vertical-align: top; padding: 8px 0; font-weight: bold; width: 30%;">[ $timeKey ]</td>');
        } else {
          buffer.writeln('<td style="vertical-align: top; padding: 8px 0; width: 30%;"></td>');
        }
        buffer.writeln('<td style="vertical-align: top; padding: 8px 0; text-align: left;">$details</td>');
        buffer.writeln('</tr>');
      }
    }
    buffer.writeln('</table>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }

  // =========================================================================
  // 3. Star PassPRNT（iOSアプリ）を起動する関数
  // =========================================================================
  Future<void> _printViaPassPRNT(BuildContext context, String htmlContent) async {
    try {
      // HTMLをURLエンコード
      final encodedHtml = Uri.encodeComponent(htmlContent);
      
      // Flutter Webで今開いているURL（自動復帰用）を取得
      final currentUrl = Uri.base.toString();
      final encodedReturnUrl = Uri.encodeComponent(currentUrl);

      // PassPRNTのURLスキームを構築
      final String urlStr = 'starpassprnt://v1/print/nopreview?html=$encodedHtml&url=$encodedReturnUrl';

      // ★ 修正：url_launcher は使わず、JavaScriptと全く同じ方法で強制ジャンプ！
      html.window.location.href = urlStr;
      
    } catch (e) {
      debugPrint('🚨 PassPRNT起動エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('印刷アプリを起動できませんでした: $e')),
        );
      }
    }
  }

  void _handlePrintAction(BuildContext context) async {
    // 画面に表示するプレビュー用テキスト
    final previewText = _generatePrintFormat();
    // 実際にプリンターに送るHTML
    final printHtml = _generatePrintHtml();
    
    if (!context.mounted) return;
    _showPrintPreview(context, previewText, printHtml);
  }

  // 省略: _showReservationDetails (変更なし)
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

  void _showPrintPreview(BuildContext context, String previewText, String printHtml) {
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
                previewText, // 画面上では今までの見やすいテキストを表示
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18, height: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('閉じる')
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.print),
              label: const Text('レジプリンターで印刷 (PassPRNT)'),
              onPressed: () async {
                // プレビューのダイアログを閉じる
                Navigator.pop(context); 
                // 裏で作っておいたHTMLデータをiOSアプリに渡して起動！
                await _printViaPassPRNT(context, printHtml); 
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