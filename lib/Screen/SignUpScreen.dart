import 'package:flutter/material.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/State/mainState.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _errorMessage = '';

  
  @override
  Widget build(BuildContext context) {

    var LoginState = context.watch<LoginStateNotifier>();

    

    Future<void> _createAccount() async {
    
    try {
      String email = _idController.text.trim() + "@newtesttest.com";
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password:_passwordController.text,
      );
      // アカウント作成成功
      LoginState.logIn();
      loginState = true;
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        uid = user.uid; // UID を取得
        print('ログイン中: ${user.email}');
        setState(() {
          loginState = true;
        });  
      } else {
        // ログインしていない場合
        print('ユーザーはログインしていません');
      }
      context.go('/nameInput');

    
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("アカウント作成成功！"),
      ));
      // 他の画面に遷移するなどの処理を追加できます
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message!;
      });
    }
  }

  void setMyInfo() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('myFriendId', _idController.text);
    prefs.setString('myRank', 'bronze1');
    prefs.setInt('myRankCount', 0);
    prefs.setStringList('myOwnSkillList', ['No1','No2','No3','No4','No5','No6','No7','No8','No9','No10',]);
    prefs.setInt('myRockCount', 0);
    prefs.setInt('myScissorCount', 0);
    prefs.setInt('myPaperCount', 0);
    prefs.setInt('myBattleCount', 0);
    prefs.setInt('myWinCount', 0);
    prefs.setInt('myWinStreak', 0);
    prefs.setInt('myHonestCount', 0);
    prefs.setInt('myGachaPoint', 5000);
    prefs.setInt('myLevel', 1);
    prefs.setInt('myLevelExp', 0);
    prefs.setInt('myTrophy', 0);
    prefs.setString('myFavoriteSkillNo', 'No1');
    prefs.setString('myFavoriteSkillName', '硬い拳');
  }

    return Scaffold(
      appBar: AppBar(
        title: Text('アカウント新規作成'), // タイトルを追加
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: "ID(フレンドコード)を決めてください。"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "パスワードを決めてください。"),
              obscureText: true,
            ),
            
            Text('パスワードを設定するとアカウントの復元、移行が可能になります。\nパスワードの変更は後からでもできます。'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => {setMyInfo(), _createAccount()},
              child: Text("アカウント作成"),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}