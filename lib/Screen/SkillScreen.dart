import 'dart:ffi';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SkillScreen extends StatefulWidget {
  @override
  _SkillScreenState createState() => _SkillScreenState();
}

class _SkillScreenState extends State<SkillScreen>  with SingleTickerProviderStateMixin {

  List<Map<String, String>> mySpeedSkillCardList = [];
  List<Map<String, String>> myOwnSkillCardList = [];
  List<String> mySpeedSkillNoList = [];
  List<String> mySpeedSkillTypeList = [];
  List<String> myStrategySkillNoList = [];
  List<int> mySkillUseCountList = [-1];
  List<int> mySkillActiveCountList = [-1];
  List<String> myQuestSkillNoList = [];
  List<String> myOwnSkillList = ['No1','No2','No3','No4','No5','No6','No7','No8','No9', 'No10'];
  BannerAd? _bannerAd;

  bool questClear = false;
  bool skillReleaseCheck = false;
  bool questClearView = false;
  bool questNotClearView = false;
  String skillMode = 'strategy';

  @override
  void initState() {
    super.initState();
    _initialize();  // 初期化メソッドにまとめる
  }

  void _initialize() async {
    await _loadRoutePass('skill');
    _loadSkillList();
    countSkillTypes();

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

  void _loadSkillList() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      gachaPoint = (prefs.getInt('myGachaPoint') ?? 0);
      myStrategySkillNoList = (prefs.getStringList('StrategySkillNoList') ?? ['No1','No2','No3','No4','No5','No6','No7','No8','No9','No10']);
      mySpeedSkillNoList = (prefs.getStringList('SpeedSkillNoList') ?? ['No1','No2','No3','No4','No5','No6','No7','No8','No9','No10']);
      mySpeedSkillTypeList = (prefs.getStringList('SpeedSkillTypeList') ?? ['rock', 'rock', 'rock', 'rock', 'scissor', 'scissor', 'scissor', 'paper', 'paper', 'paper']);
      myOwnSkillList = (prefs.getStringList('myOwnSkillList') ?? ['No1','No2','No3','No4','No5','No6','No7','No8','No9', 'No10']);
      myOwnSkillList.sort((a, b) {
        // "No" を削除して数値部分を取得
        final int numA = int.tryParse(a.replaceAll('No', '')) ?? 0;
        final int numB = int.tryParse(b.replaceAll('No', '')) ?? 0;
        return numA.compareTo(numB);
      });

      prefs.setStringList('myOwnSkillList', myOwnSkillList);

      print(myOwnSkillList);
      for (int i = 0 ; i < skills.length ; i++) {
        if (!myOwnSkillList.contains(skills[i]['No']) && !myQuestSkillNoList.contains(skills[i]['No'])){
          myQuestSkillNoList.add(skills[i]['No'] ?? 'No50');
        }
      }

      for (int i = 1; i < skills.length; i++){
        mySkillUseCountList.add(prefs.getInt('mySkillCount_No$i') ?? 0);
      }

      for (int i = 1; i < skills.length; i ++ ){
        mySkillActiveCountList.add(prefs.getInt('mySkillActive_No$i') ?? 0);
      }

      for (var skill in skills) {
        if (myOwnSkillList.contains(skill['No']!)) {
          myOwnSkillCardList.add(skill);
        }
      }

      while (mySkillUseCountList.length < skills.length) {
        mySkillUseCountList.add(0);
      }
      // Pair the elements of mySpeedSkillNoList and mySpeedSkillTypeList for sorting
      List<Map<String, String>> pairedList = List.generate(mySpeedSkillNoList.length, (index) {
        return {
          'No': mySpeedSkillNoList[index],
          'Type': mySpeedSkillTypeList[index]
        };
      });

      // Sort pairedList based on the order of 'Type' field: rock -> scissor -> paper
      pairedList.sort((a, b) {
        int orderA = _getTypeOrder(a['Type']!);
        int orderB = _getTypeOrder(b['Type']!);
        return orderA.compareTo(orderB);
      });

      // Update mySpeedSkillNoList and mySpeedSkillTypeList based on sorted pairedList
      mySpeedSkillNoList = pairedList.map((item) => item['No']!).toList();
      mySpeedSkillTypeList = pairedList.map((item) => item['Type']!).toList();

      // Create mySpeedSkillCardList from sorted lists
      mySpeedSkillCardList = List.generate(mySpeedSkillNoList.length, (index) {
        return {
          'No': mySpeedSkillNoList[index],
          'Type': mySpeedSkillTypeList[index]
        };
      });
    });
  }

  int _getTypeOrder(String type) {
    switch (type) {
      case 'rock':
        return 0;
      case 'scissor':
        return 1;
      case 'paper':
        return 2;
      default:
        return 3; // in case of unknown type
    }
  }

  _saveSKillList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setStringList('StrategySkillNoList', myStrategySkillNoList);
      prefs.setStringList('SpeedSkillNoList', mySpeedSkillNoList);
      prefs.setStringList('SpeedSkillTypeList', mySpeedSkillTypeList);  // 'counter' というキーでカウントを保存
      prefs.setStringList('myOwnSkillList', myOwnSkillList);
    });
  }

  _loadRoutePass(String routeName) {
    setState(() {
      if (routePass.isNotEmpty) {
        if (routePass.contains(routeName)) {
          while (routePass.contains(routeName)) {
            if (routePass.last == routeName) {
              return;
            }
            routePass.removeLast();
          }
        } else {
          routePass.add(routeName);
        }
      }
    });
  }

  _changeRoutePass() {
    _saveSKillList();
    routePass.removeLast();
    context.go('/menu');
  }

  void onSkillSelected(String skillNo, String tap,) {
    if (_mySelectedCardIndex != -1 && tap == 'double') {
      if (!mySpeedSkillNoList.contains(skillNo) && skillMode == 'speed' && myOwnSkillList.contains(skillNo)) {
        setState(() {
          print('change skill');
          selectedSkillNo = skillNo; // 選択された番号を更新
          mySpeedSkillCardList[_mySelectedCardIndex]['No'] = skillNo;
          mySpeedSkillNoList[_mySelectedCardIndex] = skillNo;
          _saveSKillList();
        });
      } else if(!myStrategySkillNoList.contains(skillNo) && skillMode == 'strategy' && myOwnSkillList.contains(skillNo)) {
        setState(() {
          print('change skill');
          selectedSkillNo = skillNo; // 選択された番号を更新
          myStrategySkillNoList[_mySelectedCardIndex] = skillNo;
          _saveSKillList();
        });
      }
    }

    if (tap == 'single') {
      setState(() {
        selectedSkillNo = skillNo;
        _mySelectedCardIndex = myOwnSkillList.indexOf(skillNo);
        mySkillDetail = true;
      });
      print('single Tap!!');
      print(selectedSkillNo);
    }
  }

  void releaseSkill(bool clearState) {
    if (clearState) {
      setState(() {
        questClearView = true;
        questNotClearView = false;
        questClear = true;
      });
      print('clear quest skill release!');
    } else {
      setState(() {
        questClearView = false;
        questNotClearView = true;
        questClear = false;
      });
      print('not clear quest please pay money');
    }
  }

  void releaseSkillReal(bool clearState) {
    skillReleaseCheck = true;
    if (clearState) {
      setState(() {
        questClearView = true;
        questNotClearView = false;
        questClear = true;
      });
      print('clear quest skill release!');
    } else {
      setState(() {
        questClearView = false;
        questNotClearView = true;
        questClear = false;
      });
      print('not clear quest please pay money');
    }
  }

  void purchaseSkill(int money, String skillNo) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('myGachaPoint', (prefs.getInt('myGachaPoint') ?? 0) - money);
    List<String> newSkillList = prefs.getStringList('myOwnSkillList') ?? [];
    newSkillList.add(skillNo);
    prefs.setStringList('myOwnSkillList', newSkillList);
    print('I have $newSkillList');
    setState(() {
      gachaPoint = prefs.getInt('myGachaPoint') ?? 0;
      skillMode = 'strategy';
      myOwnSkillList.add(skillNo);
      for (int i = 0; i < skills.length; i++){
        if (skills[i]['No'] == skillNo) {
          myOwnSkillCardList.add(skills[i]);
        }
      }
      for (int i = 0; i < myQuestSkillNoList.length; i++){
        if (myQuestSkillNoList[i] == skillNo) {
          myQuestSkillNoList.removeAt(i);
        }
      }
      print('skill update! ${prefs.getStringList('myOwnSkillList') ?? []}');
      skillReleaseCheck = false;
      questClearView = false;
      questNotClearView = false;
      mySkillDetail = true;
    });
  }

  void resetSkill() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setStringList('myOwnSkillList',  ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']);
      print(prefs.getStringList('myOwnSkillList') ?? []);
    });
  }

  void onSkillTypeSelected(String skillType) {
    if (_mySelectedCardIndex != -1) {
      setState(() {
        print('change Type');
        mySpeedSkillCardList[_mySelectedCardIndex]['Type'] = skillType;
        mySpeedSkillTypeList[_mySelectedCardIndex] = skillType;
        _saveSKillList();
      });
    }
    countSkillTypes();
    print(skillType);
    print(_mySelectedCardIndex);
  }

  void countSkillTypes() {
    rockCount = mySpeedSkillTypeList.where((type) => type == 'rock').length;
    scissorCount = mySpeedSkillTypeList.where((type) => type == 'scissor').length;
    paperCount = mySpeedSkillTypeList.where((type) => type == 'paper').length;

    print('Rock: $rockCount');
    print('Scissor: $scissorCount');
    print('Paper: $paperCount');
  }

  void changeSkillView(int changeNumber) {
    if (skillMode == 'quest'){
      if (_mySelectedCardIndex + 1 < myQuestSkillNoList.length && changeNumber == 1){
        setState(() {
          _mySelectedCardIndex += 1;
          selectedSkillNo = myQuestSkillNoList[_mySelectedCardIndex];
        });
      }
      if (_mySelectedCardIndex > 0 && changeNumber == -1){
        setState(() {
          _mySelectedCardIndex -= 1;
          selectedSkillNo = myQuestSkillNoList[_mySelectedCardIndex];
        });
      }
    } else { //手札選択画面
      if (_mySelectedCardIndex + 1 < myOwnSkillList.length && changeNumber == 1){
        setState(() {
          _mySelectedCardIndex += 1;
          selectedSkillNo = myOwnSkillList[_mySelectedCardIndex];
        });
      }
      if (_mySelectedCardIndex > 0 && changeNumber == -1){
        setState(() {
          _mySelectedCardIndex -= 1;
          selectedSkillNo = myOwnSkillList[_mySelectedCardIndex];
        });
      }
    }
  }

  void detailSkillOff () {
    setState(() {
      mySkillDetail = false;
    });
  }

  void changeSkillMode () {
    setState(() {
      _mySelectedCardIndex = 0;
      mySkillDetail = false;
      selectedSkillNo = myOwnSkillList[_mySelectedCardIndex];
      skillMode = (skillMode == 'strategy' ? 'speed' : 'strategy');
    });
  }

  void moneyPlus() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myGachaPoint', (prefs.getInt('myGachaPoint')?? 0) + 900 );
      gachaPoint = (prefs.getInt('myGachaPoint')?? 0);
    });
  }

  void moneyMinus() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myGachaPoint', (prefs.getInt('myGachaPoint')?? 0) - 900 );
      gachaPoint = (prefs.getInt('myGachaPoint')?? 0);
    });
  }

  void levelPlus() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myLevel', (prefs.getInt('myLevel')?? 0) + 1 );
    });
  }

  void levelMinus() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myLevel', (prefs.getInt('myLevel')?? 0) - 1 );
    });
  }



  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  int _mySelectedCardIndex = -1;
  String selectedSkillNo = '';
  bool mySkillDetail = false;

  int rockCount = 0;
  int scissorCount = 0;
  int paperCount = 0;
  int gachaPoint = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
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
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: screenWidth,
                  height: 50,
                  child: SizedBox(),
                ),
              ),
              Container(
                height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.08,
                child:
                SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child:
              Row(
                children: [
                  GestureDetector(
                  onTap: _changeRoutePass,
                  child: Image.asset(
                    'Images/left.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                  Icon(
                    Icons.military_tech, // 条件に応じて変更可能
                    size: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.04, // 大きさを指定
                    color: Colors.black, // 必要に応じて色を指定
                  ),
                  Text('$gachaPoint枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenHeight * 0.023)),
                  SizedBox(width: screenWidth * 0.03),

                  if(skillMode == 'strategy')
                  Text('手札選択', style: TextStyle(fontFamily: 'makinas4', fontSize: screenHeight * 0.026, fontWeight: FontWeight.bold, decoration: TextDecoration.underline,)),
                  if(skillMode == 'quest')
                  Text('クエスト', style: TextStyle(fontFamily: 'makinas4', fontSize: screenHeight * 0.026, fontWeight: FontWeight.bold, decoration: TextDecoration.underline,)),

                  SizedBox(width: screenWidth * 0.03),
                  if (skillMode != 'quest')
                  CustomImageButton(screenWidth: screenWidth, buttonText: '切り替え', onPressed: () => { setState(() {
                    if (myQuestSkillNoList.isEmpty){
                      print('quest is empty!!');
                    } else {

                      selectedSkillNo = myQuestSkillNoList[0];
                      print('quest is there!');
                      for (int i = 0 ; i < myQuestSkillNoList.length ; i ++){
                        print('dont have ${myQuestSkillNoList[i]}');
                      }
                    skillMode = 'quest';
                    }
                  })}),
                  if (skillMode == 'quest')
                  CustomImageButton(screenWidth: screenWidth, buttonText: '切り替え', onPressed: changeSkillMode),
                ],
              ),
                )
              ),

              //
              //
              //
              //スピードモードのセレクト画面
              //
              //
              //
              if (skillMode == 'speed')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      SpeedCardListView(
                    cards: mySpeedSkillCardList,
                    screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                    screenWidth: screenWidth,
                    selectedCardIndex: _mySelectedCardIndex,
                    onCardTap: (index) {
                      setState(() {
                        _mySelectedCardIndex = index;
                      });
                    },
                    onCardDoubleTap: (index) {
                      setState(() {
                        _mySelectedCardIndex = index;
                        mySkillDetail = true;
                        selectedSkillNo = mySpeedSkillNoList[index];
                      });
                    },
                  ),

                ],
              ),
              if (skillMode == 'speed')
              Container(
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 253, 253, 253),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedImageView(screenHeight: screenHeight, onTap: () => {onSkillTypeSelected('rock')}, imagePath: 'Images/rock.svg'),
                        Text(rockCount.toString() + '枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenHeight * 0.02)),
                      ],
                    ),

                    SizedBox(width: 20), // アイコン間のスペース

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedImageView(screenHeight: screenHeight, onTap: () => {onSkillTypeSelected('scissor')}, imagePath: 'Images/scissor.svg'),
                        Text(scissorCount.toString() + '枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenHeight * 0.02)),
                      ],
                    ),

                    SizedBox(width: 20),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedImageView(screenHeight: screenHeight, onTap: () => {onSkillTypeSelected('paper')}, imagePath: 'Images/paper.svg'),
                        Text(paperCount.toString() + '枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenHeight * 0.02)),
                      ],
                    ),
                  ],
                ),
              ),
              if (skillMode == 'speed')
              Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 253, 253, 253),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                ),
                child: SpeedSkillGridWidget(
                  skills: myOwnSkillCardList,
                  mySkillNoList: mySpeedSkillNoList,
                  mySpeedSkillTypeList: mySpeedSkillTypeList,
                  mySkillOwnNoList: myOwnSkillList,
                  screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                  onSkillSelected: onSkillSelected,
                ),
              ),

              //
              //
              //
              //戦略モードのセレクト画面
              //
              //
              //
              if (skillMode == 'strategy')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.35,
                    width: screenWidth,
                    child:
                    Stack(
                      children: [
                        StrategyCardListView(
                          cards: myStrategySkillNoList,
                          screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                          screenWidth: screenWidth,
                          selectedCardIndex: _mySelectedCardIndex,
                          onCardTap: (index) {
                            setState(() {
                              _mySelectedCardIndex = index;
                            });
                          },
                          onCardDoubleTap: (index) {
                            setState(() {
                              _mySelectedCardIndex = index;
                              mySkillDetail = true;
                              selectedSkillNo = myStrategySkillNoList[index];
                            });
                          },
                        ),
                      ],
                    )


                  ),


                ],
              ),
              if (skillMode == 'strategy')
              Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 253, 253, 253),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                ),
                child: StrategySkillGridWidget(
                  skills: myOwnSkillCardList,
                  mySkillNoList: myStrategySkillNoList,
                  mySkillOwnNoList: myOwnSkillList,
                  screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                  onSkillSelected: onSkillSelected,
                ),
              ),
              //
            //
            //
            //クエストモードのセレクト画面
            //
            //
            //
            if (skillMode == 'quest' && myQuestSkillNoList.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth,
                    height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.35,
                    child:
                  Stack(
                    children: [
                      QuestCardListView(
                    cards: myQuestSkillNoList,
                    screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                    screenWidth: screenWidth,
                    selectedCardIndex: _mySelectedCardIndex,
                    onCardTap: (index) {
                      setState(() {
                        _mySelectedCardIndex = index;
                        selectedSkillNo = myQuestSkillNoList[index];
                        mySkillDetail = true;
                      });
                    },
                    onCardDoubleTap: (index) {
                      setState(() {
                        _mySelectedCardIndex = index;
                        mySkillDetail = true;
                      });
                    },
                  ),
                    ],
                  )
                  )

                ],
              ),
            ],
          ),

          if (mySkillDetail && skillMode != 'quest')
           Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.57, // 高さを画面の下半分に設定
              color: Colors.black.withOpacity(0.5), // 背景色を薄透明に設定 (0.0〜1.0で透明度調整)
            ),
          ),


          if (mySkillDetail && skillMode == 'strategy')
          Positioned(
            left: screenWidth * 0.05,
            bottom: screenHeight * 0.1,
            child:
            CardDetailView(
              selectedCardNo: selectedSkillNo,
              skills: myOwnSkillCardList,
              skillNoList: myStrategySkillNoList,
              skillOwnList: myOwnSkillList,
              skillTypeList: [],
              screenHeight: screenHeight,
              screenWidth: screenWidth
            ),
          ),

          if (mySkillDetail && skillMode == 'speed')
          Positioned(
            left: screenWidth * 0.05,
            bottom: screenHeight * 0.1,
            child:
            CardDetailView(
              selectedCardNo: selectedSkillNo,
              skills: skills,
              skillNoList: mySpeedSkillNoList,
              skillOwnList: myOwnSkillList,
              skillTypeList: mySpeedSkillTypeList,
              screenHeight: screenHeight,
              screenWidth: screenWidth
            ),
          ),

        if (skillMode == 'quest')
        Stack (
          alignment: Alignment.center,
        children: [
          Positioned(
            left: screenWidth * 0.05,
            bottom: screenHeight * 0.02,
            child:
            QuestDetailView(
              selectedCardNo: selectedSkillNo,
              skills: skills,
              skillNoList: myQuestSkillNoList,
              skillOwnList: myOwnSkillList,
              skillTypeList: [],
              skillUseCountList: mySkillUseCountList,
              skillActiveCountList: mySkillActiveCountList,
              skillWinRateList: [],
              screenHeight: screenHeight,
              screenWidth: screenWidth,
              releaseButtonTap: releaseSkill,
            ),
          ),

        ]
        ),

        if (mySkillDetail || skillMode == 'quest')
        Stack(
          children:
          [
            MovingLeftImage(onTap: () => {changeSkillView(-1)}, screenHeight: screenHeight, screenWidth: screenWidth)
          ],
        ),
        if (mySkillDetail || skillMode == 'quest')
        Stack(
          children: [
            MovingRightImage(onTap: () => {changeSkillView(1)}, screenHeight: screenHeight, screenWidth: screenWidth)
          ],
        ),

        if (questClearView || questNotClearView)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 2, // 高さを画面の下半分に設定
            color: Colors.black.withOpacity(0.85), // 背景色を薄透明に設定 (0.0〜1.0で透明度調整)
          ),
        ),

        if (questClearView && skillMode == 'quest')
        Positioned(
            bottom: screenHeight * 0.2,
            child:Column(
              children: [
              QuestClearView(selectedCardNo: selectedSkillNo, skills: skills, questClear: questClear, screenHeight: screenHeight, screenWidth: screenWidth, releaseButtonTap: releaseSkill),
               Row (
                  children: [
                    if (questClear && gachaPoint > 1000 && !skillReleaseCheck)
                    CustomImageButton(screenWidth: screenWidth, buttonText: '解放', onPressed: () => {releaseSkillReal(questClear)}),
                    if(skillReleaseCheck)
                    CustomImageButton(screenWidth: screenWidth, buttonText: '閉じる', onPressed: () => {setState(() {
                      skillReleaseCheck = false;
                    })}),
                    if (questClear && gachaPoint > 1000 )
                    SizedBox(width: screenWidth * 0.1,),
                    if (!skillReleaseCheck)
                    ClosedButton(screenHeight: screenHeight, onTap: () => {setState(() {
                      questClearView = false;
                    })}, imagePath: ''),
                    if (questClear && gachaPoint > 1000 && skillReleaseCheck)
                    CustomImageButton(screenWidth: screenWidth, buttonText: '決定', onPressed: () => {purchaseSkill(1000, selectedSkillNo)})
                  ]
                ),
              ]
            ),
          ),

        if (questNotClearView && skillMode == 'quest') (
        Positioned(
          bottom: screenHeight * 0.2,
          child:Column(
            children: [
            QuestClearView(selectedCardNo: selectedSkillNo, skills: skills, questClear: questClear, screenHeight: screenHeight, screenWidth: screenWidth, releaseButtonTap: releaseSkill),
              Row (
                children: [
                  if (!questClear &&  gachaPoint > ((((int.parse(RegExp(r'\d+').stringMatch(selectedSkillNo) ?? '0')) * 300 / 1000).round()) * 1000) && !skillReleaseCheck)
                  CustomImageButton(screenWidth: screenWidth, buttonText: '強制解放', onPressed: () => {releaseSkillReal(questClear)}),
                  if(skillReleaseCheck)
                  CustomImageButton(screenWidth: screenWidth, buttonText: '閉じる', onPressed: () => {setState(() {
                    skillReleaseCheck = false;
                  })}),
                  if (!questClear &&  gachaPoint > ((((int.parse(RegExp(r'\d+').stringMatch(selectedSkillNo) ?? '0')) * 300 / 1000).round()) * 1000))
                  SizedBox(width: screenWidth * 0.1,),
                  if (!skillReleaseCheck)
                  ClosedButton(screenHeight: screenHeight, onTap: () => {setState(() {
                    questNotClearView = false;
                  })}, imagePath: ''),
                  if (!questClear &&  gachaPoint > ((((int.parse(RegExp(r'\d+').stringMatch(selectedSkillNo) ?? '0')) * 300 / 1000).round()) * 1000) && skillReleaseCheck)
                  CustomImageButton(screenWidth: screenWidth, buttonText: '決定', onPressed: () => {purchaseSkill(  ((((int.parse(RegExp(r'\d+').stringMatch(selectedSkillNo) ?? '0')) * 300 / 1000).round()) * 1000)   , selectedSkillNo)})
                ]
              )
            ]
          )
        )
      ),

        if (mySkillDetail && !(skillMode == 'quest'))
          Positioned(
            bottom: screenHeight * 0.04,
            left: screenWidth * 0.2,
            child: ClosedButton(screenHeight: screenHeight, onTap: detailSkillOff, imagePath: '')
          ),

        if (mySkillDetail && !(skillMode == 'quest') && myOwnSkillList.contains(selectedSkillNo))
          Positioned(
            bottom: screenHeight * 0.04,
            right: screenWidth * 0.2,
            child: DecideButton(screenHeight: screenHeight, onTap: () => {}, imagePath: '', onSkillSelected: onSkillSelected, skillNo: selectedSkillNo,
            buttonText: skillMode == 'speed'
            ?
            mySpeedSkillNoList.contains(selectedSkillNo) ? '装備済' : '装備'
            :
            myStrategySkillNoList.contains(selectedSkillNo) ? '装備済'  : '装備'
            )
          ),
        ],
      )
    );
  }
}

