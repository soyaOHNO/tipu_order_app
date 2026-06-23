import 'package:flutter/material.dart';

import '../data/item_data.dart';
import '../models/item.dart';

class MasterEditPage extends StatefulWidget {
  const MasterEditPage({super.key});

  @override
  State<MasterEditPage> createState() => _MasterEditPageState();
}

class _MasterEditPageState extends State<MasterEditPage> {

  // 編集・追加ダイアログを表示する関数
  void _showEditDialog({Item? existingItem}) {
    final isNew = existingItem == null;
    
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    // ★変更：最低数を2つに分割
    final kitchenMinController = TextEditingController(text: existingItem?.kitchen_minimum ?? '');
    final backMinController = TextEditingController(text: existingItem?.back_minimum ?? '');
    
    final kitchenCatController = TextEditingController(text: existingItem?.kitchen_category ?? '');
    final backCatController = TextEditingController(text: existingItem?.back_category ?? '');
    final supController = TextEditingController(text: existingItem?.supplier ?? '');
    OrderType selectedType = existingItem?.orderType ?? OrderType.chief;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final deadItems = items.where((e) => !e.alive).toList();

            final existingKitchenCategories = items
                .where((e) => e.alive)
                .map((e) => e.kitchen_category.trim())
                .toSet()
                .where((c) => c.isNotEmpty)
                .toList();

            final existingBackCategories = items
                .where((e) => e.alive)
                .map((e) => e.back_category.trim())
                .toSet()
                .where((c) => c.isNotEmpty)
                .toList();

            return AlertDialog(
              title: Text(isNew ? '商品の追加' : '商品の編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNew && deadItems.isNotEmpty) ...[
                      DropdownButtonFormField<Item>(
                        decoration: const InputDecoration(
                          labelText: '♻️ 過去の削除データから自動入力',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color.fromARGB(255, 240, 248, 255),
                        ),
                        items: deadItems.map((item) => DropdownMenuItem(value: item, child: Text(item.name))).toList(),
                        onChanged: (Item? val) {
                          if (val != null) {
                            setStateDialog(() {
                              nameController.text = val.name;
                              kitchenMinController.text = val.kitchen_minimum; // ★変更
                              backMinController.text = val.back_minimum;       // ★変更
                              kitchenCatController.text = val.kitchen_category;
                              backCatController.text = val.back_category;
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
                    
                    const SizedBox(height: 16),
                    // --- キッチン側設定エリア ---
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          const Text('🍳 キッチン側の設定', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: kitchenCatController,
                            decoration: const InputDecoration(labelText: 'カテゴリ (例: 冷蔵庫(左上))', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                            onChanged: (text) => setStateDialog(() {}),
                          ),
                          const SizedBox(height: 6),
                          if (existingKitchenCategories.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 6.0,
                                runSpacing: 4.0,
                                children: existingKitchenCategories.map((category) {
                                  final isSelected = kitchenCatController.text.trim() == category;
                                  return ChoiceChip(
                                    label: Text(category, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                                    selected: isSelected,
                                    selectedColor: Colors.orange,
                                    onSelected: (bool selected) {
                                      setStateDialog(() {
                                        kitchenCatController.text = selected ? category : '';
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextField(
                            controller: kitchenMinController,
                            decoration: const InputDecoration(labelText: '最低数 (例: 2パック)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // --- 裏側設定エリア ---
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          const Text('📦 裏側の設定', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: backCatController,
                            decoration: const InputDecoration(labelText: 'カテゴリ (例: 裏棚A)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                            onChanged: (text) => setStateDialog(() {}),
                          ),
                          const SizedBox(height: 6),
                          if (existingBackCategories.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 6.0,
                                runSpacing: 4.0,
                                children: existingBackCategories.map((category) {
                                  final isSelected = backCatController.text.trim() == category;
                                  return ChoiceChip(
                                    label: Text(category, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                                    selected: isSelected,
                                    selectedColor: Colors.indigo,
                                    onSelected: (bool selected) {
                                      setStateDialog(() {
                                        backCatController.text = selected ? category : '';
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextField(
                            controller: backMinController,
                            decoration: const InputDecoration(labelText: '最低数 (例: 1箱)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),
                    TextField(
                      controller: supController,
                      decoration: const InputDecoration(labelText: '仕入先 (任意)', border: OutlineInputBorder()),
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
                            kitchen_minimum: existingItem.kitchen_minimum,
                            back_minimum: existingItem.back_minimum,
                            kitchen_category: existingItem.kitchen_category,
                            back_category: existingItem.back_category,
                            supplier: existingItem.supplier,
                            orderType: existingItem.orderType,
                            alive: false,
                          );
                        }
                        await saveItemMasterToLocal();
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

                    final kCat = kitchenCatController.text.trim();
                    final bCat = backCatController.text.trim();
                    final kMin = kitchenMinController.text.trim(); // ★変更
                    final bMin = backMinController.text.trim();    // ★変更

                    if (isNew) {
                      int deadIndex = items.indexWhere((e) => !e.alive && e.name == inputName);

                      if (deadIndex != -1) {
                        items[deadIndex] = Item(
                          id: items[deadIndex].id,
                          name: inputName,
                          kitchen_minimum: kMin, // ★変更
                          back_minimum: bMin,    // ★変更
                          kitchen_category: kCat,
                          back_category: bCat,
                          supplier: supController.text.trim(),
                          orderType: selectedType,
                          alive: true,
                        );
                      } else {
                        int newId = items.isEmpty ? 1 : items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
                        items.add(Item(
                          id: newId,
                          name: inputName,
                          kitchen_minimum: kMin, // ★変更
                          back_minimum: bMin,    // ★変更
                          kitchen_category: kCat,
                          back_category: bCat,
                          supplier: supController.text.trim(),
                          orderType: selectedType,
                          alive: true,
                        ));
                      }
                    } else {
                      int index = items.indexWhere((e) => e.id == existingItem.id);
                      if (index != -1) {
                        items[index] = Item(
                          id: existingItem.id, 
                          name: inputName,
                          kitchen_minimum: kMin, // ★変更
                          back_minimum: bMin,    // ★変更
                          kitchen_category: kCat,
                          back_category: bCat,
                          supplier: supController.text.trim(),
                          orderType: selectedType,
                          alive: true,
                        );
                      }
                    }

                    await saveItemMasterToLocal();
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
    final activeItems = items.where((item) => item.alive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品マスタ編集'),
      ),
      body: ListView.builder(
        itemCount: activeItems.length,
        itemBuilder: (context, index) {
          final item = activeItems[index];
          String catDisplay = '';
          // ★変更：一覧表示での見栄えを調整
          String minDisplay = '';
          
          if (item.kitchen_category.isNotEmpty && item.back_category.isNotEmpty) {
            catDisplay = '🫕:${item.kitchen_category} / 📦:${item.back_category}';
            minDisplay = '🫕:${item.kitchen_minimum} / 📦:${item.back_minimum}';
          } else if (item.kitchen_category.isNotEmpty) {
            catDisplay = '🫕:${item.kitchen_category}';
            minDisplay = '🫕:${item.kitchen_minimum}';
          } else {
            catDisplay = '📦:${item.back_category}';
            minDisplay = '📦:${item.back_minimum}';
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$catDisplay\n最低数: $minDisplay / ${item.orderType.name}'),
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
      ),
    );
  }
}