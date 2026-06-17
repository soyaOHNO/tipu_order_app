import 'dart:math';
import 'package:flutter/material.dart';
import '../data/course_data.dart';
import '../data/dish_data.dart';
import '../models/course_recipe.dart';
import '../models/dish.dart';

class CourseEditPage extends StatefulWidget {
  const CourseEditPage({super.key});

  @override
  State<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends State<CourseEditPage> {
  
  void _showCourseDialog({CourseRecipe? existingCourse}) {
    final isNew = existingCourse == null;
    
    final nameController = TextEditingController(text: existingCourse?.courseName ?? '');
    final toretaController = TextEditingController(text: existingCourse?.toretaKeyword ?? '');
    
    // ★変更：Stringではなく料理の「IDリスト」として保持
    List<int> tempDishIds = isNew ? [] : List<int>.from(existingCourse.dishIds);

    Dish? selectedDishToAdd;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // 論理削除されていない（alive: true）料理のみ追加候補にする
            final availableDishes = dishes.where((d) => d.alive).toList();

            return AlertDialog(
              title: Text(isNew ? 'コースの新規追加' : 'コースの編集'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: '現場での呼び名 (例: 赤くら)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: toretaController,
                        decoration: const InputDecoration(labelText: 'Toretaでの正式なコース名', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      const Text('■ 含まれる料理リスト', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),

                      if (tempDishIds.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('料理が登録されていません', style: TextStyle(color: Colors.grey)),
                        ),
                      
                      ...tempDishIds.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dishId = entry.value;
                        // ★IDからマスタを引いて料理名を表示。見つからない場合は不明として表示。
                        final dish = dishes.firstWhere(
                          (d) => d.id == dishId, 
                          orElse: () => Dish(id: dishId, name: '不明な料理(ID:$dishId)', calcType: 'proportion', memo: '', requiredItems: {}, alive: false)
                        );

                        return Card(
                          color: dish.alive ? Colors.grey.shade50 : Colors.red.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              dish.name, 
                              style: TextStyle(fontWeight: FontWeight.bold, decoration: dish.alive ? null : TextDecoration.lineThrough)
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => setStateDialog(() => tempDishIds.removeAt(index)),
                            ),
                          ),
                        );
                      }),

                      const Divider(height: 32),
                      const Text('＋ 料理をこのコースに追加', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      if (availableDishes.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<Dish>(
                                isExpanded: true,
                                hint: const Text('料理を選択'),
                                value: selectedDishToAdd,
                                items: availableDishes.map((dish) => DropdownMenuItem<Dish>(value: dish, child: Text(dish.name))).toList(),
                                onChanged: (val) => setStateDialog(() => selectedDishToAdd = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedDishToAdd == null ? null : () {
                                setStateDialog(() {
                                  tempDishIds.add(selectedDishToAdd!.id); // ★名前ではなくIDを保存
                                  selectedDishToAdd = null;
                                });
                              },
                              child: const Text('追加'),
                            ),
                          ],
                        )
                      else
                        const Text('追加できる料理がマスタにありません', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isNew)
                  TextButton(
                    onPressed: () async {
                      // ★物理削除ではなく、論理削除(alive = false)に変更
                      final idx = courseRecipes.indexWhere((c) => c.id == existingCourse.id);
                      if (idx != -1) courseRecipes[idx].alive = false;
                      await saveCourseRecipesToLocal();
                      if (context.mounted) Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('コース削除', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(
                  onPressed: nameController.text.trim().isEmpty || toretaController.text.trim().isEmpty ? null : () async {
                    final finalName = nameController.text.trim();
                    final finalToreta = toretaController.text.trim();
                    
                    if (isNew) {
                      // ★新規IDの安全な自動発番
                      int newId = courseRecipes.isEmpty ? 1 : courseRecipes.map((c) => c.id).reduce(max) + 1;
                      final newCourse = CourseRecipe(
                        id: newId,
                        courseName: finalName,
                        toretaKeyword: finalToreta,
                        dishIds: tempDishIds,
                        alive: true,
                      );
                      courseRecipes.add(newCourse);
                    } else {
                      final idx = courseRecipes.indexWhere((c) => c.id == existingCourse.id);
                      if (idx != -1) {
                        courseRecipes[idx].courseName = finalName;
                        courseRecipes[idx].toretaKeyword = finalToreta;
                        courseRecipes[idx].dishIds = tempDishIds;
                      }
                    }

                    await saveCourseRecipesToLocal();
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
    // ★画面に表示するのは論理削除されていないコースのみ
    final activeCourses = courseRecipes.where((c) => c.alive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('コースレシピ編集')),
      body: activeCourses.isEmpty
          ? const Center(child: Text('登録されているコースはありません', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: activeCourses.length,
              itemBuilder: (context, index) {
                final course = activeCourses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    title: Text(course.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Toreta検索名: ${course.toretaKeyword}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          Text('登録料理: ${course.dishIds.length} 品', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey, size: 20),
                    onTap: () => _showCourseDialog(existingCourse: course),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新コースを追加'),
      ),
    );
  }
}