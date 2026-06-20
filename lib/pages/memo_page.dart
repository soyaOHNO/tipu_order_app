import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  // 端末のローカルからメモを読み込む
  Future<void> _loadMemo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _memoController.text = prefs.getString('local_memo') ?? '';
    });
  }

  // 入力するたびに端末のローカルへ保存する
  Future<void> _saveMemo(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_memo', text);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _memoController,
          maxLines: null, // 何行でも書けるようにする
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: '自由にメモを記入してください...',
            border: InputBorder.none, // 枠線を消してノートっぽくする
          ),
          onChanged: (text) {
            _saveMemo(text); // 文字を打つたびにローカル保存
          },
        ),
      ),
    );
  }
}