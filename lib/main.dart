// flutter run -d chrome --dart-define-from-file=.env
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'pages/order_home_page.dart';
import 'data/item_data.dart';
import 'pages/master_edit_page.dart';
import 'pages/reservation_page.dart';
import 'data/course_data.dart';
import 'pages/course_edit_page.dart';
import 'data/dish_data.dart';
import 'pages/dish_edit_page.dart';
import 'pages/hall_order_page.dart';
import 'data/hall_item_data.dart';
import 'pages/hall_master_edit_page.dart';
import 'utils/version_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // アプリ起動時にバージョンチェックを実施
  await checkAppVersionAndReload();
  
  // Firestoreのローカルキャッシュを有効化（オフライン対応）
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  
  await loadItemMaster(); 
  await loadHallItems();
  await loadDishes();
  await loadCourseRecipes();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'みらんちぷ発注管理',
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
        title: const Text('みらんちぷ発注管理'),
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
              title: 'キッチン発注',
              icon: Icons.assignment,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHomePage()),
                );
              },
            ),

            // 2. ホール発注（紫）
            MenuButton(
              title: 'ホール発注',
              icon: Icons.assignment,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HallOrderHomePage()),
                );
              },
            ),

            // 3. 予約状況（そのままブルー）
            MenuButton(
              title: '予約確認',
              icon: Icons.book_online,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReservationPage()),
                );
              },
            ),
            
            // 4. 発注品マスタ編集（マスタ系：爽やかな明るい薄緑「shade600」）
            MenuButton(
              title: 'キッチン発注品マスタ編集',
              icon: Icons.edit_note,
              color: Colors.lightGreen.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MasterEditPage()),
                );
              },
            ),

            // 5. ホール商品マスタ編集（★新規追加：ホールを意識したブルーグリーン）
            MenuButton(
              title: 'ホール商品マスタ編集',
              icon: Icons.liquor, // ドリンクをイメージするアイコン
              color: Colors.teal.shade400, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HallMasterEditPage()),
                );
              },
            ),

            // 6. 料理マスタ編集（マスタ系：標準的な中間の黄緑「shade500」）
            MenuButton(
              title: '料理マスタ編集',
              icon: Icons.lunch_dining,
              color: Colors.lightGreen.shade500,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DishEditPage()),
                );
              },
            ),

            // 7. コースレシピ編集（マスタ系：少し深い落ち着いた緑「shade400」）
            MenuButton(
              title: 'コースレシピ編集',
              icon: Icons.restaurant_menu,
              color: Colors.lightGreen.shade400,
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