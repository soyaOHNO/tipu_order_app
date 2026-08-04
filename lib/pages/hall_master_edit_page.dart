import 'package:flutter/material.dart';
import 'dart:math';

import '../data/hall_item_data.dart';
import '../models/hall_item.dart';

class HallMasterEditPage extends StatefulWidget {
  const HallMasterEditPage({super.key});

  @override
  State<HallMasterEditPage> createState() => _HallMasterEditPageState();
}

class _HallMasterEditPageState extends State<HallMasterEditPage> {
  // 編集・追加ダイアログを表示する関数
  void _showEditDialog({HallItem? existingItem}) {
    final isNew = existingItem == null;

    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final categoryController = TextEditingController(text: existingItem?.category ?? '');
    
    // 目標数
    final tOpenedController = TextEditingController(text: existingItem?.targetOpened.toString() ?? '0');
    final tUnopenedController = TextEditingController(text: existingItem?.targetUnopened.toString() ?? '0');
    final tStockController = TextEditingController(text: existingItem?.targetStock.toString() ?? '0');
    
    // 特殊発注ルール
    final threshController = TextEditingController(
      text: existingItem?.orderThreshold != null ? existingItem!.orderThreshold.toString() : ''
    );
    final unitController = TextEditingController(text: existingItem?.orderUnit.toString() ?? '1');
    final memoController = TextEditingController(text: existingItem?.memo ?? '');
    
    bool isSupply = existingItem?.isSupply ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // 既存のカテゴリ一覧を抽出（重複排除）
            final existingCategories = hallItems
                .map((e) => e.category.trim())
                .toSet()
                .where((c) => c.isNotEmpty)
                .toList();

            return AlertDialog(
              title: Text(isNew ? 'ホール商品の追加' : 'ホール商品の編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- 基本設定エリア ---
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '商品名 (例: ジンジャエール)'),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🏷 カテゴリ設定', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: categoryController,
                            decoration: const InputDecoration(labelText: 'カテゴリ (例: 冷蔵庫①-上段)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                            onChanged: (text) => setStateDialog(() {}),
                          ),
                          const SizedBox(height: 6),
                          if (existingCategories.isNotEmpty) ...[
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: existingCategories.map((category) {
                                final isSelected = categoryController.text.trim() == category;
                                return ChoiceChip(
                                  label: Text(category, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                                  selected: isSelected,
                                  selectedColor: Colors.blueAccent,
                                  onSelected: (bool selected) {
                                    setStateDialog(() {
                                      categoryController.text = selected ? category : '';
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- アイテム種別（トグル） ---
                    SwitchListTile(
                      title: const Text('補充・消耗品として扱う', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('チェックボックスのみで管理します'),
                      activeColor: Colors.deepOrange,
                      value: isSupply,
                      onChanged: (bool value) {
                        setStateDialog(() {
                          isSupply = value;
                        });
                      },
                    ),

                    // --- ドリンク・ストック設定エリア（補充品でない場合のみ表示） ---
                    if (!isSupply) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🎯 目標数設定', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: tOpenedController, decoration: const InputDecoration(labelText: '開栓の目標', border: OutlineInputBorder(), filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(controller: tUnopenedController, decoration: const InputDecoration(labelText: '未開栓の目標', border: OutlineInputBorder(), filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(controller: tStockController, decoration: const InputDecoration(labelText: 'ストックの目標 (冷蔵庫③など)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white), keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- 特殊発注ルールエリア ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚙️ 特殊発注ルール (生マッコリ等)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: threshController, decoration: const InputDecoration(labelText: '発注トリガー (〇本以下)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(controller: unitController, decoration: const InputDecoration(labelText: '発注単位 (〇本ごと)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextField(
                      controller: memoController,
                      decoration: const InputDecoration(labelText: '発注画面への警告メモ (任意)', border: OutlineInputBorder()),
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
                          content: Text('${existingItem.name} を一覧から完全に削除しますか？\n（連携しているsameIdがある場合は注意してください）'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        hallItems.removeWhere((e) => e.id == existingItem.id);
                        _updateListsAndSave();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('削除', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final inputName = nameController.text.trim();
                    final inputCat = categoryController.text.trim();
                    if (inputName.isEmpty || inputCat.isEmpty) return;

                    int tOp = int.tryParse(tOpenedController.text) ?? 0;
                    int tUn = int.tryParse(tUnopenedController.text) ?? 0;
                    int tSt = int.tryParse(tStockController.text) ?? 0;
                    int? thresh = int.tryParse(threshController.text);
                    int unit = int.tryParse(unitController.text) ?? 1;
                    if (unit < 1) unit = 1;

                    if (isNew) {
                      // IDは1000番台で連番を取る
                      int newId = hallItems.isEmpty ? 1000 : hallItems.map((e) => e.id).reduce(max) + 1;
                      hallItems.add(HallItem(
                        id: newId,
                        name: inputName,
                        category: inputCat,
                        isSupply: isSupply,
                        targetOpened: isSupply ? 0 : tOp,
                        targetUnopened: isSupply ? 0 : tUn,
                        targetStock: isSupply ? 0 : tSt,
                        orderThreshold: isSupply ? null : thresh,
                        orderUnit: isSupply ? 1 : unit,
                        memo: memoController.text.trim(),
                      ));
                    } else {
                      int index = hallItems.indexWhere((e) => e.id == existingItem.id);
                      if (index != -1) {
                        // sameIdの連携は保持したまま更新する
                        hallItems[index] = HallItem(
                          id: existingItem.id,
                          sameId: existingItem.sameId,
                          name: inputName,
                          category: inputCat,
                          isSupply: isSupply,
                          targetOpened: isSupply ? 0 : tOp,
                          targetUnopened: isSupply ? 0 : tUn,
                          targetStock: isSupply ? 0 : tSt,
                          orderThreshold: isSupply ? null : thresh,
                          orderUnit: isSupply ? 1 : unit,
                          memo: memoController.text.trim(),
                        );
                      }
                    }

                    _updateListsAndSave();
                    if (context.mounted) Navigator.pop(context);
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

  // リストを更新して保存・再描画する処理
  void _updateListsAndSave() async {
    // 表示用のモックリストも同期させる
    mockDrinkItems = hallItems.where((item) => !item.isSupply).toList();
    mockSupplyItems = hallItems.where((item) => item.isSupply).toList();
    
    await saveHallItemsToLocal();
    setState(() {}); // 画面を再描画
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホール商品マスタ編集'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: hallItems.length,
        itemBuilder: (context, index) {
          final item = hallItems[index];
          
          String subInfo = '';
          if (item.isSupply) {
            subInfo = '📦 補充・消耗品';
          } else {
            List<String> targets = [];
            if (item.targetOpened > 0) targets.add('開:${item.targetOpened}');
            if (item.targetUnopened > 0) targets.add('未:${item.targetUnopened}');
            if (item.targetStock > 0) targets.add('庫:${item.targetStock}');
            subInfo = '目標: ${targets.join(' / ')}';
            if (item.sameId != null) subInfo += ' (連携ID: ${item.sameId})';
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('📁 ${item.category}\n$subInfo'),
              isThreeLine: true,
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
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}