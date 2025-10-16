import 'package:flutter/material.dart';
import '../main.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MasFillScreen extends StatefulWidget {
  @override
  _MasFillScreenState createState() => _MasFillScreenState();
}

class _MasFillScreenState extends State<MasFillScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<List<String>> grid = [];
  List<List<String>> detailGrid = [];
  Color selectedColor = Colors.blue; // 初期色
  bool tileDetail = false;
  bool drawMode = true; //falseは色をコピーするモード
  String loadingState = 'load'; //load setting finish



  final int gridNumber = 128; // グリッドのサイズ（10x10）
  String docIdHead = 'free16_';
  Map<String, String> docIdHeadMap = {
    'free16_': 'フリー',
    'fun16_': '面白系',
    'beautiful16_': '美しい系',
    'cute16_': 'カワイイ系',
    'horror16_': 'ちょっと怖い系',
    'mystery16_': '不気味系',
    'retro16_': 'レトロ系',
    'anime16_': 'アニメ系',
    'game16_': 'ゲーム系',
    'cool16_': 'かっこいいやつ',
    'daily16_': '日常系',
    'honobono16_': 'ほのぼの',
  };
  int pixelNumber = 16;


  List<Map<String, dynamic>> pendingChanges = [];// 変更を保存するリスト
  int selectedTile = -1;
  BannerAd? _bannerAd;

  final List<Color> colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
    Colors.teal,
  ];

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
    setState(() {
      grid = List.generate(gridNumber, (_) => List.filled(gridNumber, "7d9549"));
    });
    print(grid);
    // createDocuments();
    // createGridFields();
    _loadGrid();
  }

  Future<void> createDocuments() async {
    final firestore = FirebaseFirestore.instance;

    // `masFill`コレクションを取得
    final masFillCollection = firestore.collection('masFill');

    for (int i = 1; i <= 64; i++) {
      String docId = '$docIdHead$i'; // ドキュメントIDを指定
      try {
        await masFillCollection.doc(docId).set({
          'createdAt': FieldValue.serverTimestamp(), // 任意のフィールドを設定
        });
        print('Document $docId created successfully!');
      } catch (e) {
        print('Error creating document $docId: $e');
      }
    }
  }

  Future<void> createGridFields() async { //フィールドの初期化
  final firestore = FirebaseFirestore.instance;
  setState(() {
    loadingState = 'load';
  });

  // `masFill`コレクションを取得
  final masFillCollection = firestore.collection('masFill');

  // ランダムな色を生成する関数
  String getRandomColor(int i) {
    // RGB値をランダムに生成
    int b = 3 * i; // 0〜255
    int g = 1 * i; // 0〜255
    int r = 100; // 0〜255
    // 16進数に変換して返す
    return '${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  // gridフィールドに設定するデータ
  List<String> gridField = List<String>.generate(pixelNumber * pixelNumber, (index) => getRandomColor(0));

  for (int i = 1; i <= 64; i++) {
    String docId = '$docIdHead$i'; // ドキュメントIDを指定
    gridField = List<String>.generate(pixelNumber * pixelNumber, (index) => getRandomColor(i));
    try {
      await masFillCollection.doc(docId).set({
        'grid': gridField,
      });
      print('Grid field created for document $docId');
    } catch (e) {
      print('Error creating grid field for document $docId: $e');
    }
  }
  setState(() {
    loadingState = 'finish';
  });
}

   Future<void> _loadGrid() async { //画面全体をロード
    final firestore = FirebaseFirestore.instance;
    setState(() {
      tileDetail = false;
      loadingState = 'load';
    });

    // `masFill`コレクションの中から`fun1`から`fun64`までのドキュメントを取得
    List<List<String>> allGrids = [];
    for (int i = 1; i <= 64; i++) {
      String docId = '$docIdHead$i'; // ドキュメントID
      try {
        // ドキュメントを取得
        DocumentSnapshot doc = await firestore.collection('masFill').doc(docId).get();
        if (doc.exists) {
          // `grid`フィールドを取得してリストに格納
          allGrids.add(List<String>.from((doc['grid'] as List).map((e) => e.toString())));
          print(docId);
        } else {
          print('Document $docId not found');
        }
      } catch (e) {
        print('Error loading grid for $docId: $e');
      }
    }

    setState(() {
      loadingState = 'setting';
    });

    // すべてのグリッドがロードされたら、状態を更新
    setState(() {
      grid = List.generate(gridNumber, (y) {
        return List.generate(gridNumber, (x) {
          // タイルのインデックスを計算
          int tileX = x ~/ pixelNumber;
          int tileY = y ~/ pixelNumber;
          int tileIndex = tileY * 8 + tileX;

          // タイル内のローカル座標
          int localX = x % pixelNumber;
          int localY = y % pixelNumber;

          // `allGrids`の中から、該当するタイルの色を取得して返す
          return allGrids[tileIndex][localY * pixelNumber + localX];
        });
      });
      loadingState = 'finish';
    });
  }

  Future<void> _loadSpecificGrid(int tileNumber)async {
  final firestore = FirebaseFirestore.instance;
  setState(() {
    tileDetail = false;
    loadingState = 'load';
  });

  // `masFill`コレクションから、指定された `targetDocId` のみを取得
  List<List<String>> allGrids = [];
  try {
    // ドキュメントを取得
    DocumentSnapshot doc = await firestore.collection('masFill').doc('$docIdHead${tileNumber + 1}').get();
    if (doc.exists) {
      // `grid`フィールドを取得してリストに格納
      allGrids.add(List<String>.from((doc['grid'] as List).map((e) => e.toString())));
    } else {
    }
  } catch (e) {
    print(e);
  }

  setState(() {
    loadingState = 'setting';
  });
  // すべてのグリッドがロードされたら、状態を更新
  setState(() {
    // 特定のタイルだけ更新
    grid = List.generate(gridNumber, (y) {
      return List.generate(gridNumber, (x) {
        // タイルのインデックスを計算
        int tileX = x ~/ pixelNumber;
        int tileY = y ~/ pixelNumber;
        int tileIndex = tileY * 8 + tileX;

        // タイル内のローカル座標
        int localX = x % pixelNumber;
        int localY = y % pixelNumber;

        // 更新したいターゲットのタイルの場合、そのデータをセット
        if (tileIndex == tileNumber) { // `targetDocIdIndex` をそのターゲットタイルに対応するインデックスに置き換えてください
          return allGrids[0][localY * pixelNumber + localX];
        } else {
          // それ以外は元の `grid` 値を保持
          return grid[y][x];
        }
      });
    });
    loadingState = 'finish';
  });
}


  Future<void> _loadDeitalGrid() async { //タイル１枚のピクセルアートをロード
    final firestore = FirebaseFirestore.instance;
    setState(() {
      pendingChanges = [];
    });

    // `masFill`コレクションの中から`fun1`から`fun64`までのドキュメントを取得
    List<List<String>> allGrids = [];
    String docId = '$docIdHead${selectedTile + 1}'; // ドキュメントID
    try {
      // ドキュメントを取得
      DocumentSnapshot doc = await firestore.collection('masFill').doc(docId).get();
      if (doc.exists) {
        // `grid`フィールドを取得してリストに格納
        allGrids.add(List<String>.from((doc['grid'] as List).map((e) => e.toString())));
        print(docId);
      } else {
        print('Document $docId not found');
      }
    } catch (e) {
      print('Error loading grid for $docId: $e');
    }


    // すべてのグリッドがロードされたら、状態を更新
    setState(() {
      // 8×8のタイルを80×80のグリッドに変換
      detailGrid = List.generate(pixelNumber, (y) {
        return List.generate(pixelNumber, (x) {
          // タイルのインデックスを計算
          int tileX = x ~/ pixelNumber;
          int tileY = y ~/ pixelNumber;
          int tileIndex = tileY * 8 + tileX;

          // タイル内のローカル座標
          int localX = x % pixelNumber;
          int localY = y % pixelNumber;

          // `allGrids`の中から、該当するタイルの色を取得して返す
          return allGrids[tileIndex][localY * pixelNumber + localX];
        });
      });
      tileDetail = true;
    });
  }


  void handleTap(int row, int col) {
    if (pendingChanges.length > 500) {
      return;
    }
  setState(() {
    detailGrid[col][row] = selectedColor.value.toRadixString(16); // カラーコードを保存

    // 現在の時刻を記録してリストに追加
    pendingChanges.add({
      "row": row,
      "col": col,
      "color": selectedColor.value.toRadixString(16), // 選択された色
      "timestamp": DateTime.now().toIso8601String(), // ISO 8601形式の日時
    });

    print(selectedColor.value.toRadixString(16));
    print("変更リスト: $pendingChanges");
  });
}

  void saveChanges() async {
  if (pendingChanges.isEmpty) {
    print("変更がありません。");
    return; // 変更がなければ終了
  }


  // 先頭の変更時間を取得
  DateTime firstChangeTime = DateTime.parse(pendingChanges.first['timestamp'] as String);
  DateTime currentTime = DateTime.now();

  // 経過時間を計算
  Duration elapsed = currentTime.difference(firstChangeTime);

  if (elapsed.inMinutes >= 5) {
    print("変更から10分以上経過したため保存できません。");
    return; // 10分以上経過していたら保存しない
  }

  // 保存処理
  setState(() {
    pendingChanges.clear();
  });

  List<String> flatGrid = detailGrid.expand((row) => row).toList();
  await _firestore.collection('masFill').doc('$docIdHead${selectedTile + 1}').set({
    'grid': flatGrid,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  print("変更を保存しました。");
}

  void openColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("色を選択"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              setState(() {
                selectedColor = color;
              });
            },
            showLabel: false,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("閉じる"),
          ),
        ],
      ),
    );
  }

  void _selectTile(int tileIndex) {
    setState(() {
      selectedTile = tileIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

        final cellSize = screenWidth / (pixelNumber + 10);
    return Scaffold(
      body: Column(
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
                      onTap: (){
                        if (!tileDetail) {
                        context.go('/miniGame');
                        } else {
                          _loadSpecificGrid(selectedTile);
                        }
                      },
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                    ),
                  ],
                ),
              ),
              Text('お絵かき掲示板', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.05), ),
              Spacer(),
              if (loadingState == 'finish')
              DropdownButton<String>(
              value: docIdHead,
              items: docIdHeadMap.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key, // 実際の値
                  child: Text(entry.value, style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline),), // 表示名
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null && loadingState == 'finish') {
                  setState(() {
                    docIdHead = newValue;
                  });
                  // createGridFields();
                  _loadGrid();
                }
              },
            ),
            if(loadingState != 'finish')
            Text('読み込み中', style: TextStyle(fontFamily: 'makinas4'),),
            ],
          ),
          SizedBox(height: 15,),
          if (loadingState == 'load')
          CircularProgressIndicator(),
          if (loadingState == 'setting')
          Text('データ取得完了、反映中', style: TextStyle(fontFamily: 'makinas4',fontSize: screenWidth * 0.05),),
          if (!tileDetail)
          SizedBox(
            height: screenWidth + 30,
            width: screenWidth,
            child:
          Column(
            children: [
              if (selectedTile != -1)
              Text('選択中：上から${(selectedTile ~/ 8 ) + 1}左から${(selectedTile % 8) + 1}', style: TextStyle(fontFamily: 'makinas4',fontSize: screenWidth * 0.05),),
              if (selectedTile == -1)
              Text('編集したい部分を選択してください', style: TextStyle(fontFamily: 'makinas4',fontSize: screenWidth * 0.05),),
              Stack(
                children: [
                  // 下に表示するピクセルアート

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gridNumber, (x) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(gridNumber, (y) {
                          return GestureDetector(
                            onTap: () => (){},
                            child: Container(
                              width: screenWidth / (gridNumber + 10),
                              height: screenWidth / (gridNumber + 10),
                              color: Color(int.parse('0xFF' + grid[x][y])), // 通常の色
                              margin: EdgeInsets.all(0),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(8, (x) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(8, (y) {
                          return GestureDetector(
                            onTap: () => _selectTile((x * 8 + y)), // クリック時に色を変更
                            child: Container(
                              width: (screenWidth   / (gridNumber + 10)) * pixelNumber,
                              height: (screenWidth   / (gridNumber + 10)) * pixelNumber,
                              color: Color(selectedTile == x * 8 + y
                                  ? 0x77000000  // 半透明の黒（アルファ値33）
                                  : 0x00FFFFFF, // 半透明の白（アルファ値33）
                              ),
                              margin: EdgeInsets.all(0),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          ),

        if (tileDetail)
        GestureDetector(
        onPanUpdate: (details) {
          // タップ位置を取得
          final position = details.localPosition;

          int x = (position.dx / cellSize).floor();
          int y = (position.dy / cellSize).floor();

          // 範囲内なら色を変更
          if (x >= 0 && x < pixelNumber && y >= 0 && y < pixelNumber && drawMode) {
            handleTap(x, y);
          }
        },
      onTapUp: (details) {
        // タップしたときの処理
        final position = details.localPosition;
        int x = (position.dx / cellSize).floor();
        int y = (position.dy / cellSize).floor();
        // 範囲内なら色を変更
        if (x >= 0 && x < pixelNumber && y >= 0 && y < pixelNumber && drawMode) {
          handleTap(x, y);
        }
        if (!drawMode) {
          String tappedColorHex = detailGrid[y][x]; // 保存されている色コード
          Color tappedColor = Color(int.parse('0xFF$tappedColorHex'));

          setState(() {
            selectedColor = tappedColor; // 選択された色を更新
          });
        }
      },
      child: Container(
          width: cellSize * pixelNumber,
          height: cellSize * pixelNumber,
          color: Colors.black12, // 全体の背景色

          child: Column(
            children: List.generate(pixelNumber, (y) {
              return Row(
                children: List.generate(pixelNumber, (x) {
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    color: Color(int.parse('0xFF' + detailGrid[y][x])),
                    margin: EdgeInsets.all(0), // セル間の余白
                  );
                }),
              );
            }),
          ),
        ),
      ),
          Expanded(child:
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                //全体を見るモード
                if (!tileDetail)
                Column(
                  children: [
                    if (selectedTile != -1)
                    CustomImageButton(
                    screenWidth: screenWidth,
                      buttonText: '選択取消',
                      onPressed: (){setState(() {
                      selectedTile = -1;
                    });}),
                    SizedBox(height:  20,),
                    if (selectedTile != -1)
                    CustomImageButton(
                    screenWidth: screenWidth,
                      buttonText: '編集する',
                      onPressed: (){setState(() {
                      _loadDeitalGrid();
                    });}),
                    SizedBox(height: 20,),
                    Text('↓から他の掲示板も見れるよ'),
                    DropdownButton<String>(
                      value: docIdHead,
                      items: docIdHeadMap.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key, // 実際の値
                          child: Text(entry.value, style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline),), // 表示名
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null && loadingState == 'finish') {
                          setState(() {
                            docIdHead = newValue;
                          });
                          // createGridFields();
                          _loadGrid();
                        }
                      },
                    ),
                  ],
                ),



                //描画モード
                if (tileDetail)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomImageButton(
                        screenWidth: screenWidth,
                          buttonText: '変更適用',
                          onPressed: (){setState(() {
                          saveChanges();
                        });}),
                        Text('${pendingChanges.length} / 500'),
                      ],
                    ),
                    if (pendingChanges.length > 500)
                    Text('リセットするか変更を適用しないと次の変更はできません。'),

                    Text('変更は5分以内に適用してください。'),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                        width: screenWidth * 0.07,
                        height: screenWidth * 0.07,
                        color: selectedColor,
                      ),
                      CustomImageButton(
                    screenWidth: screenWidth,
                      buttonText: '色を変更',
                      onPressed: (){setState(() {
                      openColorPicker();
                    });}),
                      ],
                    ),


                    ElevatedButton(
                      onPressed: () {setState(() {
                        drawMode = !drawMode;
                      });},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy_outlined),
                          if (!drawMode)
                          Text('色コピー中', style: TextStyle(fontSize: 20),),
                          if (drawMode)
                          Text('色コピーモードOFF(描画中)', style: TextStyle(fontSize: 20),)
                        ],
                      )
                    ),
                    GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // 1行に6個のボックス
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: colors.length,
                        shrinkWrap: true, // GridViewが親のサイズに合わせてスクロールしないようにする
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = colors[index]; // 色を変更
                              });
                            },
                            child: Container(
                              color: colors[index], // 色のボックス
                              margin: EdgeInsets.all(5),
                              width: screenWidth * 0.07, // 横のサイズ（小さめに設定）
                              height: screenWidth * 0.07, // 縦のサイズ（小さめに設定）
                            ),
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomImageButton(
                          screenWidth: screenWidth,
                            buttonText: 'リセット',
                            onPressed: (){setState(() {
                            _loadDeitalGrid();
                          });}),
                          CustomImageButton(
                          screenWidth: screenWidth,
                            buttonText: '全体図',
                            onPressed: (){setState(() {
                            _loadSpecificGrid(selectedTile);
                          });}),
                        ],
                      )


                  ],
                ),


              ],
            )
          )
          )
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




