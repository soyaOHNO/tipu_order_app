import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

// ★ package_info_plus は使わず、PowerShellが作ったファイルを読み込む！
import '../config/app_config.dart'; 

Future<void> checkAppVersionAndReload() async {
  try {
    // ★ 物理的に埋め込まれた文字を読むだけなので、エラーになる確率0%！
    final currentAppVersion = AppConfig.version; 

    // Firestoreから最新バージョンを取得
    final doc = await FirebaseFirestore.instance.collection('app_info').doc('version').get();

    if (doc.exists && doc.data() != null) {
      final latestVersion = doc.data()!['latest_version'] as String?;

      if (latestVersion != null && latestVersion != currentAppVersion) {
        debugPrint('更新検知: 最新 $latestVersion (現在: $currentAppVersion)');
        if (kIsWeb) {
          html.window.location.reload(); 
        }
      }
    }
  } catch (e) {
    debugPrint('バージョンチェック失敗: $e');
  }
}