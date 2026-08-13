// flutter run -d chrome --dart-define-from-file=.env
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // バージョンチェックだけは先に行う（ここで引っかかるとリロードされるため）
  await checkAppVersionAndReload();
  
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  
  runApp(const MyApp());
}

// -----------------------------------------------------
// ★ スプラッシュ画面（ローディング画面）
// -----------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ここで裏側でデータを読み込む
  Future<void> _loadAllData() async {
    try {
      await loadItemMaster();
      await loadHallItems();
      await loadDishes();
      await loadCourseRecipes();
      
      // 読み込みが終わったら、本来のトップ画面（TopMenuPage）に遷移する
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TopMenuPage()),
        );
      }
    } catch (e) {
      debugPrint("データ読み込みエラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('マスタデータを読み込み中...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
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
      home: const SplashScreen(),
    );
  }
}

// -----------------------------------------------------
// ★ トップメニュー画面（StatefulWidgetに変更し、バージョン取得を追加）
// -----------------------------------------------------

class TopMenuPage extends StatefulWidget {
  const TopMenuPage({super.key});

  @override
  State<TopMenuPage> createState() => _TopMenuPageState();
}

class _TopMenuPageState extends State<TopMenuPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _fetchVersion();
  }

  // package_info_plus から現在のバージョン（例: 1.0.4+5）を取得
  Future<void> _fetchVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      if (mounted) {
        setState(() {
          if (version.isNotEmpty) {
            _appVersion = '$version+$buildNumber';
          } else {
            _appVersion = '1.0.?'; // 万が一取れなかった場合のフォールバック値
          }
        });
      }
    } catch (e) {
      debugPrint('バージョン情報の取得に失敗しました: $e');
      if (mounted) {
        setState(() {
          _appVersion = '1.0.4+5'; // エラー時も直接表示させる
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ちぷ発注管理'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 2,         
          crossAxisSpacing: 16,      
          mainAxisSpacing: 16,       
          children: [
            // 1. 発注管理（キッチン発注）
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

            // 2. ホール発注
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

            // 3. 予約状況
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
            
            // 4. キッチン発注品マスタ編集
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

            // 5. ホール商品マスタ編集
            MenuButton(
              title: 'ホール商品マスタ編集',
              icon: Icons.liquor,
              color: Colors.teal.shade400, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HallMasterEditPage()),
                );
              },
            ),

            // 6. 料理マスタ編集
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

            // 7. コースレシピ編集
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
          child: Text(
            _appVersion.isNotEmpty ? 'ver $_appVersion' : '',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
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