import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Screen/SkillScreen.dart';
import 'package:flutter_application_1/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/State/mainState.dart';
import 'package:shared_preferences/shared_preferences.dart';


var passwordState = true;



class IDLoginScreen extends StatefulWidget {
  @override
  _IDLoginScreenState createState() => _IDLoginScreenState();
}

class _IDLoginScreenState extends State<IDLoginScreen> {
  bool mailLogin = false;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 画面表示時に実行される処理
    print('IDLogin画面が表示されました');
  }

  Future<dynamic> getFieldFromFirebase({
  required String field,      // 読み取るフィールド名
  }) async {
    try {
      // Firebaseのドキュメント参照
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('newUserData').doc(uid);

      // ドキュメントを取得
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        print('field$field: ${docSnapshot.get(field)}');
        // フィールドの値を取得して返す
        return docSnapshot.get(field);
      } else {
        print("Document does not exist.");
        return null;
      }
    } catch (e) {
      print("Error reading field from Firebase: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    

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

    Future<void> _loadUserData(String uid, SharedPreferences prefs) async {
  try {
    final battleCount = await getFieldFromFirebase(field: 'battleCount');
    final gachaPoint = await getFieldFromFirebase(field: 'gachaPoint');
    final level = await getFieldFromFirebase(field: 'level');
    final exp = await getFieldFromFirebase(field: 'exp');
    final name = await getFieldFromFirebase(field: 'name');
    final friendId = await getFieldFromFirebase(field: 'id');
    final paperCount = await getFieldFromFirebase(field: 'paperCount');
    final rockCount = await getFieldFromFirebase(field: 'rockCount');
    final scissorCount = await getFieldFromFirebase(field: 'scissorCount');
    final rank = await getFieldFromFirebase(field: 'rank');
    final rankCount = await getFieldFromFirebase(field: 'rankCount');
    final trophy = await getFieldFromFirebase(field: 'trophy');
    final winCount = await getFieldFromFirebase(field: 'winCount');
    final winStreak = await getFieldFromFirebase(field: 'winStreak');
    final skillList = await getFieldFromFirebase(field: 'skillList') as List<dynamic>;
    final honestCount = await getFieldFromFirebase(field: 'honestCount');
    final skillUseList = await getFieldFromFirebase(field: 'skillUseList') as List<dynamic>;
    final skillActiveList = await getFieldFromFirebase(field: 'skillActiveList') as List<dynamic>;

    List<String> stringSkillList = skillList.map((item) => item.toString()).toList();
    List<int> intSkillUseList = skillUseList.map((item) {
      if (item is int) {
        return item; // すでに int 型の場合そのまま
      } else if (item is String) {
        return int.tryParse(item) ?? 0; // String 型の場合、数値に変換
      } else {
        return 0; // その他の型の場合はデフォルト値
      }
    }).toList();
    List<int> intSkillActiveList = skillActiveList.map((item) {
      if (item is int) {
        return item; // すでに int 型の場合そのまま
      } else if (item is String) {
        return int.tryParse(item) ?? 0; // String 型の場合、数値に変換
      } else {
        return 0; // その他の型の場合はデフォルト値
      }
    }).toList();
    await prefs.setString('myName', name as String);
    await prefs.setString('myRank', rank as String);
    await prefs.setInt('myRankCount', rankCount as int);
    await prefs.setInt('myTrophy', trophy as int);
    await prefs.setStringList('myOwnSkillList', stringSkillList); 
    await prefs.setInt('myPaperCount', paperCount as int);
    await prefs.setInt('myRockCount', rockCount as int);
    await prefs.setInt('myScissorCount', scissorCount as int);
    await prefs.setInt('myBattleCount', battleCount as int);
    await prefs.setInt('myWinCount', winCount as int);
    await prefs.setInt('myWinStreak', winStreak as int);
    await prefs.setInt('myHonestCount', honestCount as int);
    await prefs.setInt('myGachaPoint', gachaPoint as int);
    await prefs.setInt('myLevel', level as int);
    await prefs.setInt('myLevelExp', exp as int);
    await prefs.setString('myFriendId', friendId as String);
    for (int i = 0; i < skills.length; i++) {
      print(i);
      await prefs.setInt('mySkillCount_No${i + 1}', intSkillUseList[i]);
      await prefs.setInt('mySkillActive_No${i + 1}', intSkillActiveList[i]);
    }
    print('No1の使用回数${prefs.getInt('mySkillCount_No1') ?? 404}');
  } catch (e) {
    print('Data loading failed: $e');
  }
}

    Future<void> _signIn() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  try {
    UserCredential userCredential;
    if (mailLogin) {
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _idController.text + '@newtesttest.com',
        password: _passwordController.text,
      );
    }

    // ログイン成功後
    print('User logged in: ${userCredential.user?.email}');
    uid = userCredential.user!.uid;
    await _loadUserData(uid, prefs); // データ取得を呼び出し
    context.read<LoginStateNotifier>().logIn();
    Navigator.pop(context, true);
    print("Login success!!");
  } catch (e) {
    // エラー処理
    setState(() {
      passwordState = false;
    });
    print('Login failed: $e');
  }
}
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        leading: BackButton(), 
        title: Text('ログイン画面'), // タイトルを追加
      ),
      body: 
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: () => {setState(() {
            mailLogin = !mailLogin;
          })}, child: Text(mailLogin ? 'メール認証をしていない方' : 'メール認証がお済みの方')),
          if (mailLogin)
          Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'メールアドレスを入力してください',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // パスワード入力フィールド
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Passwordを入力してください',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // パスワードを隠す
            ),
            SizedBox(height: 20),
            passwordState == true
              ? SizedBox.shrink()
              : Text('メールアドレスもしくはパスワードに誤りがあります。'),

            // ログインボタン
            ElevatedButton(
              onPressed: _signIn,
              child: Text('Login'),
            ),
          ],
        ),
        if (!mailLogin)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'ID(フレンドコード）を入力してください',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              // パスワード入力フィールド
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Passwordを入力してください',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // パスワードを隠す
              ),
              SizedBox(height: 20),
              passwordState == true
                ? SizedBox.shrink()
                : Text('IDもしくはパスワードに誤りがあります。'),

              // ログインボタン
              ElevatedButton(
                onPressed: _signIn,
                child: Text('Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BackButton extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: const Text(
        '＜',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
      onPressed: () {
        // ここで任意の処理
        passwordState = true;
        Navigator.of(context).pop(); // 前の画面へ遷移
      },
    );
  }
}