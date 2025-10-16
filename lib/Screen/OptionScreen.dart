import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class OptionScreen extends StatefulWidget {
  @override
  _OptionScreenState createState() => _OptionScreenState();
}
class _OptionScreenState extends State<OptionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    BannerAd(
    adUnitId: AdHelper.bannerAdUnitId,
    request: AdRequest(),
    size: AdSize.banner,
    listener: BannerAdListener(
      onAdLoaded: (ad) {
        setState(() {
          _bannerAd = ad as BannerAd;
        });
      },
      onAdFailedToLoad: (ad, err) {
        print('Failed to load a banner ad: ${err.message}');
        ad.dispose();
      },
    ),
  ).load();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Firebase Auth からログアウト
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ログアウトしました"),
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/load');
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("ログアウトに失敗しました: $e"),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
  try {
    User? user = _auth.currentUser;
    if (user != null) {
      // 再認証を要求する（パスワード認証）
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: 'ユーザーの現在のパスワード',  // ユーザーから入力されたパスワード
      );
      await user.reauthenticateWithCredential(credential);  // 再認証

      await user.delete(); // アカウント削除
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('アカウントが削除されました')));
    }
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: ${e.message}')));
  }
}

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width ; // ボタンの幅
    final double screenHeight = screenSize.height ;  // ボタンの高さ


    _changeRoutePass() {
      context.go('/menu');
    }




    return Scaffold(
      body:
      Center( // Columnを画面全体の中央に配置
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start, // 子ウィジェットを横方向の中央に揃える
          children: [
            if(_bannerAd != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
            if (_bannerAd == null)
            const SizedBox(height: 50.0,),
            Row(
              children: [
                SizedBox( // サイズ制約を明示
                  width: 50, // 必要に応じて調整
                  height: 50, // 必要に応じて調整
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MovingLeftImage(
                        onTap: _changeRoutePass,
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                ),
                const Text('設定など', style: TextStyle(fontFamily: 'makinas4', fontSize: 30),), // タイトルを追加
              ]
            ),
            SizedBox(height: screenHeight * 0.35,),
            ElevatedButton(onPressed: _logout, child: Text('ログアウト')),
            Text('パスワードを忘れていると２度とログインできない可能性があるので注意してください。'),
            SizedBox(height: 30,),
            ElevatedButton(onPressed: (){deleteAccount(context);}, child: Text('アカウントを削除')),
            Text('アカウント削除した後は２度と情報を復元できません。'),

          ],
        ),
      ),
    );
  }
}

class MovingLeftImage extends StatefulWidget {
  final VoidCallback onTap; // The function to execute on tap
  final double screenHeight;
  final double screenWidth;

  const MovingLeftImage({
    Key? key,
    required this.onTap,
    required this.screenHeight,
    required this.screenWidth,
  }) : super(key: key);

  @override
  _MovingLeftImageState createState() => _MovingLeftImageState();
}

class _MovingLeftImageState extends State<MovingLeftImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth easing effect
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: _animation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Image.asset(
              'Images/left.png',
              width: 50,
              height: 50,
            ),
          ),
        );
      },
    );
  }
}