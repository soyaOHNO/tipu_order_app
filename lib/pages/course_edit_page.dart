import 'package:flutter/material.dart';
import '../data/course_data.dart';
import '../data/dish_data.dart'; // ★追加：料理データを参照するためにインポート
import '../models/course_recipe.dart';
import '../models/dish.dart';

class CourseEditPage extends StatefulWidget {
  const CourseEditPage({super.key});

  @override
  State<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends State<CourseEditPage> {
  
  // コースの追加・編集ダイアログ
  void _showCourseDialog({CourseRecipe? existingCourse}) {
    final isNew = existingCourse == null;
    
    final nameController = TextEditingController(text: existingCourse?.courseName ?? '');
    // ★変更：食材ではなく「料理名（String）のリスト」を一時コピーして保持する
    List<String> tempDishNames = isNew 
        ? [] 
        : List<String>.from(existingCourse.dishNames);

    // 追加用のドロップダウンで選択されている料理
    Dish? selectedDishToAdd;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // ドロップダウンの選択肢には、料理マスタ（dishes）のデータをそのまま使う
            final availableDishes = dishes;

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
                        decoration: const InputDecoration(
                          labelText: 'コース名 (例: 歓送迎会プラン)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '■ 含まれる料理（メニュー）リスト',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // 1. すでに登録されている料理のリスト表示
                      if (tempDishNames.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('料理が登録されていません', style: TextStyle(color: Colors.grey)),
                        ),
                      
                      ...tempDishNames.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dishName = entry.value;

                        return Card(
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            title: Text(dishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () {
                                // コースから料理を外す
                                setStateDialog(() => tempDishNames.removeAt(index));
                              },
                            ),
                          ),
                        );
                      }),

                      const Divider(height: 32),
                      const Text('＋ 料理をこのコースに追加', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // 2. 料理を追加するためのドロップダウンエリア
                      if (availableDishes.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<Dish>(
                                isExpanded: true,
                                hint: const Text('料理を選択'),
                                value: selectedDishToAdd,
                                items: availableDishes.map((dish) {
                                  return DropdownMenuItem<Dish>(value: dish, child: Text(dish.name));
                                }).toList(),
                                onChanged: (val) {
                                  setStateDialog(() => selectedDishToAdd = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedDishToAdd == null ? null : () {
                                setStateDialog(() {
                                  // コースに料理名を追加
                                  tempDishNames.add(selectedDishToAdd!.name);
                                  selectedDishToAdd = null; // 選択をリセット
                                });
                              },
                              child: const Text('追加'),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          '追加できる料理がマスタにありません。\n先に「料理マスタ編集」から料理を作ってください。', 
                          style: TextStyle(color: Colors.grey, fontSize: 13)
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isNew) // 既存コースなら削除ボタン
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('コースの削除'),
                          content: Text('${existingCourse.courseName} を削除しますか？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        courseRecipes.removeWhere((c) => c.courseName == existingCourse.courseName);
                        await saveCourseRecipesToLocal();
                        if (context.mounted) Navigator.pop(context);
                        setState(() {});
                      }
                    },
                    child: const Text('コース削除', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: nameController.text.trim().isEmpty ? null : () async {
                    final finalName = nameController.text.trim();
                    
                    if (isNew) {
                      courseRecipes.add(CourseRecipe(
                        courseName: finalName,
                        dishNames: tempDishNames, // ★料理名リストを保存
                      ));
                    } else {
                      final idx = courseRecipes.indexWhere((c) => c.courseName == existingCourse.courseName);
                      if (idx != -1) {
                        courseRecipes[idx] = CourseRecipe(
                          courseName: finalName,
                          dishNames: tempDishNames,
                        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('コースレシピ編集'),
      ),
      body: courseRecipes.isEmpty
          ? const Center(child: Text('登録されているコースはありません', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: courseRecipes.length,
              itemBuilder: (context, index) {
                final course = courseRecipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    title: Text(course.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('登録料理: ${course.dishNames.length} 品'), // ★ 〇品という表記に変更
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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