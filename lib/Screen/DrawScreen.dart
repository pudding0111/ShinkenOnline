import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class DrawScreen extends StatelessWidget {
  
  

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.7; // ボタンの幅
    final double buttonHeight = screenSize.height * 0.1;  // ボタンの高さ

    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    var appState = context.watch<MyAppState>();

    // Firestoreからデータを取得するFutureを作成
    Future<String?> getSkillName() async {
      // Firestoreインスタンスを取得
      var firestore = FirebaseFirestore.instance;

      // 'bronze'コレクションの'rooma2'ドキュメントの'skillName2'フィールドを取得
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await firestore.collection('OAuthToken').doc('currentToken').get();

      // ドキュメントが存在するかを確認し、skillName2を返す
      if (snapshot.exists) {
        return snapshot.data()?['token'] as String?;
      }

      return null; // データがない場合はnullを返す
    }

    Future<void> _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // ログイン成功後の処理
      print('User logged in: ${userCredential.user?.email}');
    } catch (e) {
      // エラー処理
      print('Login failed: $e');
    }
  }

    return Scaffold(
      appBar: AppBar(
        title: Text('OnlineBattleScreen'), // タイトルを追加
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('A random idea:'),
          Text(appState.current.asLowerCase),
          SizedBox(height: 20),

          // FutureBuilderを使ってFirestoreのデータを取得して表示
          FutureBuilder<String?>(
            future: getSkillName(), // Firestoreからデータを取得
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // データ取得中はローディングインジケータを表示
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                // エラーが発生した場合
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                // データが正常に取得できた場合、表示
                return Text('Skill Name: ');
              } else {
                // データが存在しない場合
                return Text('Skill Name not found');
              }
            },
          ),
          SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),

          // パスワード入力フィールド
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true, // パスワードを隠す
          ),
          SizedBox(height: 20),

          // ログインボタン
          ElevatedButton(
            onPressed: _signIn,
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}