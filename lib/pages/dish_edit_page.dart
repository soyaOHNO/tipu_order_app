import 'package:flutter/material.dart';
import '../data/dish_data.dart';
import '../data/item_data.dart';
import '../models/dish.dart';
import '../models/item.dart';

class DishEditPage extends StatefulWidget {
  const DishEditPage({super.key});

  @override
  State<DishEditPage> createState() => _DishEditPageState();
}

class _DishEditPageState extends State<DishEditPage> {
  
  void _showDishDialog({Dish? existingDish}) {
    final isNew = existingDish == null;
    final nameController = TextEditingController(text: existingDish?.name ?? '');
    final memoController = TextEditingController(text: existingDish?.memo ?? '');
    
    // 計算タイプの初期値
    String selectedCalcType = existingDish?.calcType ?? 'proportion';

    // 編集中の食材要件マップをディープコピー
    Map<int, DishItemRequirement> tempRequiredItems = isNew
        ? {}
        : Map<int, DishItemRequirement>.from(
            existingDish.requiredItems.map((k, v) => MapEntry(k, DishItemRequirement(
              amountPerPerson: v.amountPerPerson,
              yieldPerUnit: v.yieldPerUnit,
              isTableFixed: v.isTableFixed,
            ))),
          );

    Item? selectedItemToAdd;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final availableItems = items
                .where((item) => item.alive && !tempRequiredItems.containsKey(item.id))
                .toList();

            return AlertDialog(
              title: Text(isNew ? '料理の新規追加' : '料理の編集'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: '料理名 (例: チョレギサラダ)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      
                      // ★追加：計算タイプのドロップダウン
                      DropdownButtonFormField<String>(
                        value: selectedCalcType,
                        decoration: const InputDecoration(labelText: '自動計算のタイプ', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'proportion', child: Text('人数比例・増減型 (サラダ・キムチ等)')),
                          DropdownMenuItem(value: 'per_person', child: Text('人数＝個数型 (タン・サンチュ等)')),
                          DropdownMenuItem(value: 'step', child: Text('段階・しきい値型 (冷麺・クッパ等)')),
                          DropdownMenuItem(value: 'per_table', child: Text('テーブル固定型 (肉ケーキ等)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setStateDialog(() => selectedCalcType = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: memoController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: '料理のメモ (自由記述)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      const Text('■ 必要な食材と個別レートの設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),

                      if (tempRequiredItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('食材が登録されていません', style: TextStyle(color: Colors.grey)),
                        ),

                      ...tempRequiredItems.entries.map((entry) {
                        final itemId = entry.key;
                        final req = entry.value;
                        final item = items.firstWhere(
                          (i) => i.id == itemId,
                          orElse: () => Item(id: itemId, name: '不明な食材(ID:$itemId)', minimum: '', category: '', supplier: '', orderType: OrderType.chief),
                        );

                        return Card(
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                      onPressed: () => setStateDialog(() => tempRequiredItems.remove(itemId)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // ① 必要量の入力
                                    Expanded(
                                      child: TextField(
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: '必要量 (gや枚数)', border: OutlineInputBorder(), isDense: true),
                                        controller: TextEditingController(text: req.amountPerPerson == 0 ? '' : req.amountPerPerson.toString()),
                                        onChanged: (val) => req.amountPerPerson = double.tryParse(val) ?? 0.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // ② 個別レート（仕込み分解数）の入力
                                    Expanded(
                                      child: TextField(
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: '1単位から取れる量', hintText: '例: 10.0', border: OutlineInputBorder(), isDense: true),
                                        controller: TextEditingController(text: req.yieldPerUnit == 1.0 && isNew ? '' : req.yieldPerUnit.toString()),
                                        onChanged: (val) => req.yieldPerUnit = double.tryParse(val) ?? 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                // ③ テーブル固定フラグのスイッチ（比例型のみ意味を持つが、いつでも設定可能）
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('この食材はテーブルごとに固定量にする', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                    Switch(
                                      value: req.isTableFixed,
                                      onChanged: (val) => setStateDialog(() => req.isTableFixed = val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<Item>(
                              isExpanded: true,
                              hint: const Text('食材を選択して追加'),
                              value: selectedItemToAdd,
                              items: availableItems.map((item) => DropdownMenuItem<Item>(value: item, child: Text(item.name))).toList(),
                              onChanged: (val) => setStateDialog(() => selectedItemToAdd = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedItemToAdd == null ? null : () {
                              setStateDialog(() {
                                tempRequiredItems[selectedItemToAdd!.id] = DishItemRequirement(amountPerPerson: 0.0, yieldPerUnit: 1.0);
                                selectedItemToAdd = null; 
                              });
                            },
                            child: const Text('追加'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isNew)
                  TextButton(
                    onPressed: () async {
                      dishes.removeWhere((d) => d.name == existingDish.name);
                      await saveDishesToLocal();
                      if (context.mounted) Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('料理削除', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(
                  onPressed: nameController.text.trim().isEmpty ? null : () async {
                    final finalName = nameController.text.trim();
                    final finalDish = Dish(
                      name: finalName,
                      calcType: selectedCalcType,
                      memo: memoController.text.trim(),
                      requiredItems: tempRequiredItems,
                    );

                    if (isNew) {
                      dishes.add(finalDish);
                    } else {
                      final idx = dishes.indexWhere((d) => d.name == existingDish.name);
                      if (idx != -1) dishes[idx] = finalDish;
                    }

                    await saveDishesToLocal();
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
    return Scaffold(
      appBar: AppBar(title: const Text('料理マスタ編集')),
      body: dishes.isEmpty
          ? const Center(child: Text('登録されている料理はありません', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: dishes.length,
              itemBuilder: (context, index) {
                final dish = dishes[index];
                String typeLabel = '比例型';
                if (dish.calcType == 'per_person') typeLabel = '人数個数型';
                if (dish.calcType == 'step') typeLabel = '段階型';
                if (dish.calcType == 'per_table') typeLabel = '卓固定型';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Chip(label: Text(typeLabel, style: const TextStyle(fontSize: 11)), backgroundColor: Colors.indigo.shade50),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dish.memo.isNotEmpty)
                            Text('メモ: ${dish.memo}', style: const TextStyle(color: Colors.blueGrey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('登録食材: ${dish.requiredItems.length} 種類', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey),
                    onTap: () => _showDishDialog(existingDish: dish),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDishDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新料理を追加'),
      ),
    );
  }
}