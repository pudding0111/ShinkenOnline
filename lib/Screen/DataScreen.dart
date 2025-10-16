import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  late Future<SharedPreferences> _prefsFuture;

  String myName = '';

  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    loadMyNames();
    // 非同期で SharedPreferences を取得
    _prefsFuture = SharedPreferences.getInstance();
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

  void loadMyNames() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    myName = prefs.getString('myName') ?? '名前は不明です';
  }

  Future<List<Map<String, String>>> fetchLogs(SharedPreferences prefs) async {
    try {
      final dateLog = prefs.getStringList('dateLog') ?? [];
      final gameTypeLog = prefs.getStringList('gameTypeLog') ?? [];
      final resultLog = prefs.getStringList('resultLog') ?? [];
      final enemyNameLog = prefs.getStringList('enemyNameLog') ?? [];
      final enemyRankLog = prefs.getStringList('enemyRankLog') ?? [];
      final enemyCardLog = prefs.getStringList('enemyCardLog') ?? [];
      final enemyPointLog = prefs.getStringList('enemyPointLog') ?? [];
      final myRankLog = prefs.getStringList('myRankLog') ?? [];
      final myCardLog = prefs.getStringList('myCardLog') ?? [];
      final myPointLog = prefs.getStringList('myPointLog') ?? [];

      int count = dateLog.length;
      List<Map<String, String>> logs = [];

      for (int i = 0; i < count; i++) {
        logs.add({
          'dateTime': dateLog[i],
          'gameType': gameTypeLog.length > i ? gameTypeLog[i] : '',
          'battleResult': resultLog.length > i ? resultLog[i] : '',
          'enemyName': enemyNameLog.length > i ? enemyNameLog[i] : '',
          'enemyRank': enemyRankLog.length > i ? enemyRankLog[i] : '',
          'enemyCard': enemyCardLog.length > i ? enemyCardLog[i] : '',
          'enemyPoint': enemyPointLog.length > i ? enemyPointLog[i] : '',
          'myRank': myRankLog.length > i ? myRankLog[i] : '',
          'myCard': myCardLog.length > i ? myCardLog[i] : '',
          'myPoint': myPointLog.length > i ? myPointLog[i] : '',
        });
      }

      return logs.reversed.toList(); // 新着順にするため逆順
    } catch (e) {
      // ログ取得中のエラーをキャッチして空リストを返す
      print('Error fetching logs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Column(
        children: [
          // バナー広告表示
          if (_bannerAd != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          if (_bannerAd == null)
            SizedBox(height: 50.0),

          // タイトルと戻るボタン
          Row(
            children: [
              SizedBox( // サイズ制約を明示
                  width: 50, // 必要に応じて調整
                  height: 50, // 必要に応じて調整
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MovingLeftImage(
                        onTap: () { context.go('/menu');},
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                ),
              Text(
                '対戦履歴',
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontFamily: 'makinas4',
                ),
              ),
            ],
          ),

          // コンテンツ部分
          Expanded(
            child: FutureBuilder<SharedPreferences>(
              future: _prefsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final prefs = snapshot.data!;
                  return FutureBuilder<List<Map<String, String>>>(
                    future: fetchLogs(prefs),
                    builder: (context, logsSnapshot) {
                      if (logsSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (logsSnapshot.hasError) {
                        return Center(child: Text('ログ取得中にエラーが発生しました'));
                      } else if (logsSnapshot.hasData && logsSnapshot.data!.isNotEmpty) {
                        return LogListView(
                          logs: logsSnapshot.data!,
                          screenHeight: screenHeight,
                          screenWidth: screenWidth,
                          myName: myName,
                        );
                      } else {
                        return Center(child: Text('ログがありません'));
                      }
                    },
                  );
                } else {
                  return Center(child: Text('エラーが発生しました'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}



class LogListView extends StatefulWidget {
  final List<Map<String, String>> logs;
  final double screenHeight;
  final double screenWidth;
  final String myName;

  LogListView({
    required this.logs,
    required this.screenHeight,
    required this.screenWidth,
    required this.myName,
  });

  @override
  _LogListViewState createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  // 各ログの展開状態を管理
  List<bool> _expandedStates = [];
  String gameType = '';



  @override
  void initState() {
    super.initState();
    // 初期状態ではすべて未展開
    _expandedStates = List.generate(widget.logs.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.logs.length,
      itemBuilder: (context, index) {
        final log = widget.logs[index];
        final isExpanded = _expandedStates[index];
        String gameType = log['gameType'] ?? '';
        switch (gameType) {
          case 'strategy':
            gameType = 'ランク対戦';
            break;
          case 'casual':
            gameType = 'カジュアル対戦';
            break;
          case 'tournament':
            gameType = 'トーナメント';
            break;
          default:
            gameType = '不明なゲームタイプ';
            break;
        }
        String result = log['battleResult'] ?? '';
        switch (result) {
          case 'win':
            result = '勝利';
            break;
          case 'lose':
            result = '敗北';
            break;
          case 'knokOut':
            result = '完全勝利';
            break;
          case 'draw':
            result = '引き分け';
            break;
          default:
            result = '不明なゲームタイプ';
            break;
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _expandedStates[index] = !_expandedStates[index]; // 展開状態を切り替え
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上部: 基本情報
                    if (!isExpanded)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          gameType,
                          style: TextStyle(fontSize: widget.screenWidth * 0.04,  fontFamily: 'makinas4', decoration: TextDecoration.underline,),
                        ),
                        Text(
                          result,
                          style: TextStyle(fontSize: widget.screenWidth * 0.045, fontWeight: FontWeight.bold, color: result == '敗北' ? Color.fromARGB(255, 16, 47, 125) : Color.fromARGB(255, 0, 0, 0), fontFamily: 'makinas4'),
                        ),
                        Text(
                          log['dateTime'] ?? 'Unknown Date',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    if (!isExpanded)
                    Row(
                        children: [
                          // 左側: 自分の情報
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.myName,
                                      style: TextStyle(
                                          fontSize: widget.screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'makinas4'),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'Images/${log['myRank'] ?? 'none'}.svg',
                                      width: widget.screenWidth * 0.15,
                                      height: widget.screenHeight * 0.06,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      log['myPoint'] ?? '',
                                      style: TextStyle(
                                          fontSize: widget.screenWidth * 0.1, fontFamily: 'makinas4'),
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          // 右側: 敵の情報
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      log['enemyName'] ?? '',
                                      style: TextStyle(
                                          fontSize: widget.screenWidth * 0.036,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'makinas4'),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'Images/${log['enemyRank'] ?? 'none'}.svg',
                                      width: widget.screenWidth * 0.15,
                                      height: widget.screenHeight * 0.06,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      log['enemyPoint'] ?? '',
                                      style: TextStyle(
                                          fontSize: widget.screenWidth * 0.1, fontFamily: 'makinas4'),
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    if (isExpanded) ...[
                      Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          gameType,
                          style: TextStyle(fontSize: widget.screenWidth * 0.04,  fontFamily: 'makinas4', decoration: TextDecoration.underline,),
                        ),
                        Text(
                          result,
                          style: TextStyle(fontSize: widget.screenWidth * 0.045, fontWeight: FontWeight.bold, color: result == '敗北' ? Color.fromARGB(255, 16, 47, 125) : Color.fromARGB(255, 0, 0, 0), fontFamily: 'makinas4'),
                        ),
                        Text(
                          log['dateTime'] ?? 'Unknown Date',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                      SizedBox(height: 16),
                      Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.myName,
                              style: TextStyle(
                                  fontSize: widget.screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'makinas4'),
                            ),
                            Row(
                              children: [
                            SvgPicture.asset(
                              'Images/${log['myRank'] ?? 'none'}.svg',
                              width: widget.screenWidth * 0.15,
                              height: widget.screenHeight * 0.06,
                            ),
                            SizedBox(width: 8),
                            Text(
                              log['myPoint'] ?? '',
                              style: TextStyle(fontSize: widget.screenWidth * 0.1, fontFamily: 'makinas4'),
                            ),
                              ]
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildCardList(
                      (log['myCard'] ?? '').split(','),
                      widget.screenWidth,
                      widget.screenHeight,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'V.S.',
                          style: TextStyle(fontSize: widget.screenWidth * 0.1, fontFamily: 'makinas4'),
                        ),
                      ],
                    ),


                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log['enemyName'] ?? '',
                              style: TextStyle(
                                  fontSize: widget.screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'makinas4'),
                            ),
                            Row(
                            children: [
                              SvgPicture.asset(
                                'Images/${log['enemyRank'] ?? 'none'}.svg',
                                width: widget.screenWidth * 0.15,
                                height: widget.screenHeight * 0.06,
                              ),
                              SizedBox(width: 8),
                              Text(
                                log['enemyPoint'] ?? '',
                                style: TextStyle(fontSize: widget.screenWidth * 0.1, fontFamily: 'makinas4'),
                              ),
                            ],
                          ),
                          ],
                        ),
                      ],
                    ),
                    _buildCardList(
                      (log['enemyCard'] ?? '').split(','),
                      widget.screenWidth,
                      widget.screenHeight,
                    ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardList(List<String> cards, double screenWidth, double screenHeight) {
    return SizedBox(
      height: screenHeight * 0.07,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          // カードが空でない場合のみ表示
          if (cards[index] != '') {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'Images/${cards[index]}.png',
                width: screenWidth * 0.13,
                height: screenHeight * 0.1,
              ),
            );
          } else {
            // 空の場合は空のウィジェットを返す
            return SizedBox.shrink();
          }
        },
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



