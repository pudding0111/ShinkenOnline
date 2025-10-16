import 'package:flutter/material.dart';
import '../main.dart';

class LoginStateNotifier extends ChangeNotifier {

  void logIn() { 
    loginState = true;
     notifyListeners();
  }

  void logOut() { 
    loginState = false;
     notifyListeners();
  }
}

// class CountdownTimerWithBar extends StatefulWidget {
//   final int initialTime; // カウントダウンの初期時間（秒）
//   final double barWidth; // 棒の最大幅
//   final double barHeight; // 棒の高さ
//   final Color barColor; // 時間が減少する棒の色
//   final Color backgroundColor; // 背景の棒の色

//   const CountdownTimerWithBar({
//     Key? key,
//     required this.initialTime,
//     this.barWidth = 200,
//     this.barHeight = 10,
//     this.barColor = Colors.blue,
//     this.backgroundColor = Colors.grey,
//   }) : super(key: key);

//   @override
//   _CountdownTimerWithBarState createState() => _CountdownTimerWithBarState();
// }

// class _CountdownTimerWithBarState extends State<CountdownTimerWithBar> {
//   late int _remainingTime; // 残り時間
//   late double _currentBarWidth; // 現在の棒の幅
//   Timer? _timer; // タイマー

//   @override
//   void initState() {
//     super.initState();
//     _remainingTime = widget.initialTime;
//     _currentBarWidth = widget.barWidth; // 初期幅は最大幅
//     _startTimer();
//   }

//   /// タイマーを開始
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_remainingTime > 0) {
//           _remainingTime--;
//           _currentBarWidth = widget.barWidth * (_remainingTime / widget.initialTime);
//         } else {
//           timer.cancel(); // 時間切れでタイマーを停止
//         }
//       });
//     });
//   }

//   /// タイマーをリセット
//   void _resetTimer() {
//     setState(() {
//       _remainingTime = widget.initialTime;
//       _currentBarWidth = widget.barWidth;
//       _timer?.cancel();
//       _startTimer();
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel(); // ウィジェット破棄時にタイマーを停止
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           _remainingTime > 0
//               ? '$_remainingTime'
//               : '',
//           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }
// }

// void changeTimer() { 
//     setState(() {
//       sceneTimer = scenes[nowSceneIndex]['seconds'];
//       timerKey.currentState?._resetTimer();
//     });
//   }

