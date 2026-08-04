import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/reservation.dart';

Future<List<Reservation>> fetchTodayReservations(String dateString) async {
  // PythonのCloud Functions APIエンドポイント
  final String apiUrl = 'https://us-central1-tipu-order.cloudfunctions.net/get_reservations?date=$dateString';
  
  // ★ .envファイルから「SECRET_API_KEY」を取得
  final String apiKey = dotenv.env['SECRET_API_KEY'] ?? ''; 

  try {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'X-API-KEY': apiKey,
      },
    );

    if (response.statusCode == 200) {
      // 日本語の文字化けを防ぐために utf8.decode を挟む
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Reservation.fromJson(json)).toList();
    } else {
      print('Toreta API エラー: ステータスコード ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Toreta データの取得に失敗しました: $e');
    return [];
  }
}