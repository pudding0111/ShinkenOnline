import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro_platform_interface.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dart_midi_pro/dart_midi_pro.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'dart:typed_data'; // ByteData
import 'package:path_provider/path_provider.dart'; // getTemporaryDirectory
import 'package:audioplayers/audioplayers.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter/services.dart';


class MakeSoundScreen extends StatefulWidget {
  @override
  _MakeSoundScreenState createState() => _MakeSoundScreenState();
}
class _MakeSoundScreenState extends State<MakeSoundScreen> {
  String myFriendId = '';
  late AudioCache _audioCache;
  late AudioPlayer _audioPlayer;
  double _playbackRate = 1.0;
  final MidiPro midiPro = MidiPro();
  final ValueNotifier<Map<int, String>> loadedSoundfonts = ValueNotifier<Map<int, String>>({});
  final ValueNotifier<int?> selectedSfId = ValueNotifier<int?>(null);
  final instrumentIndex = ValueNotifier<int>(0);
  final bankIndex = ValueNotifier<int>(0);
  final channelIndex = ValueNotifier<int>(0);
  final volume = ValueNotifier<int>(127);

  @override
void initState() {
  super.initState();
  _loadPreferences();
  _audioCache = AudioCache(prefix: 'assets/Sounds/');
  _audioPlayer = AudioPlayer();
}
@override
void dispose() {
  _audioPlayer.dispose();
  super.dispose();
}

  _loadPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      myFriendId = prefs.getString('myFriendId') ?? 'アカウントを作成してください';
    });
  }

 void playAudio(String soundFileName) async {
  try {
    print('Playing sound: $soundFileName');
    final audioPlayer = AudioPlayer(); // 新しいインスタンスを生成
    await audioPlayer.play(AssetSource('Sounds/$soundFileName.mp3'));
  } catch (e) {
    print('Error playing audio: $e');
  }
}
void _stopAudio() async {
  await _audioPlayer.stop();
}

  void loadWav() async{
    final soundfontId = await MidiPro().loadSoundfont(path: 'Sounds/FluidR3_GM.sf2', bank:0, program: 0);
    print('somethinig');
    print('somethinig');
    print('somethinig');
    await midiPro.playNote(sfId: soundfontId, channel: 0, key: 60, velocity: 127);
}

Future<void> playNote({
    required int key,
    required int velocity,
    int channel = 0,
    int sfId = 1,
  }) async {
    int? sfIdValue = sfId;
    if (!loadedSoundfonts.value.containsKey(sfId)) {
      sfIdValue = loadedSoundfonts.value.keys.first;
    }
    await midiPro.playNote(channel: channel, key: key, velocity: velocity, sfId: sfIdValue);
  }

  /// Stops a note on the specified channel.
  Future<void> stopNote({
    required int key,
    int channel = 0,
    int sfId = 1,
  }) async {
    int? sfIdValue = sfId;
    if (!loadedSoundfonts.value.containsKey(sfId)) {
      sfIdValue = loadedSoundfonts.value.keys.first;
    }
    await midiPro.stopNote(channel: channel, key: key, sfId: sfIdValue);
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
      body: Center( // Columnを画面全体の中央に配置
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center, // 子ウィジェットを横方向の中央に揃える
          children: [
            // if(_bannerAd != null)
            // Align(
            //   alignment: Alignment.topCenter,
            //   child: Container(
            //     width: _bannerAd!.size.width.toDouble(),
            //     height: _bannerAd!.size.height.toDouble(),
            //     child: AdWidget(ad: _bannerAd!),
            //   ),
            // ),
            // if (_bannerAd == null)
            // SizedBox(height: 50.0,),
            ElevatedButton(onPressed: (){playAudio('盾で防御');}, child: Text('load wav')),
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
                Text('友達と対戦', style: TextStyle(fontFamily: 'makinas4', fontSize: 30),), // タイトルを追加
              ]
            ),
            SizedBox(height: screenHeight * 0.35,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('自分のフレンドコード', style: TextStyle(fontFamily: 'makinas4'),),
                CopyableText(myFriendId),
              ],
            ),
            Text('タップでコピーできます。↑', style: TextStyle(fontFamily: 'makinas4'),),

            ElevatedButton(onPressed: loadWav, child: Text('load wav')),
            Text(
              '次回アプデで\nフレンド機能追加予定',
              style: TextStyle(
                fontFamily: 'makinas4',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
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

class CopyableText extends StatelessWidget {
  final String text;

  const CopyableText(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$text」をコピーしました！')),
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}