class SpeedCardListView extends StatefulWidget {
  final List<Map<String, String>> cards;
  final double screenHeight;
  final double screenWidth;
  final int selectedCardIndex;
  final Function(int) onCardTap;
  final Function(int) onCardDoubleTap;

  SpeedCardListView({
    required this.cards,
    required this.screenHeight,
    required this.screenWidth,
    required this.selectedCardIndex,
    required this.onCardTap,
    required this.onCardDoubleTap,
  });

  @override
  _SpeedCardListViewState createState() => _SpeedCardListViewState();
}

class _SpeedCardListViewState extends State<SpeedCardListView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800), // 拍動の速度
    )..repeat(reverse: true); // 拡大・縮小を繰り返す

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Positioned(
      right: 0, // 画面の右端に固定
      bottom: 0, // 画面の下端に固定
      child: Container(
        width: widget.screenWidth * 0.98,
        height: widget.screenHeight * 0.35,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: widget.cards.length,
                itemBuilder: (context, index) {
                  final bool isSelected = widget.selectedCardIndex == index;
                  String selectedNo = widget.cards[index]['No']!;
                  Map<String, String>? selectedSkill = skills.firstWhere(
                    (skill) => skill['No'] == selectedNo,
                    orElse: () => {},
                  );
                String skillName = selectedSkill['name'] ?? 'スキル名が見つかりません';

                  return GestureDetector(
                    onTap: () => widget.onCardTap(index),
                    onDoubleTap: () => widget.onCardDoubleTap(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0), // 上下に8.0のマージンを追加
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Image.asset(
                            'Images/cardView.png',
                            width: widget.screenWidth * 0.98, // カードの幅を画面の80%に設定
                            height: widget.screenWidth* 0.15, // カードの高さを指定
                            fit: BoxFit.fill, // 画像をカードサイズに合わせる
                          ),
                          Positioned(
                            left: widget.screenWidth * 0.05, // カードの左上から8.5%右へ
                            top: widget.screenWidth * 0.027, // カードの上から40.7%下へ
                            child: SvgPicture.asset(
                              'Images/' + widget.cards[index]['Type']! + '.svg', // 手の画像
                              height: widget.screenWidth * 0.075, // 手の画像のサイズ
                            ),
                          ),
                          Positioned(
                            left: widget.screenWidth * 0.2, // カードの左上から20%右へ
                            top: widget.screenWidth * 0.02, // カードの上から48%下へ
                            child: Row(
                              children: [
                                Image.asset(
                                  'Images/' + widget.cards[index]['No']! + '.png', // スキルの画像
                                  height: widget.screenWidth * 0.1,
                                  width:  widget.screenWidth * 0.1,
                                  fit: BoxFit.contain,
                                   // スキルの画像のサイズ
                                ),
                                SizedBox(width: 5), // スキル名との間にスペースを追加
                                Text(
                                  skillName,
                                  style: TextStyle(
                                    fontFamily: 'makinas4',
                                    fontSize: widget.screenWidth * 0.075,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                          Positioned(
                            top: widget.screenHeight * 0.008,
                            right: widget.screenWidth * 0.1,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Image.asset(
                                'Images/pointer.png',
                                height: widget.screenHeight * 0.04,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StrategyCardListView extends StatefulWidget {
  final List<String> cards;
  final double screenHeight;
  final double screenWidth;
  final int selectedCardIndex;
  final Function(int) onCardTap;
  final Function(int) onCardDoubleTap;

  StrategyCardListView({
    required this.cards,
    required this.screenHeight,
    required this.screenWidth,
    required this.selectedCardIndex,
    required this.onCardTap,
    required this.onCardDoubleTap,
  });

  @override
  _StrategyCardListViewState createState() => _StrategyCardListViewState();
}

class _StrategyCardListViewState extends State<StrategyCardListView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800), // 拍動の速度
    )..repeat(reverse: true); // 拡大・縮小を繰り返す

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Positioned(
      right: 0, // 画面の右端に固定
      bottom: 0, // 画面の下端に固定
      child: Container(
        width: widget.screenWidth * 0.98,
        height: widget.screenHeight * 0.35,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: widget.cards.length,
                itemBuilder: (context, index) {
                  final bool isSelected = widget.selectedCardIndex == index;
                  String selectedNo = widget.cards[index]!;
                  Map<String, String>? selectedSkill = skills.firstWhere(
                    (skill) => skill['No'] == selectedNo,
                    orElse: () => {},
                  );
                String skillName = selectedSkill?['name'] ?? 'スキル名が見つかりません';

                  return GestureDetector(
                    onTap: () => widget.onCardTap(index),
                    onDoubleTap: () => widget.onCardDoubleTap(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0), // 上下に8.0のマージンを追加
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Image.asset(
                            'Images/cardView.png',
                            width: widget.screenWidth * 0.98, // カードの幅を画面の80%に設定
                            height: widget.screenWidth* 0.15, // カードの高さを指定
                            fit: BoxFit.fill, // 画像をカードサイズに合わせる
                          ),
                          Positioned(
                            left: widget.screenWidth * 0.057, // カードの左上から8.5%右へ
                            top: widget.screenWidth * 0.002, // カードの上から40.7%下へ
                            child: Text((index + 1).toString() + '.',
                            style: TextStyle(
                                    fontFamily: 'makinas4',
                                    fontSize: widget.screenWidth * 0.075,
                                  ),)

                          ),
                          Positioned(
                            left: widget.screenWidth * 0.2, // カードの左上から20%右へ
                            top: widget.screenWidth * 0.02, // カードの上から48%下へ
                            child: Row(
                              children: [
                                Image.asset(
                                  'Images/' + widget.cards[index]! + '.png', // スキルの画像
                                  height: widget.screenWidth * 0.1,
                                  width:  widget.screenWidth * 0.1,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: 5), // スキル名との間にスペースを追加
                                Text(
                                  skillName,
                                  style: TextStyle(
                                    fontFamily: 'makinas4',
                                    fontSize: widget.screenWidth * 0.075,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: widget.screenHeight * 0.008,
                              right: widget.screenWidth * 0.1,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Image.asset(
                                  'Images/pointer.png',
                                  height: widget.screenHeight * 0.04,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestCardListView extends StatefulWidget {
  final List<String> cards;
  final double screenHeight;
  final double screenWidth;
  final int selectedCardIndex;
  final Function(int) onCardTap;
  final Function(int) onCardDoubleTap;

  QuestCardListView({
    required this.cards,
    required this.screenHeight,
    required this.screenWidth,
    required this.selectedCardIndex,
    required this.onCardTap,
    required this.onCardDoubleTap,
  });

  @override
  _QuestCardListViewState createState() => _QuestCardListViewState();
}

class _QuestCardListViewState extends State<QuestCardListView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800), // 拍動の速度
    )..repeat(reverse: true); // 拡大・縮小を繰り返す

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Positioned(
      right: 0, // 画面の右端に固定
      bottom: 0, // 画面の下端に固定
      child: Container(
        width: widget.screenWidth * 0.98,
        height: widget.screenHeight * 0.35,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: widget.cards.length,
                itemBuilder: (context, index) {
                  final bool isSelected = widget.selectedCardIndex == index;
                  String selectedNo = widget.cards[index]!;
                  RegExp regExp = RegExp(r'\d+');
                  String? noInt = regExp.stringMatch(selectedNo);
                  Map<String, String>? selectedSkill = skills.firstWhere(
                    (skill) => skill['No'] == selectedNo,
                    orElse: () => {},
                  );
                String skillName = selectedSkill['name'] ?? 'スキル名が見つかりません';

                  return GestureDetector(
                    onTap: () => widget.onCardTap(index),
                    onDoubleTap: () => widget.onCardDoubleTap(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0), // 上下に8.0のマージンを追加
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Image.asset(
                            'Images/cardView.png',
                            width: widget.screenWidth * 0.98, // カードの幅を画面の80%に設定
                            height: widget.screenWidth* 0.15, // カードの高さを指定
                            fit: BoxFit.fill, // 画像をカードサイズに合わせる
                          ),
                          Positioned(
                            right: widget.screenWidth * 0.84, // カードの左上から8.5%右へ
                            top: widget.screenWidth * 0.002, // カードの上から40.7%下へ
                            child: Text('$noInt.',
                            style: TextStyle(
                                    fontFamily: 'makinas4',
                                    fontSize: widget.screenWidth * 0.075,
                                  ),)

                          ),
                          Positioned(
                            left: widget.screenWidth * 0.2, // カードの左上から20%右へ
                            top: widget.screenWidth * 0.02, // カードの上から48%下へ
                            child: Row(
                              children: [
                                Image.asset(
                                  'Images/' + widget.cards[index]! + '.png', // スキルの画像
                                  height: widget.screenWidth * 0.1,
                                  width:  widget.screenWidth * 0.1,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: 5), // スキル名との間にスペースを追加
                                Text(
                                  skillName,
                                  style: TextStyle(
                                    fontFamily: 'makinas4',
                                    fontSize: widget.screenWidth * 0.075,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: widget.screenHeight * 0.008,
                              right: widget.screenWidth * 0.1,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Image.asset(
                                  'Images/pointer.png',
                                  height: widget.screenHeight * 0.04,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeedSkillGridWidget extends StatelessWidget {
  final List<Map<String, String>> skills;
  final List<String> mySkillNoList;
  final List<String> mySpeedSkillTypeList;
  final List<String> mySkillOwnNoList;
  final double screenHeight; // スクリーンの高さを引数として追加
  final Function(String, String) onSkillSelected;

  SpeedSkillGridWidget({
    required this.skills,
    required this.mySkillNoList,
    required this.mySpeedSkillTypeList,
    required this.mySkillOwnNoList,
    required this.screenHeight,
    required this.onSkillSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: screenHeight * 0.4, // 引数で渡されたスクリーンの高さを使用
        width: screenWidth,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            final skillNo = skills[index]["No"]!;
            final skillTypeIndex = mySkillNoList.indexOf(skillNo);
            final skillType = skillTypeIndex != -1 ? mySpeedSkillTypeList[skillTypeIndex] : null;
            final isOwned = mySkillOwnNoList.contains(skillNo);


            return GestureDetector(
              onDoubleTap: () => onSkillSelected(skillNo, 'double'),
              onTap:() => onSkillSelected(skillNo, 'single'),
              child:
              SkillCard(
                skillNo: skillNo,
                skillType: skillType,
                isUsing: skillType != null, // 装備しているかどうか
                isOwned: isOwned,
              )
            );
          },
        ),
      ),
    );
  }
}

class StrategySkillGridWidget extends StatelessWidget {
  final List<Map<String, String>> skills;
  final List<String> mySkillNoList;
  final List<String> mySkillOwnNoList;
  final double screenHeight; // スクリーンの高さを引数として追加
  final Function(String, String) onSkillSelected;

  StrategySkillGridWidget({
    required this.skills,
    required this.mySkillNoList,
    required this.mySkillOwnNoList,
    required this.screenHeight,
    required this.onSkillSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: screenHeight * 0.5, // 引数で渡されたスクリーンの高さを使用
        width: screenWidth,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: skills.length, //myOwnSkillListの長さ
          itemBuilder: (context, index) {
            final skillNo = skills[index]["No"]!;
            final skillUsing = mySkillNoList.contains(skillNo);
            final isOwned = mySkillOwnNoList.contains(skillNo);

            return GestureDetector(
              onDoubleTap: () => onSkillSelected(skillNo, 'double'),
              onTap:() => onSkillSelected(skillNo, 'single'),
              child:
              SkillCard(
                skillNo: skillNo,
                skillType: 'none',
                isUsing: skillUsing, // 装備しているかどうか
                isOwned: isOwned,
              )
            );
          },
        ),
      ),
    );
  }
}

class SkillCard extends StatelessWidget {
  final String skillNo;
  final String? skillType; // スキルタイプを追加
  final bool isOwned;
  final bool isUsing;

  const SkillCard({
    required this.skillNo,
    this.skillType,
    required this.isOwned,
    required this.isUsing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset(
                'Images/$skillNo.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.image),
              ),
              const SizedBox(height: 8),
              Text(
                skillNo,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (isUsing && skillType != 'none')
          Positioned(
            top: 0,
            right: 0,
              child: Opacity(
                opacity: 0.8, // 透明度の値（0.0が完全に透明、1.0が完全に不透明）
                child: Image.asset(
                  'Images/battleLogSkill.png',
                  width: 30,
                  height: 40,
                  fit: BoxFit.fill,
                ),
              )
            ),
          if (isUsing && skillType != 'none')
            Positioned(
              top: 12,
              right: 8,
              child: Opacity(
                opacity: 0.6,
                child:
                SvgPicture.asset(
                  'Images/$skillType.svg',
                  width: 16,
                  height: 16,
                  fit: BoxFit.fill,
                  placeholderBuilder: (context) => Icon(Icons.image),
                ),
              )
            ),
          if (isUsing && skillType == 'none')
            Positioned(
              top: 12,
              right: 8,
              child: Opacity(
                opacity: 1,
                child:
                SvgPicture.asset(
                  'Images/skillActive.svg',
                  width: 20,
                  height: 20,
                  fit: BoxFit.fill,
                  placeholderBuilder: (context) => Icon(Icons.image),
                ),
              )
            ),
          // else if (!isOwned)
          //   Positioned(
          //     top: 10,
          //     right: 6,
          //     child: Icon(Icons.lock, size: 20), // 所有していないスキルのデフォルトマーク
          //   ),
        ],
      ),
    );
  }
}

class CardDetailView extends StatefulWidget {
  final String selectedCardNo;
  final List<Map<String, String>> skills;
  final List<String> skillNoList;
  final List<String> skillOwnList;
  final List<String> skillTypeList;
  final double screenHeight;
  final double screenWidth;

  CardDetailView({
    required this.selectedCardNo,
    required this.skills,
    required this.skillNoList,
    required this.skillOwnList,
    required this.skillTypeList,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  _CardDetailViewState createState() => _CardDetailViewState();
}


class _CardDetailViewState extends State<CardDetailView> {
  int useCount = 0;
  int activeCount = 0;
  double activeRate = 0.0;

  //クエストの条件
  int userWinCount = 0;
  int userLoseCount = 0;
  int userBattleCount = 0;
  int userHonestCount = 0;
  int userAllHandCount = 0;
  int userNotHonestCount = 0;
  int userWinStreak = 0;
  int userLevel = 1;
  List<int> skillUseCountList = [-1];
  List<int> skillActiveCountList = [-1];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  @override
  void didUpdateWidget(covariant CardDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // selectedCardNo が変更された場合のみ処理を実行
    if (widget.selectedCardNo != oldWidget.selectedCardNo) {
      _loadPreferences();
    }
  }
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

      setState(() {
        useCount = 0;
        activeCount = 0;
        activeRate = 0.0;
        useCount = prefs.getInt('mySkillCount_${widget.selectedCardNo}') ?? 0;
        activeCount = prefs.getInt('mySkillActive_${widget.selectedCardNo}') ?? 0;
        userLevel = prefs.getInt('myLevel') ?? 1;
        userWinCount = prefs.getInt('myWinCount') ?? 0;
        userAllHandCount = (prefs.getInt('myRockCount') ?? 0) + (prefs.getInt('myScissorCount') ?? 0) + (prefs.getInt('myPaperCount') ?? 0);
        userHonestCount = prefs.getInt('myHonestCount') ?? 0;
        userNotHonestCount = userAllHandCount - userHonestCount;
        userBattleCount = prefs.getInt('myBattleCount') ?? 0;
        userLoseCount = userBattleCount - userWinCount;
        userWinStreak = prefs.getInt('myWinStreak') ?? 0;
      });
      if (useCount != 0){
        activeRate = ((activeCount / useCount) * 1000).round() / 10;
      }
      for (int i = 0; i < skills.length; i++) {
        skillUseCountList.add(prefs.getInt('mySkillCount_No${i + 1}') ?? 0);
        skillActiveCountList.add(prefs.getInt('mySkillActive_No${i + 1}') ?? 0);
      }
    }


  @override
  Widget build(BuildContext context) {
    String selectedType = 'none';
    Map<String, String>? selectedSkill = skills.firstWhere(
      (skill) => skill['No'] == widget.selectedCardNo,
      orElse: () => {}, // 見つからなかった場合はnullを返す
    );
    int selectedIndex = widget.skillNoList.indexWhere((skillNo) => skillNo == widget.selectedCardNo);
    if (widget.skillTypeList.isNotEmpty){
      selectedType = (selectedIndex != -1) ? widget.skillTypeList[selectedIndex] : '';
    }
    int selectedCardNoIndex = int.parse(RegExp(r'\d+').stringMatch(widget.selectedCardNo) ?? '0') - 1;

    return Stack(
      children: [
        // 背景画像のサイズと位置調整
        Image.asset(
          'Images/cardDetail.png',

          width: widget.screenWidth * 0.9,
          fit: BoxFit.cover,
        ),

        // 前面のカード詳細 (右上に画像)
        if (widget.skillNoList.contains(widget.selectedCardNo) && widget.skillOwnList.contains(widget.selectedCardNo))
        Positioned(
          top: widget.screenWidth * 0.054,
          right: widget.screenWidth * 0.095,
          child: SvgPicture.asset(
            widget.skillTypeList.isEmpty ? 'Images/skillActive.svg' : 'Images/$selectedType.svg',
            width: widget.screenWidth * 0.1,
          ),
        ),

        if (!widget.skillOwnList.contains(widget.selectedCardNo))
        Positioned(
          top: widget.screenWidth * 0.054,
          right: widget.screenWidth * 0.095,
          child: Icon(
            widget.skillTypeList.isEmpty ? Icons.lock : Icons.lock_open, // 条件に応じて変更可能
            size: widget.screenWidth * 0.1, // 大きさを指定
            color: Colors.black, // 必要に応じて色を指定
          ),
        ),

        Positioned(
          top: widget.screenWidth * 0.16,
          left: widget.screenWidth * 0.17,
          child: Image.asset(
            'Images/' + (selectedSkill['No'] ?? 'No0') + '.png',
            width: widget.screenWidth * 0.27,
            height: widget.screenWidth * 0.27,
          ),
        ),

        Positioned(
          top: widget.screenWidth * 0.2,
          left: widget.screenWidth * 0.55,
          child: Text(
            '使用回数:$useCount回',
              style: TextStyle(
                fontFamily: 'makinas4',
                fontSize: widget.screenWidth * 0.04,
              ),
            ),
        ),

        Positioned(
          top: widget.screenWidth * 0.3,
          left: widget.screenWidth * 0.55,
          child: Text(
            '発動回数:$activeCount回',
              style: TextStyle(
                fontFamily: 'makinas4',
                fontSize: widget.screenWidth * 0.04,
              ),
            ),
        ),

        Positioned(
          top: widget.screenWidth * 0.02,
          left: widget.screenWidth * 0.05,
          child: Text(
            (selectedSkill['No'] ?? 'unknown') + ' ' + (selectedSkill['name'] ?? 'unknown'),
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: widget.screenWidth * 0.065,
            ),
          ),
        ),

        // 説明テキスト (下側中央)
        if ((widget.skillOwnList.contains(widget.selectedCardNo)))
        Positioned(
          top: widget.screenWidth * 0.5,
          left: widget.screenWidth * 0.1,
          right: widget.screenWidth * 0.1,
          bottom: widget.screenWidth * 0.1,
          child: SingleChildScrollView(
          child: Text(
            selectedSkill['description'] ?? '',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: widget.screenHeight * 0.02, // フォントサイズを調整
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        ),

      ],
    );
  }
}

class QuestDetailView extends StatefulWidget {
  final String selectedCardNo;
  final List<Map<String, String>> skills;
  final List<String> skillNoList;
  final List<String> skillOwnList;
  final List<String> skillTypeList;
  final List<String> skillWinRateList;
  final List<int> skillUseCountList;
  final List<int> skillActiveCountList;
  final double screenHeight;
  final double screenWidth;
  final Function(bool) releaseButtonTap;

  QuestDetailView({
    required this.selectedCardNo,
    required this.skills,
    required this.skillNoList,
    required this.skillOwnList,
    required this.skillTypeList,
    required this.skillWinRateList,
    required this.skillUseCountList,
    required this.skillActiveCountList,
    required this.screenHeight,
    required this.screenWidth,
    required this.releaseButtonTap,

  });

  @override
  _QuestDetailViewState createState() => _QuestDetailViewState();
}


class _QuestDetailViewState extends State<QuestDetailView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  int useCount = 0;
  int activeCount = 0;
  double activeRate = 0.0;

  //クエストの条件
  bool questClear = true;
  int userWinCount = 0;
  int userLoseCount = 0;
  int userBattleCount = 0;
  int userHonestCount = 0;
  int userAllHandCount = 0;
  int userNotHonestCount = 0;
  int userWinStreak = 0;
  int userLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // アニメーションコントローラーの初期化
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // 短いアニメーション
    );

    // 縮小アニメーション
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose(); // コントローラーの破棄
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuestDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // selectedCardNo が変更された場合のみ処理を実行
    if (widget.selectedCardNo != oldWidget.selectedCardNo) {
      _loadPreferences();
    }
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

      setState(() {
        useCount = 0;
        activeCount = 0;
        activeRate = 0.0;
        useCount = prefs.getInt('mySkillCount_${widget.selectedCardNo}') ?? 0;
        activeCount = prefs.getInt('mySkillActive_${widget.selectedCardNo}') ?? 0;
        userLevel = prefs.getInt('myLevel') ?? 1;
        userWinCount = prefs.getInt('myWinCount') ?? 0;
        userAllHandCount = (prefs.getInt('myRockCount') ?? 0) + (prefs.getInt('myScissorCount') ?? 0) + (prefs.getInt('myPaperCount') ?? 0);
        userHonestCount = prefs.getInt('myHonestCount') ?? 0;
        userNotHonestCount = userAllHandCount - userHonestCount;
        userBattleCount = prefs.getInt('myBattleCount') ?? 0;
        userLoseCount = userBattleCount - userWinCount;
        userWinStreak = prefs.getInt('myWinStreak') ?? 0;
      });
      if (useCount != 0){
        activeRate = ((activeCount / useCount) * 1000).round() / 10;
      }
    }


  @override
  Widget build(BuildContext context) {
    String selectedType = 'none';
    Map<String, String>? selectedSkill = skills.firstWhere(
      (skill) => skill['No'] == widget.selectedCardNo,
      orElse: () => {}, // 見つからなかった場合はnullを返す
    );
    int selectedIndex = widget.skillNoList.indexWhere((skillNo) => skillNo == widget.selectedCardNo);
    if (widget.skillTypeList.isNotEmpty){
      selectedType = (selectedIndex != -1) ? widget.skillTypeList[selectedIndex] : '';
    }
    int selectedCardNoIndex = int.parse(RegExp(r'\d+').stringMatch(widget.selectedCardNo) ?? '0') - 1;
    final questDetails = (selectedSkill['quest'] ?? '解放条件は謎に包まれている')
        .split('\n')
        .map((condition) => condition.trim())
        .toList();
    questClear = true;
    // 各条件の達成状況を記述
    final conditionsWithStatus = questDetails.map((condition) {
      String status = '';
      if (condition.contains('レベル')) {
        RegExp regex = RegExp(r'レベル(\d+)');
        Match? match = regex.firstMatch(condition);
        if (match != null) {
          int? clearCount = int.tryParse(match.group(1)!);
          if (userLevel >= clearCount!){
            status = '→達成！($userLevel / $clearCount)';
          } else {
            status = '→達成率${(userLevel/clearCount * 100).round()}% ($userLevel / $clearCount)';
            print('level fail');
            questClear = false;
            print('$questClear');
          }
        }
      } else if (condition.contains('勝つ')) {
        RegExp regex = RegExp(r'試合で(\d+)');
        Match? match = regex.firstMatch(condition);
        if (match != null) {
          int? clearCount = int.tryParse(match.group(1)!);
          if (userWinCount >= clearCount!){
            status = '→達成！($userWinCount / $clearCount)';
          } else {
            status = '→達成率${(userWinCount/clearCount * 100).round()}% ($userWinCount / $clearCount)';
            print('winCOunt fail');
            questClear = false;
          }
        }
      } else if (condition.contains('負ける')) {
        RegExp regex = RegExp(r'試合で(\d+)');
        Match? match = regex.firstMatch(condition);
        if (match != null) {
          int? clearCount = int.tryParse(match.group(1)!);
          if (userLoseCount >= clearCount!){
            status = '→達成！($userLoseCount / $clearCount)';
          } else {
            status = '→達成率${(userLoseCount/clearCount * 100).round()}% ($userLoseCount / $clearCount)';
            print('loseCOunt fail');
            questClear = false;
          }
        }
      } else if (condition.contains('宣言した')) {
        RegExp regex = RegExp(r'手を(\d+)');
        Match? match = regex.firstMatch(condition);
        if (match != null) {
          int? clearCount = int.tryParse(match.group(1)!);
          if (userHonestCount >= clearCount!){
            status = '→達成！($userHonestCount / $clearCount)';
          } else {
            status = '→達成率${(userHonestCount/clearCount * 100).round()}% ($userHonestCount / $clearCount)';
            print('honest fail');
            questClear = false;
          }
        }
      } else if (condition.contains('宣言していない')) {
        RegExp regex = RegExp(r'手を(\d+)');
        Match? match = regex.firstMatch(condition);
        if (match != null) {
          int? clearCount = int.tryParse(match.group(1)!);
          if (userNotHonestCount >= clearCount!){
            status = '→達成！($userNotHonestCount / $clearCount)';
          } else {
            status = '→達成率${(userNotHonestCount/clearCount * 100).round()}% ($userNotHonestCount / $clearCount)';
            print('not honest fail');
            questClear = false;
          }
        }
      } else if (condition.contains('No')) {
        RegExp regex = RegExp(r'No(\d+)');
        Match? match = regex.firstMatch(condition);
        if (match != null) {
          int? skillNo = int.tryParse(match.group(1)!);
          if (condition.contains('発動')) {
            RegExp regex1 = RegExp(r'」を(\d+)');
            Match? match1 = regex1.firstMatch(condition);
            if (match1 != null){
              int? clearCount = int.tryParse(match1.group(1)!);
              if (widget.skillActiveCountList[skillNo ?? 0] >= clearCount!) {
                status = '→達成！(${widget.skillActiveCountList[skillNo ?? 0]} / $clearCount)';
              } else {
                status = '→達成率${(widget.skillActiveCountList[skillNo ?? 0]/clearCount * 100).round()}% (${widget.skillActiveCountList[skillNo ?? 0]} / $clearCount)';
                print('active fail');
                questClear = false;
              }
            }
          } else if (condition.contains('使用')) {
            RegExp regex1 = RegExp(r'」を(\d+)');
            Match? match1 = regex1.firstMatch(condition);
            if (match1 != null){
              int? clearCount = int.tryParse(match1.group(1)!);
              if (widget.skillActiveCountList[skillNo!] >= clearCount!) {
                status = '→達成！(${widget.skillUseCountList[skillNo]} / $clearCount)';
              } else {
                status = '→達成率${(widget.skillUseCountList[skillNo]/clearCount * 100).round()}% (${widget.skillUseCountList[skillNo]} / $clearCount)';
                print('use fail');
                questClear = false;
              }
            }
          }
        }
      } else if (condition.contains('連勝')) {
        RegExp regex = RegExp(r'試合で(\d+)');
        Match? match = regex.firstMatch(condition);
        if (match != null) {
          int? clearCount = int.tryParse(match.group(1)!);
          if (userWinStreak >= clearCount!){
            status = '→達成！($userWinStreak / $clearCount)';
          } else {
            status = '→達成率${(userWinStreak/clearCount * 100).round()}% ($userWinStreak / $clearCount)';
            print('win streak fail');
            questClear = false;
          }
        }
      } else {
        status = '未確認の条件';
      }

      if (status != '') {
        return '$condition\n$status';
      } else {
        return condition;
      }
    }).toList();

    buttonTap() {
      setState(() {
        _controller.forward();
      });
      Future.delayed(Duration(milliseconds: 200), () {
        setState(() {
          _controller.reverse();
        });
      });
      widget.releaseButtonTap(questClear);
    }

    return Stack(
      children: [
        // 背景画像のサイズと位置調整
        Image.asset(
          'Images/questDetail.png',

          width: widget.screenWidth * 0.9,
          height: widget.screenHeight * 0.5,
          fit: BoxFit.fill,
        ),

        if (!widget.skillOwnList.contains(widget.selectedCardNo))
        Positioned(
          top: widget.screenHeight * 0.02,
          right: widget.screenWidth * 0.11,
          child: Icon(
            !questClear ? Icons.lock : Icons.lock_open, // 条件に応じて変更可能
            size: widget.screenWidth * 0.1, // 大きさを指定
            color: Colors.black, // 必要に応じて色を指定
          ),
        ),

        Positioned(
          top: widget.screenWidth * 0.16,
          left: widget.screenWidth * 0.17,
          child: Image.asset(
            'Images/' + (selectedSkill['No'] ?? 'No0') + '.png',
            width: widget.screenWidth * 0.26,
            height: widget.screenHeight * 0.1,
            fit: BoxFit.contain
          ),
        ),

        Positioned(
          top: widget.screenWidth * 0.02,
          left: widget.screenWidth * 0.05,
          child: Text(
            (selectedSkill['No'] ?? 'unknown') + ' ' + (selectedSkill['name'] ?? 'unknown'),
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: widget.screenWidth * 0.065,
            ),
          ),
        ),

        Positioned(
          top: widget.screenHeight * 0.08,
          right: widget.screenWidth * 0.05,
          child: Stack(
            children: [
              GestureDetector(
                onTapDown: (_) => _controller.forward(), // 縮むアニメーション開始
                onTapUp: (_) {
                  _controller.reverse(); // 元のサイズに戻る
                  // 必要な処理をここに追加 (例: ボタンのクリック処理)
                  print("ボタンが押されました！");
                },
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: CustomImageButton(screenWidth: widget.screenWidth, buttonText: questClear ? '解放する' : '強制解放' , onPressed: buttonTap,)
                ),
              ),
            ]
          ),
        ),

        if (!(widget.skillOwnList.contains(widget.selectedCardNo)))
        Positioned(
          top: widget.screenHeight * 0.21,
          left: widget.screenWidth * 0.1,
          right: widget.screenWidth * 0.1,
          bottom: widget.screenHeight * 0.04,
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                questClear ? '解放可能！' : '未達成！',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget.screenHeight * 0.025, // フォントサイズを調整
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                conditionsWithStatus.join('\n\n'),
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget.screenHeight * 0.02, // フォントサイズを調整
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 20,),
              Text(
                'スキルの効果',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget.screenHeight * 0.025, // フォントサイズを調整
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                selectedSkill['description'] ?? '説明はない',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget.screenHeight * 0.02, // フォントサイズを調整
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.left,
              ),
            ]
          ),
        ),
        ),
      ],
    );
  }
}

class QuestClearView extends StatefulWidget {
  final String selectedCardNo;
  final List<Map<String, String>> skills;
  final bool questClear;
  final double screenHeight;
  final double screenWidth;
  final Function(bool) releaseButtonTap;

  QuestClearView({
    required this.selectedCardNo,
    required this.skills,
    required this.questClear,
    required this.screenHeight,
    required this.screenWidth,
    required this.releaseButtonTap,
  });

  @override
  _QuestClearViewState createState() => _QuestClearViewState();
}


class _QuestClearViewState extends State<QuestClearView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int nowGachaPoint = 0;


  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        nowGachaPoint = prefs.getInt('myGachaPoint') ?? 10000;
      });
    }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // アニメーションコントローラーの初期化
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // 短いアニメーション
    );

    // 縮小アニメーション
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose(); // コントローラーの破棄
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String>? selectedSkill = skills.firstWhere(
      (skill) => skill['No'] == widget.selectedCardNo,
      orElse: () => {}, // 見つからなかった場合はnullを返す
    );
    int selectedCardNoIndex = int.parse(RegExp(r'\d+').stringMatch(widget.selectedCardNo) ?? '0');
    buttonTap() {
      setState(() {
        _controller.forward();
      });
      Future.delayed(Duration(milliseconds: 200), () {
        setState(() {
          _controller.reverse();
        });
      });
      widget.releaseButtonTap(widget.questClear);
    }

    return Stack(
      children: [
        // 背景画像のサイズと位置調整
        Image.asset(
          'Images/questView.png',
          width: widget.screenWidth,
          height: widget.screenHeight * 0.5,
          fit: BoxFit.fill,
        ),

        Positioned(
          top: widget.screenHeight * 0.023,
          right: widget.screenWidth * 0.087,
          child: Icon(
            !widget.questClear ? Icons.lock : Icons.lock_open, // 条件に応じて変更可能
            size: widget.screenWidth * 0.15, // 大きさを指定
            color: Colors.black, // 必要に応じて色を指定
          ),
        ),

        Positioned(
          top: widget.screenWidth * 0.2,
          left: widget.screenWidth * 0.27,
          child: Image.asset(
            'Images/' + (selectedSkill['No'] ?? 'No0') + '.png',
            width: widget.screenWidth * 0.45,
            height: widget.screenHeight * 0.18,
            fit: BoxFit.contain
          ),
        ),

        Positioned(
          top: widget.screenWidth * 0.02,
          left: widget.screenWidth * 0.05,
          child: Text(
            (selectedSkill['No'] ?? 'unknown') + ' ' + (selectedSkill['name'] ?? 'unknown'),
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: widget.screenWidth * 0.078,
            ),
          ),
        ),

        Positioned(
          bottom: widget.screenHeight * 0.04,
          child:
          Container(
            width: widget.screenWidth,
            child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ガチャメダル',
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: widget.screenWidth * 0.06,
                    ),
                  ),

                  Icon(
                    Icons.military_tech, // 条件に応じて変更可能
                    size: widget.screenWidth * 0.15, // 大きさを指定
                    color: Colors.black, // 必要に応じて色を指定
                  ),

                  Text(
                    widget.questClear ? '1000枚' : '${((selectedCardNoIndex * 300 / 1000).round()) * 1000}枚',
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: widget.screenWidth * 0.06,
                      fontWeight: FontWeight.bold
                    ),
                  ),





                ]
              ),

              Text(
                widget.questClear ? 'で解放する' : 'で強制解放する',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget.screenWidth * 0.06,
                ),
              ),

              Text(
                '現在:$nowGachaPoint枚',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget.screenWidth * 0.05,
                ),
              ),

            ]
          )
          )
        ),
      ],
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
          bottom: widget.screenHeight * 0.2, // Center vertically
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

class MovingRightImage extends StatefulWidget {
  final VoidCallback onTap; // The function to execute on tap
  final double screenHeight;
  final double screenWidth;

  const MovingRightImage({
    Key? key,
    required this.onTap,
    required this.screenHeight,
    required this.screenWidth,
  }) : super(key: key);

  @override
  _MovingRightImageState createState() => _MovingRightImageState();
}

class _MovingRightImageState extends State<MovingRightImage> with SingleTickerProviderStateMixin {
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
          right: _animation.value,
          bottom: widget.screenHeight * 0.2, // Center vertically
          child:
          GestureDetector(
            onTap: widget.onTap,
            child: Image.asset(
              'Images/right.png',
              width: 50,
              height: 50,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedImageView extends StatefulWidget {
  final double screenHeight;
  final VoidCallback onTap;
  final String imagePath;

  const AnimatedImageView({
    Key? key,
    required this.screenHeight,
    required this.onTap,
    required this.imagePath,
  }) : super(key: key);

  @override
  _AnimatedImageViewState createState() => _AnimatedImageViewState();
}

class _AnimatedImageViewState extends State<AnimatedImageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTap() async {
    widget.onTap();
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child:
        Stack(
          children: [
            Image.asset(
              'Images/battleLogSkill.png',
              height: widget.screenHeight * 0.1,
            ),
            Positioned(
              top: widget.screenHeight * 0.02,
              left: widget.screenHeight * 0.029,

              child:
              SvgPicture.asset(
                widget.imagePath,
                height: widget.screenHeight * 0.06,
                fit: BoxFit.contain,
              ),
            ),
          ]
        ),
      )
    );
  }
}

class ClosedButton extends StatefulWidget {
  final double screenHeight;
  final VoidCallback onTap;
  final String imagePath;

  const ClosedButton({
    Key? key,
    required this.screenHeight,
    required this.onTap,
    required this.imagePath,
  }) : super(key: key);

  @override
  _ClosedButtonState createState() => _ClosedButtonState();
}

class _ClosedButtonState extends State<ClosedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTap() async {
    widget.onTap();
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child:
        Stack(
          children: [
            Image.asset(
              'Images/button.png',
              height: widget.screenHeight * 0.05,
            ),
            Positioned(
              top: widget.screenHeight * 0.012,
              left: widget.screenHeight * 0.037,

              child:
              Text('閉じる',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontWeight: FontWeight.bold,
                  fontSize: widget.screenHeight * 0.02,
                ),
              ),
            ),
          ]
        ),
      )
    );
  }
}

