import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../data/item_data.dart';
import '../models/item.dart';

class MasterEditPage extends StatefulWidget {
  const MasterEditPage({super.key});

  @override
  State<MasterEditPage> createState() => _MasterEditPageState();
}

class _MasterEditPageState extends State<MasterEditPage> {
  Future<void> _saveMasterToCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final masterDir = Directory('${directory.path}/みらんちぷ発注/マスタ');
    if (!await masterDir.exists()) {
      await masterDir.create(recursive: true);
    }
    
    final file = File('${masterDir.path}/item_master.csv');
    final buffer = StringBuffer();
    
    // ★ヘッダーに alive 追加
    buffer.writeln('id,name,minimum,category,supplier,orderType,alive');
    
    for (final item in items) {
      // ★ alive を書き込む
      buffer.writeln('${item.id},${item.name},${item.minimum},${item.category},${item.supplier},${orderTypeToString(item.orderType)},${item.alive}');
    }
    
    await file.writeAsString(buffer.toString());
  }

  // 編集・追加ダイアログを表示する関数
  void _showEditDialog({Item? existingItem}) {
    final isNew = existingItem == null;
    
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final minController = TextEditingController(text: existingItem?.minimum ?? '');
    final catController = TextEditingController(text: existingItem?.category ?? '');
    final supController = TextEditingController(text: existingItem?.supplier ?? '');
    OrderType selectedType = existingItem?.orderType ?? OrderType.chief;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // ★削除済みのアイテム（alive == false）のリストを取得
            final deadItems = items.where((e) => !e.alive).toList();

            return AlertDialog(
              title: Text(isNew ? '商品の追加' : '商品の編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ★ 新規追加時かつ、削除済みデータが存在する場合のみ「復元メニュー」を表示
                    if (isNew && deadItems.isNotEmpty) ...[
                      DropdownButtonFormField<Item>(
                        decoration: const InputDecoration(
                          labelText: '♻️ 過去の削除データから自動入力',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color.fromARGB(255, 240, 248, 255), // 薄い青色で目立たせる
                        ),
                        items: deadItems.map((item) => DropdownMenuItem(value: item, child: Text(item.name))).toList(),
                        onChanged: (Item? val) {
                          if (val != null) {
                            // 過去のデータで入力欄を自動フィル！
                            setStateDialog(() {
                              nameController.text = val.name;
                              minController.text = val.minimum;
                              catController.text = val.category;
                              supController.text = val.supplier;
                              selectedType = val.orderType;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '商品名 (例: チャンジャ)'),
                    ),
                    TextField(
                      controller: minController,
                      decoration: const InputDecoration(labelText: '最低数 (例: 2パック)'),
                    ),
                    TextField(
                      controller: catController,
                      decoration: const InputDecoration(labelText: 'カテゴリ (例: 冷蔵庫(左上))'),
                    ),
                    DropdownButtonFormField<OrderType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: '発注担当'),
                      items: OrderType.values.map((type) {
                        String label = type.name;
                        if (type == OrderType.chief) label = '主任さん';
                        if (type == OrderType.part) label = 'パートさん';
                        if (type == OrderType.owner) label = 'とも兄さん';
                        if (type == OrderType.regular) label = '定期発注';
                        if (type == OrderType.preparation) label = '仕込み';
                        return DropdownMenuItem(value: type, child: Text(label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedType = val);
                      },
                    ),
                    TextField(
                      controller: supController,
                      decoration: const InputDecoration(labelText: '仕入先 (任意)'),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isNew) 
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('削除の確認'),
                          content: Text('${existingItem.name} を一覧から削除しますか？\n（過去の発注履歴には影響しません）'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        int index = items.indexWhere((e) => e.id == existingItem.id);
                        if (index != -1) {
                          items[index] = Item(
                            id: existingItem.id,
                            name: existingItem.name,
                            minimum: existingItem.minimum,
                            category: existingItem.category,
                            supplier: existingItem.supplier,
                            orderType: existingItem.orderType,
                            alive: false, // 論理削除
                          );
                        }
                        await _saveMasterToCsv();
                        if (context.mounted) Navigator.pop(context); 
                        setState(() {}); 
                      }
                    },
                    child: const Text('削除', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final inputName = nameController.text.trim();
                    if (inputName.isEmpty) return; 

                    if (isNew) {
                      // ★ 追加処理：入力された名前が「削除済みアイテム」の中に存在するかチェック
                      int deadIndex = items.indexWhere((e) => !e.alive && e.name == inputName);

                      if (deadIndex != -1) {
                        // 過去に同じ名前のものがあれば、そのIDを再利用して「復活」させる！
                        items[deadIndex] = Item(
                          id: items[deadIndex].id, // 過去のIDをそのまま引き継ぐ
                          name: inputName,
                          minimum: minController.text.trim(),
                          category: catController.text.trim(),
                          supplier: supController.text.trim(),
                          orderType: selectedType,
                          alive: true, // 復活！
                        );
                      } else {
                        // 全く新しい商品名なら、新規IDを発行する
                        int newId = items.isEmpty ? 1 : items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
                        items.add(Item(
                          id: newId,
                          name: inputName,
                          minimum: minController.text.trim(),
                          category: catController.text.trim(),
                          supplier: supController.text.trim(),
                          orderType: selectedType,
                          alive: true,
                        ));
                      }
                    } else {
                      // 既存アイテムの編集処理（変更なし）
                      int index = items.indexWhere((e) => e.id == existingItem.id);
                      if (index != -1) {
                        items[index] = Item(
                          id: existingItem.id, 
                          name: inputName,
                          minimum: minController.text.trim(),
                          category: catController.text.trim(),
                          supplier: supController.text.trim(),
                          orderType: selectedType,
                          alive: true,
                        );
                      }
                    }

                    await _saveMasterToCsv();
                    if (context.mounted) Navigator.pop(context);
                    setState(() {}); 
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★ 画面に表示するのは alive が true のものだけに絞り込む
    final activeItems = items.where((item) => item.alive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品マスタ編集'),
      ),
      body: ListView.builder(
        itemCount: activeItems.length,
        itemBuilder: (context, index) {
          final item = activeItems[index]; // activeItemsから取り出す
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item.category} / 最低: ${item.minimum} / ${item.orderType.name}'),
              trailing: const Icon(Icons.edit, color: Colors.grey),
              onTap: () => _showEditDialog(existingItem: item),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('商品を追加'),
      ),
    );
  }
}