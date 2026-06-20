// flutter run -d chrome
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/order_home_page.dart';
import 'data/item_data.dart';
import 'pages/master_edit_page.dart';
import 'pages/reservation_page.dart';
import 'data/course_data.dart';
import 'pages/course_edit_page.dart';
import 'data/dish_data.dart';
import 'pages/dish_edit_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ★追加：Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ★追加：Firestoreのローカルキャッシュを有効化（オフライン対応）
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  
  await loadItemMaster(); 
  await loadDishes();
  await loadCourseRecipes();
  
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'みらんちぷ業務管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const TopMenuPage(),
    );
  }
}

class TopMenuPage extends StatelessWidget {
  const TopMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('みらんちぷ業務管理'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 2,         
          crossAxisSpacing: 16,      
          mainAxisSpacing: 16,       
          children: [
            // 1. 発注管理（そのままオレンジ）
            MenuButton(
              title: '発注管理',
              icon: Icons.assignment,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHomePage()),
                );
              },
            ),

            // 2. 予約状況（そのままブルー）
            MenuButton(
              title: '明日の予約状況\n(トレタ連携デモ)',
              icon: Icons.book_online,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReservationPage()),
                );
              },
            ),

            // 3. キャッシュクリア（赤色・確認ダイアログ付き）
            MenuButton(
              title: 'キャッシュクリア\n(マスタ再読み込み)',
              icon: Icons.cleaning_services,
              color: Colors.redAccent,
              onTap: () async {
                // 間違えて押さないように確認ダイアログを表示
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('キャッシュクリアの確認'),
                    content: const Text('端末に保存されているメモやキャッシュを消去し、マスタデータを最新の状態に再読み込みします。\n（※現在入力中の発注データは消えません）\n\n本当によろしいですか？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('実行', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );

                if (confirm != true) return; // キャンセルされたら処理を中断

                // ① ローカルのキャッシュ（メモや日付データなど）を全て削除
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // ② 各マスタデータをFirestoreから再読み込み
                await loadItemMaster();
                await loadDishes();
                await loadCourseRecipes();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('キャッシュをクリアし、マスタデータを最新にしました！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            
            // 4. 発注品マスタ編集（マスタ系：爽やかな明るい薄緑「shade300」）
            MenuButton(
              title: '発注品マスタ編集',
              icon: Icons.edit_note,
              color: Colors.lightGreen.shade600, // ★明るい薄緑
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MasterEditPage()),
                );
              },
            ),

            // 5. 料理マスタ編集（マスタ系：標準的な中間の黄緑「shade500」）
            // ★目線のフロー（食材➔料理➔コース）に合わせるため、5番と6番の配置順を入れ替えました！
            MenuButton(
              title: '料理マスタ編集',
              icon: Icons.lunch_dining,
              color: Colors.lightGreen.shade500, // ★中間の黄緑
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DishEditPage()),
                );
              },
            ),

            // 6. コースレシピ編集（マスタ系：少し深い落ち着いた緑「shade700」）
            MenuButton(
              title: 'コースレシピ編集',
              icon: Icons.restaurant_menu,
              color: Colors.lightGreen.shade400, // ★深い引き締まった緑
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseEditPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}