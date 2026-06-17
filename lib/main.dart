// flutter run -d windows
import 'package:flutter/material.dart';
import 'pages/order_home_page.dart';
import 'data/item_data.dart';
import 'pages/master_edit_page.dart';
import 'pages/reservation_page.dart';
import 'data/course_data.dart';
import 'pages/course_edit_page.dart';
import 'data/dish_data.dart';
import 'pages/dish_edit_page.dart';

void main() async {
  // 非同期処理をmain関数で実行するための必須コード
  WidgetsFlutterBinding.ensureInitialized();
  
  // アプリ起動時にマスタデータを読み込む
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
      home: const TopMenuPage(), // 起動時はトップメニュー画面を表示
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
            // 発注管理ボタン
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

            // 予約状況ボタン
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

            // マスタ再読み込みボタン
            MenuButton(
              title: '各マスタを書き換えたらここを押して反映',
              icon: Icons.sync,
              color: Colors.blue,
              onTap: () async {
                // CSVデータを再読み込みして items を上書きする
                await loadItemMaster();
                await loadDishes();
                await loadCourseRecipes();
                
                // 読み込み完了をスナックバーで通知
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
            
            // 発注品マスタ編集ボタン
            MenuButton(
              title: '発注品マスタ編集',
              icon: Icons.edit_note,
              color: Colors.green, // 色も有効な感じのグリーンへ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MasterEditPage()),
                );
              },
            ),

            // コースレシピ編集ボタン
            MenuButton(
              title: 'コースレシピ編集',
              icon: Icons.restaurant_menu,
              color: Colors.teal, // おしゃれな青緑色に
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseEditPage()),
                );
              },
            ),

            // 料理マスタ編集ボタン
            MenuButton(
              title: '料理マスタ編集',
              icon: Icons.lunch_dining,
              color: Colors.deepOrange, // 美味しそうなディープオレンジ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DishEditPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// メニュー用のカスタムボタン（再利用しやすくパーツ化）
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