class DecideButton extends StatefulWidget {
  final double screenHeight;
  final VoidCallback onTap;
  final String imagePath;
  final Function(String, String) onSkillSelected;
  final String skillNo;
  final String buttonText;

  const DecideButton({
    Key? key,
    required this.screenHeight,
    required this.onTap,
    required this.imagePath,
    required this.onSkillSelected,
    required this.skillNo,
    required this.buttonText,
  }) : super(key: key);

  @override
  _DecideButtonState createState() => _DecideButtonState();
}

class _DecideButtonState extends State<DecideButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTap() async {
    widget.onTap();
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 両方の関数を呼び出す
        widget.onTap();
        widget.onSkillSelected(widget.skillNo, 'double');
        _onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child:
        Stack(
          children: [
            Image.asset(
              'Images/button.png',
              height: widget.screenHeight * 0.05,
            ),
            if(widget.buttonText == '装備')
            Positioned(
              top: widget.screenHeight * 0.012,
              left: widget.screenHeight * 0.045,

              child:
              Text(widget.buttonText,
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontWeight: FontWeight.bold,
                  fontSize: widget.screenHeight * 0.02,
                ),
              ),
            ),
            if(widget.buttonText == '装備済')
            Positioned(
              top: widget.screenHeight * 0.012,
              left: widget.screenHeight * 0.037,

              child:
              Text(widget.buttonText,
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontWeight: FontWeight.bold,
                  fontSize: widget.screenHeight * 0.02,
                ),
              ),
            ),
          ]
        ),
      )
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




