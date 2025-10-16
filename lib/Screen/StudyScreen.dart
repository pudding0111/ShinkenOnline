import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StudyScreen extends StatefulWidget {
  @override
  _StudyScreenState createState() => _StudyScreenState();
}
class _StudyScreenState extends State<StudyScreen> {

  String friendId = '';
  @override
  void initState() {
    super.initState();
  }
  List<List<DateTime>> studySessions = [
    [DateTime(2025, 3, 20, 10, 0), DateTime(2025, 3, 20, 11, 30)], // 10:00 - 11:30
    [DateTime(2025, 3, 20, 13, 0), DateTime(2025, 3, 20, 14, 45)], // 13:00 - 14:45
    [DateTime(2025, 3, 20, 16, 15), DateTime(2025, 3, 20, 17, 30)], // 16:15 - 17:30
  ];


  _loadPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      friendId = prefs.getString('myFriendId') ?? '名無し';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width ; // ボタンの幅
    final double screenHeight = screenSize.height ;  // ボタンの高さ


    _changeRoutePass() {
      context.go('/miniGame');
    }



    return Scaffold(
      body: Center( // Columnを画面全体の中央に配置
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center, // 子ウィジェットを横方向の中央に揃える
          children: [
            SizedBox(height: 50,),
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
                Text('勉強記録', style: TextStyle(fontFamily: 'makinas4', fontSize: 30),), // タイトルを追加
              ]
            ),
            Spacer(),
            StudyGraph(screenWidth: screenWidth, screenHeight: screenHeight, sessionData: studySessions),
            Spacer(),
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

class MasFillButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  MasFillButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed mas fill button");
        context.go('/masFill');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_3x3, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "ピクセルアート",
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'makinas4', // フォントのスタイル（makinas4はデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}


class StudyGraph extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final List<List<DateTime>> sessionData; // [[start, end], [start, end], ...]

  StudyGraph({
    required this.screenWidth,
    required this.screenHeight,
    required this.sessionData,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionData.isEmpty) {
      return Center(child: Text("データなし"));
    }

    List<FlSpot> graphData = _generateGraphData(sessionData);

    double minX = graphData.first.x;
    double maxX = graphData.last.x;


    return Container(
      width: screenWidth,
      height: screenHeight * 0.4, // 画面の40%をグラフに使用
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  );
                },
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxX - minX) / 4, // 4つのラベルを表示
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatTime(value.toInt()),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  );
                },
                reservedSize: 30,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: graphData,
              isCurved: true,
              color: Colors.blue.withOpacity(0.5),
              barWidth: 4,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 時間 (millisecondsSinceEpoch) を HH:mm に変換する関数
  String _formatTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat.Hm().format(date); // HH:mm 形式
  }

List<FlSpot> _generateGraphData(List<List<DateTime>> sessions) {
  List<FlSpot> spots = [];

  // **1. 最初のセッションは開始から終了まで集中力100で一定**
  DateTime firstStart = sessions[0][0];
  DateTime firstEnd = sessions[0][1];

  double firstStartX = firstStart.millisecondsSinceEpoch.toDouble();
  double firstEndX = firstEnd.millisecondsSinceEpoch.toDouble();

  // **最初のセッションの開始と終了を100でプロット**
  spots.add(FlSpot(firstStartX, 100));
  spots.add(FlSpot(firstEndX, 100));

  double currentConcentration = 100.0; // 最初の集中力は100

  for (int i = 1; i < sessions.length; i++) {
    DateTime start = sessions[i][0];
    DateTime end = sessions[i][1];

    double startX = start.millisecondsSinceEpoch.toDouble();
    double endX = end.millisecondsSinceEpoch.toDouble();
    double sessionDuration = (endX - startX) / 1000; // 秒換算

    // **2. セッション間の集中力低下**
    DateTime prevEnd = sessions[i - 1][1];
    double prevEndX = prevEnd.millisecondsSinceEpoch.toDouble();
    double restDuration = (startX - prevEndX) / 1000; // 秒換算

    double dyDecrease = (-1 / 8100) * (restDuration * restDuration);
    double newConcentration = currentConcentration + dyDecrease;

    // **中間2点を追加（集中力低下を滑らかに）**
    double quarterX = prevEndX + (startX - prevEndX) * 0.25;
    double threeQuarterX = prevEndX + (startX - prevEndX) * 0.75;
    spots.add(FlSpot(quarterX, currentConcentration + (newConcentration - currentConcentration) * 0.25));
    spots.add(FlSpot(threeQuarterX, currentConcentration + (newConcentration - currentConcentration) * 0.75));

    // **新しいセッション開始時の集中力をプロット**
    spots.add(FlSpot(startX, newConcentration));
    currentConcentration = newConcentration;

    // **3. セッション中の集中力上昇**
    double dyIncrease = (-1 / 8100) * (sessionDuration * sessionDuration) + (2 / 9) * sessionDuration;
    double peakConcentration = currentConcentration + dyIncrease;

    if (peakConcentration >= 100) {
      // **100に達する時刻を計算**
      double peakX = startX;
      for (double x = 0; x <= sessionDuration; x += 1) {
        double tempDy = (-1 / 8100) * (x * x) + (2 / 9) * x;
        if (currentConcentration + tempDy >= 100) {
          peakX = startX + x * 1000;
          break;
        }
      }

      // **中間2点を追加**
      double quarterX = startX + (peakX - startX) * 0.25;
      double threeQuarterX = startX + (peakX - startX) * 0.75;
      spots.add(FlSpot(quarterX, currentConcentration + (100 - currentConcentration) * 0.25));
      spots.add(FlSpot(threeQuarterX, currentConcentration + (100 - currentConcentration) * 0.75));

      // **100到達時とセッション終了時にプロット**
      spots.add(FlSpot(peakX, 100));
      spots.add(FlSpot(endX, 100));
      currentConcentration = 100;
    } else {
      // **100未満の場合 → 中間2点を追加**
      double quarterX = startX + sessionDuration * 0.25 * 1000;
      double threeQuarterX = startX + sessionDuration * 0.75 * 1000;
      spots.add(FlSpot(quarterX, currentConcentration + dyIncrease * 0.25));
      spots.add(FlSpot(threeQuarterX, currentConcentration + dyIncrease * 0.75));

      // **セッション終了時にプロット**
      spots.add(FlSpot(endX, peakConcentration));
      currentConcentration = peakConcentration;
    }
  }

  return spots;
}





}

