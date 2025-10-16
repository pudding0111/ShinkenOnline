import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screen/IDLoginScreen.dart';
import 'package:flutter_application_1/Screen/SignUpScreen.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SkillScreen.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;


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

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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
    context.go('/menu');
  } catch (e) {
    print('Data loading failed: $e');
  }
}

  @override
  void initState() {
    super.initState();
    // 画面表示時に実行される処理
    print(loginState.toString());
    print('Loading画面が表示されました');
    // FirebaseAuthからログイン状態を確認する
    _loadRoutePass();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    checkLoginState();
    });
  }
  // カウントをSharedPreferencesから読み込む
  _loadRoutePass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(()  {
      routePass = ['/load'];
      prefs.setStringList('routePass', routePass);

    });
  }

  Future<void> _changeRoutePass(String routeName) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // 既存のルートを取得して更新する場合
  List<String> routePass = prefs.getStringList('routePass') ?? []; // nullの場合は空のリストを使用
  print(routePass.join(', '));
  routePass.add(routeName); // 引数からルート名を追加
  await prefs.setStringList('routePass', routePass);
   // 更新したリストを保存
}

  void pushWithReloadByReturn(BuildContext context) async { // [*2]
    final result = await Navigator.push( // [*3]
      context,
      new MaterialPageRoute<bool>( // [*4]
        builder: (BuildContext context) => IDLoginScreen(),
      ),
    );

    if (result != null && result) {
      print("view reload!");
      setState(() {
        loginState = loginState;
      });
    }
  }



  void checkLoginState() async {
    User? user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (user != null) {
      // ログインしている場合
      uid = user.uid; // UID を取得
      print('ログイン中: ${user.email}');
      setState(() {
        loginState = true;
      });
      try {
        UserCredential userCredential = await _auth.signInAnonymously();
        User? user = userCredential.user;

        if (user != null) {
          setState(() {
            uid = user.uid;
          });
          print("User ID: ${user.uid}"); // UIDを取得
        }
      } catch (e) {
        print("Error: $e");
      }
      _loadUserData();
    } else {
      // ログインしていない場合
      print('ユーザーはログインしていません');
      setState(() {
        loginState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.7; // ボタンの幅
    final double buttonHeight = screenSize.height * 0.1;  // ボタンの高さ

    return Scaffold(
      appBar: AppBar(
        title: Text('心拳オンラインへようこそ！'), // タイトルを追加
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Column(

            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(routePass.join(', ')), // リストをカンマ区切りで1つの文字列に変換
              loginState
                ? PlayButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight)
                : noLoginMat(
                    buttonWidth: 200,
                    buttonHeight: 50,
                    onLoginPressed:  () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => IDLoginScreen()),
                      ).then((result) {
                        if (result == true) {
                          setState(() {
                            loginState = true;
                          });
                        }
                      });
                    },
                    signUpButtonPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      ).then((result) {
                        if (result == true) {
                          setState(() {
                            loginState = true;
                          });
                        }
                      });
                    },
                  ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    setState(() {
                      loginState = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Logged out successfully")),
                    );


                    // ログアウト後に特定の画面に遷移させる場合はこちらに処理を追加
                    // Navigator.pushReplacementNamed(context, '/login');
                  } catch (e) {
                    print("Error logging out: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to log out")),
                    );
                  }
                },
                child: Text('Logout'),
              ),


            ],
          ),

        ],
      ),
    );
  }
}

class noLoginMat extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;
  final VoidCallback onLoginPressed;
  final VoidCallback signUpButtonPressed; // ボタン押下時のコールバック

  noLoginMat({
    required this.buttonWidth,
    required this.buttonHeight,
    required this.onLoginPressed,
    required this.signUpButtonPressed, // コールバックを受け取る
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      SizedBox(height: 20),

              SignUpButton(
                buttonWidth: buttonWidth,
                 buttonHeight: buttonHeight,
                 onPressed: signUpButtonPressed,
                 ),
              Text('↑初めてプレイする方はこちら'),
              SizedBox(height: 10),
              LogInButton(
                buttonWidth: buttonWidth,
                buttonHeight: buttonHeight,
                onPressed: () {
                  print("ログインボタンが押されました");
                  onLoginPressed(); // ボタン押下時にコールバックを呼び出す
                },
              ),
              Text('↑以前にプレイしたことがある方はこちら'),
              SizedBox(height: 10),

      ],
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

        context.go('/menu');
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

class LogInButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;
  final VoidCallback onPressed;

  LogInButton({required this.buttonWidth, required this.buttonHeight, required this.onPressed,});

  @override
  Widget build(BuildContext context) {

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail, // Flutterのアイコンに変更
            size: 20,
          ),
           // アイコンとテキストの間のスペース
          Text(
            "メールでログイン",
            style: TextStyle(
              fontSize: 16, // テキストサイズ
              fontFamily: 'Rounded', // フォントのスタイル（Roundedはデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}

class SignUpButton extends StatelessWidget {

  final double buttonWidth;
  final double buttonHeight;
  final VoidCallback onPressed;

  SignUpButton({required this.buttonWidth, required this.buttonHeight, required this.onPressed,});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "新規作成",
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






