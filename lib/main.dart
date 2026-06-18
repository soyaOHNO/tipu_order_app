// flutter run -d windows
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ★追加
import 'firebase_options.dart'; // ★追加 (flutterfire configureで生成されたファイル)

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
  
  await loadItemMaster(); 
  await loadDishes();
  await loadCourseRecipes();
  
  runApp(const MyApp());
}

// ...以下、既存の MyApp や TopMenuPage のコードはそのまま

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

            // 3. マスタ再読み込み（同期システム：灰色）
            MenuButton(
              title: '各マスタを書き換えたらここを押して反映',
              icon: Icons.sync,
              color: Colors.grey,
              onTap: () async {
                await loadItemMaster();
                await loadDishes();
                await loadCourseRecipes();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('マスタデータを最新のCSVから読み込みました！'),
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