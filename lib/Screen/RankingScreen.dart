import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screen/SkillScreen.dart';
import '../main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RankingScreen extends StatefulWidget {
  @override
  _RankingScreenState createState() => _RankingScreenState();
}
class _RankingScreenState extends State<RankingScreen> {
  List<List<String>> newArrayOfArrays = [];
  List<Map<String, dynamic>> skillRanking = [];
  bool isLoading = true;
  bool trophyView = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    fetchRankingData();
    fetchSkillRanking();
  }

  Future<void> fetchRankingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      // ユーザー情報を取得
      final currentUser = _auth.currentUser;
      final userId = currentUser?.uid ?? '';
      final userName = prefs.getString('myName') ?? '名前はまだない'; // ユーザー名は必要に応じて取得してください
      final userTrophy = (prefs.getInt('myTrophy') ?? 0).toString(); // 初期値を設定（Firestoreから取得してください）

      // 初期データとして現在のユーザーを追加
      List<List<String>> arrayOfArrays = [
        [userId, userName, userTrophy],
      ];

      // Firestoreからデータを取得
      final rankingDoc = await _firestore
          .collection('newRanking')
          .doc('trophy')
          .get();

      if (rankingDoc.exists) {
        final data = rankingDoc.data() ?? {};
        final uids = List<String>.from((data['uid'] as List).map((e) => e.toString()));
        final names = List<String>.from((data['name'] as List).map((e) => e.toString()));
        final trophies = List<String>.from((data['trophy'] as List).map((e) => e.toString()));

        // データを配列の配列に変換
        for (int i = 0; i < uids.length; i++) {
          if (uids[i] != userId) {
            arrayOfArrays.add([uids[i], names[i], trophies[i]]);
          }
        }

        // トロフィー数でソート
        arrayOfArrays.sort((a, b) {
          final int aTrophy = int.tryParse(a[2]) ?? 0;
          final int bTrophy = int.tryParse(b[2]) ?? 0;
          return bTrophy.compareTo(aTrophy);
        });

        // トップ500に制限
        if (arrayOfArrays.length > 500) {
          arrayOfArrays = arrayOfArrays.sublist(0, 500);
        }

        setState(() {
          newArrayOfArrays = arrayOfArrays;
        });

        // Firestoreに更新
        await _firestore.collection('newRanking').doc('trophy').set({
          'uid': arrayOfArrays.map((e) => e[0]).toList(),
          'name': arrayOfArrays.map((e) => e[1]).toList(),
          'trophy': arrayOfArrays.map((e) => e[2]).toList(),
        });
      }
    } catch (e) {
      print('Error fetching ranking data: $e');
    }
  }

  Future<void> fetchSkillRanking() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Firestoreインスタンスの取得
      final firestore = FirebaseFirestore.instance;

      // newRankingコレクションのskillドキュメント参照
      final skillDocRef = firestore.collection('newRanking').doc('skill');

      // ドキュメントを取得
      final docSnapshot = await skillDocRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        // skillName と skillNo 配列の取得
        final List<dynamic> skillNames = data['skillName'] as List<dynamic>;
        final List<dynamic> skillCounts = data['skillNo'] as List<dynamic>;

        if (skillNames.length != skillCounts.length) {
          throw Exception("Skill names and counts arrays have mismatched lengths.");
        }

        // 名前と使用回数を結合
        final List<Map<String, dynamic>> combinedData = List.generate(skillNames.length, (index) {
          return {
            'skillNo': index + 1,
            'skillName': skillNames[index],
            'count': skillCounts[index],
          };
        });

        // 使用回数の多い順にソート
        combinedData.sort((a, b) => b['count'].compareTo(a['count']) as int);

        setState(() {
          skillRanking = combinedData;
        });
      } else {
        print("Document does not exist");
      }
    } catch (e) {
      print("Error fetching skill ranking: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    _changeRoutePass() {
      context.go('/menu');
    }

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
          SizedBox(height: 50.0,),

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
              Text('ランキング', style: TextStyle(fontFamily: 'makinas4', fontSize: 30.0),),
              CustomImageButton(screenWidth: screenWidth, buttonText: '切り替え', onPressed: () {setState(() {
                trophyView = !trophyView;
              });})
            ],
          ),

          //トロフィーランキングビュー
          if (trophyView)
          Expanded(
            child: ListView.builder(
              itemCount: newArrayOfArrays.length,
              itemBuilder: (context, index) {
                final array = newArrayOfArrays[index];
                final isCurrentUser = array[0] == (_auth.currentUser?.uid ?? '');

                return ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 0) SvgPicture.asset('Images/champion3.svg'),
                      if (index == 1) SvgPicture.asset('Images/champion2.svg'),
                      if (index == 2) SvgPicture.asset('Images/champion1.svg'),
                      Text('${index + 1}位'),
                    ],
                  ),
                  title: Text(
                    isCurrentUser ? '${array[1]} (あなた)' : array[1],
                    style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal, fontFamily: 'makinas4', fontSize: screenWidth * 0.04
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('Images/trophy.png', width: screenWidth * 0.15,),
                      Text(array[2], style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal, fontFamily: 'makinas4', fontSize: screenWidth * 0.06
                    ),),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!trophyView)
          Expanded(child:
          ListView.builder(
              itemCount: skillRanking.length,
              itemBuilder: (context, index) {
                final skill = skillRanking[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // 上下に8pxの余白
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text("${index + 1}位"),
                    ),
                    title: Row(
                      children: [
                        Image.asset(
                          "Images/No${skill['skillNo']}.png",
                          width: screenWidth * 0.1,
                        ),
                        SizedBox(width: 8.0), // アイコンとテキストの間に余白
                        Text(
                          '${skill['skillName']}',
                          style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06),
                        ),
                      ],
                    ),
                    trailing: Text(
                      "${skill['count']}回",
                      style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.05),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

class CustomImageButton extends StatelessWidget {
  final double screenWidth;
  final String buttonText;
  final VoidCallback onPressed;

  CustomImageButton({
    required this.screenWidth,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ボタンの背景画像
          Image.asset(
            'Images/button.png',
            width: screenWidth * 0.3, // 画面幅に応じたサイズ設定
            fit: BoxFit.contain,
          ),
          // ボタンのテキスト
          Text(
            buttonText,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}




