import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    // 画面表示時に実行される処理
    print(loginState.toString());
    print('Loading画面が表示されました');
    // FirebaseAuthからログイン状態を確認する
    WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.pushNamed(context, '/load');
    });
    
  }


  void checkLoginState() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ログインしている場合
      print('ログイン中: ${user.email}');
      setState(() {
        loginState = true;
      });
      Navigator.pushNamed(context, '/menu');
      
      
    } else {
      // ログインしていない場合
      print('ユーザーはログインしていません');
    }
  }

  @override
  Widget build(BuildContext context) {

    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.7; // ボタンの幅
    final double buttonHeight = screenSize.height * 0.1;  // ボタンの高さ

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
      Navigator.pushNamed(context, '/load');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('心拳オンラインへようこそ！'), // タイトルを追加
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight)
            ],
          ),
          
        ],
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  PlayButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed skill Select");
        
        Navigator.pushNamed(context, '/load');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_sharp, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "Play Game!",
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'Rounded', // フォントのスタイル（Roundedはデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}