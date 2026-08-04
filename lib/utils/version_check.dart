import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:html' as html;

Future<void> checkAppVersionAndReload() async {
  try {
    // ★ pubspec.yaml に書かれているバージョンを自動取得！
    final packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion = packageInfo.version; 

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