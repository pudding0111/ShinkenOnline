import 'package:flutter/material.dart';
import '../main.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart'; // これが必要です
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'TutorialBattleScreen.dart';

class IconWithLikes {
  final String id;
  final String userId;
  final String userName;
  final String originId;
  final String originName;
  final String originPostId;
  final String originPostTitle;
  final List<String> flatGrid;
  final String iconTitle;
  final String iconDetail;
  final DateTime timestamp;
  final int likeCount;
  final int installCount;
  final int badCount;
  final int price;
  final List<String> usersWhoLiked;
  final List<String> usersWhoInstalled;
  final bool sensitivity;

  IconWithLikes({
    required this.id,
    required this.userId,
    required this.userName,
    required this.originId,
    required this.originName,
    required this.originPostId,
    required this.originPostTitle,
    required this.flatGrid,
    required this.iconTitle,
    required this.iconDetail,
    required this.timestamp,
    required this.likeCount,
    required this.installCount,
    required this.badCount,
    required this.price,
    required this.usersWhoLiked,
    required this.usersWhoInstalled,
    required this.sensitivity,
  });

  // ハッシュコードと等価性をサポート
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconWithLikes &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class IconBoardScreen extends StatefulWidget {
  @override
  _IconBoardScreenState createState() => _IconBoardScreenState();
}

class _IconBoardScreenState extends State<IconBoardScreen>  with TickerProviderStateMixin{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // late ScrollController _scrollController;
  TextEditingController? _titleController;
  TextEditingController? _detailController;
  TextEditingController? _priceController;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  late AnimationController _downloadController;
  late Animation<Offset> _downloadAnimation;

  DocumentSnapshot? lastDocument;
  List<List<String>> grid = [];
  Color selectedColor = Colors.blue; // 初期色
  bool drawMode = true; //falseは色をコピーするモード
  bool isZoomMode = false;
  TransformationController _transformationController = TransformationController();
  Matrix4? _cachedMatrix; // 拡大モードを切った後も状態を保持
  String loadingState = 'load'; //load setting finish
  bool developerMode = false;
  bool postCheck = false;
  IconWithLikes selectedIconPost = IconWithLikes(
    id: 'icon123',
    userId: 'user456',
    originId: '',
    originName: '',
    originPostId: '',
    originPostTitle: '',
    userName: 'SampleUser',
    flatGrid: [], // 適当なデータ
    iconTitle: 'サンプルアイコン',
    iconDetail: 'このアイコンはサンプルとして使用されています。',
    timestamp: DateTime.now(),
    likeCount: 10,
    installCount: 5,
    badCount: 0,
    price: 100,
    usersWhoLiked: ['user123', 'user789'], // 適当なユーザーIDリスト
    usersWhoInstalled: ['user456', 'user321'], // 適当なユーザーIDリスト
    sensitivity: false, // デフォルトで不適切でない設定
  );


  int drawBold = 1;
  String myName = '';

  //templateを見る
  String templateName = '';
  List<String> templateList = [];
  bool templateMode = false;
  List<List<String>> templateGrid = [];

  //投稿用
  List<IconWithLikes> timeLineIcons = [];
  List<IconWithLikes> likeIcons = [];
  List<IconWithLikes> installIcons = [];
  List<IconWithLikes> postsByUser = [];
  List<IconWithLikes> popularWeekIcons = [];
  List<IconWithLikes> popularMonthIcons = [];
  List<IconWithLikes> popularAllIcons = [];
  String nowPost = 'timeLine'; //timeLine, makeIcon, likeIcon, installIcon, myIcon
  bool postMoral = false;
  int iconPrice = 0;
  List<String> myBlockList = [];
  bool isLoading = false;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0; // 現在のページインデックス
  bool olderFetching = false;
  bool postDetail = false; // 投稿の詳細を見るためのbool
  int myGachaPoint = 0;
  int iconInfoCount = 0;
  int iconAllLike = 0;
  int iconAllInstall = 0;
  int displayIconInfoCount = 0;
  int startIconMoney = 0;
  int endIconMoney = 0;
  int displayedGachaPoint = 0;
  bool getMoneyView = false;
  bool getMoneyClose = false;


  //投稿著作権用
  String originId = '';
  String originName = '';
  String originPostId = '';
  String originPostTitle = '';

  final int gridNumber = 32;
  int pixelNumber = 16;
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

  Future<dynamic> getFieldFromFirebase({
    required String collection,
    required String document,
    required String field, // 読み取るフィールド名
  }) async {
    try {
      // Firebaseのドキュメント参照
      DocumentReference docRef =
          FirebaseFirestore.instance.collection(collection).doc(document);

      // ドキュメントを取得
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // データを取得
        Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

        // フィールドが存在すればその値を返す
        if (data != null && data.containsKey(field)) {
          return data[field];
        } else {
          print("Field '$field' does not exist.");
          return null;
        }
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
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // 繰り返し設定（前後リバース）

    _heartAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_heartController);
    _downloadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // 繰り返し設定

    _downloadAnimation = Tween<Offset>(
      begin: Offset(0, -0.1), // 初期位置（少し上）
      end: Offset(0, 0.1),   // 終了位置（少し下）
    ).animate(
      CurvedAnimation(
        parent: _downloadController,
        curve: Curves.easeInOut, // 滑らかな動き
      ),
    );
    _loadPreferences();
    _loadTemplateList();
    fetchLatestIconsWithLikes();
    loadIconPostStateFromFirebase();
    _initializeControllers();


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
      grid = List.generate(gridNumber, (_) => List.filled(gridNumber, '0'));
      _priceController?.text = '0';
    });
    _loadGrid();
  }

  @override
  void dispose() {
    // メモリリークを防ぐためにコントローラーを破棄
    _titleController?.dispose();
    _detailController?.dispose();
    _priceController?.dispose();
    _heartController.dispose();
    _downloadController.dispose();
    // _scrollController.dispose();
    super.dispose();
  }

  loadIconPostStateFromFirebase() async {
    int? iconLikeCount = (await getFieldFromFirebase(
          collection: 'newUserData',
          document: uid,
          field: 'iconLikeCount',
        )) as int? ?? 0;
    int iconInstallCount = (await getFieldFromFirebase(
          collection: 'newUserData',
          document: uid,
          field: 'iconInstallCount',
        )) as int? ?? 0;
    int? iconDoneCount = (await getFieldFromFirebase(
          collection: 'newUserData',
          document: uid,
          field: 'iconDoneCount',
        )) as int? ?? 0;
    setState(() {
      iconAllLike = iconLikeCount;
      iconAllInstall = iconInstallCount;
      iconInfoCount = iconLikeCount + iconInstallCount - iconDoneCount;
      displayIconInfoCount = iconInfoCount;
      print(iconInfoCount);
    });
  }

  Future<void> getIconMoney() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Firebase からデータを取得
      int iconAllMoney = (await getFieldFromFirebase(
            collection: 'newUserData',
            document: uid,
            field: 'iconAllMoney',
          ) as int?) ??
          0;

      int iconDoneMoney = (await getFieldFromFirebase(
            collection: 'newUserData',
            document: uid,
            field: 'iconDoneMoney',
          ) as int?) ??
          0;

      int difference = iconAllMoney - iconDoneMoney;

      if (difference > 0) {
        startIconMoney = myGachaPoint;
        endIconMoney = myGachaPoint + difference;

        setState(() {
          myGachaPoint = endIconMoney;
        });
      }
      await prefs.setInt('myGachaPoint', myGachaPoint);

      // Firebase のデータを更新
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postUsersRef = FirebaseFirestore.instance.collection('newUserData').doc(uid);
        transaction.update(postUsersRef, {
          'iconDoneMoney': FieldValue.increment(difference),
          'iconDoneCount': FieldValue.increment(iconInfoCount),
        });
      });
      iconInfoCount = 0;

      // UI 更新
      setState(() {});
    } catch (e) {
      print('Error in getIconMoney: $e');
    }
  }

  void animateGachaPoint(int start, int end) {
    // アニメーションコントローラー
    final duration = Duration(seconds: 2); // 2秒間アニメーション
    final stepDuration = ((end - start) != 0) ?duration.inMilliseconds ~/ (end - start) : 0;

    Future.forEach<int>(List.generate(end - start, (i) => i + 1), (increment) async {
      await Future.delayed(Duration(milliseconds: stepDuration));
      setState(() {
        displayedGachaPoint = start + increment;
      });
    });
  }

  void saveChanges() async {
    print(uid);
    List<String> flatGrid = grid.expand((row) => row).toList();
    await _firestore.collection('newUserData').doc(uid).update({
      'icon': flatGrid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('myIcon', flatGrid);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('変更を保存しました。'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void saveTemplates() async {
    List<String> flatGrid = grid.expand((row) => row).toList();
    final firestore = FirebaseFirestore.instance;
    final templateCollection = firestore.collection('iconTemplate');

    try {
      print('template saving now..');
      await templateCollection.doc('initial').set({
        templateName: flatGrid,
      }, SetOptions(merge: true));

      print('Template updated successfully!');
    } catch (e) {
      // エラー時の処理
      print('Failed to update template: $e');

      // エラー通知をユーザーに表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('テンプレートの保存に失敗しました。もう一度お試しください。'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('変更を保存しました。'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  _loadPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      myName = prefs.getString('myName') ?? '名無し';
      myBlockList = prefs.getStringList('myBlockList') ?? [];
      myGachaPoint = prefs.getInt('myGachaPoint') ?? 0;
      displayedGachaPoint = myGachaPoint;
      originId = prefs.getString('iconOriginId') ?? uid;
      originName = prefs.getString('iconOriginName') ?? myName;
      originPostId = prefs.getString('iconOriginPostId') ?? 'null';
      originPostTitle = prefs.getString('iconOriginPostTitle') ?? 'null';
    });
  }

  void purchaseIcon(int price) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      myGachaPoint -= price;
      prefs.setInt('myGachaPoint', myGachaPoint);
    });
  }

  void setIconOrigin(IconWithLikes iconPost) async{ //install（使用する）を押下した後の関数
    setState(() {
      if (uid != iconPost.originId) {
        if (iconPost.originPostId == 'null') { //nullだったら最初の投稿
          originId = iconPost.userId;
          originName = iconPost.userName;
          originPostId = iconPost.id;
          originPostTitle = iconPost.iconTitle;
        } else { //nullじゃなかったら二次創作
          originId = iconPost.originId;
          originName = iconPost.originName;
          originPostId = iconPost.originPostId;
          originPostTitle = iconPost.originPostTitle;
        }
      } else {
        originId = uid;
        originName = myName;
        originPostId = 'null';
        originPostTitle = 'null';
      }
    });
  }

  void resetIconOrigin() async{ //resetしてまっさらにする関数
    setState(() {
      List<String> resetGridField = List<String>.generate(gridNumber * gridNumber, (index) => 0.toString());
      grid = List.generate(gridNumber, (y) {
        return List.generate(gridNumber, (x) {
          int index = y * gridNumber + x;

          // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
          if (index >= 0 && index < resetGridField.length) {
            return resetGridField[index]; // String を返す
          } else {
            return ''; // デフォルト値
          }
        });
      });
      originId = uid;
      originName = myName;
      originPostId = 'null';
      originPostTitle = 'null';
    });
  }

  setIconOriginToPref() async{ //コピーしたイラストを編集した変更適用したときに保存する関数
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myGachaPoint', myGachaPoint);
      prefs.setString('iconOriginId', originId);
      prefs.setString('iconOriginName', originName);
      prefs.setString('iconOriginPostId', originPostId);
      prefs.setString('iconOriginPostTitle', originPostTitle);
    });
  }

  Future<void> createGridFields() async { //フィールドの初期化
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;
    setState(() {
      loadingState = 'load';
    });

    // `masFill`コレクションを取得
    final masFillCollection = firestore.collection('newUserData');

    // ランダムな色を生成する関数
    String getRandomColor(int i) {
      return '';
    }

    // gridフィールドに設定するデータ
    List<String> gridField = List<String>.generate(gridNumber * gridNumber, (index) => getRandomColor(0));
    String docId = uid; // ドキュメントIDを指定
    gridField = prefs.getStringList('myIcon') ?? gridField;

    print(uid);
    try {
      await masFillCollection.doc(docId).set({
        'icon': gridField,
      }, SetOptions(merge: true));
      print('success for setting icon data! to uid:$uid');
    } catch (e) {
      print('Error creating grid field for document $docId: $e');
    }
    setState(() {
      loadingState = 'finish';
    });
  }

  Future<void> _loadGrid() async { //画面全体をロード
    final firestore = FirebaseFirestore.instance;
    setState(() {
      loadingState = 'load';
    });

    // `masFill`コレクションの中から`fun1`から`fun64`までのドキュメントを取得
    List<String> allGrids = [];
    String docId = uid; // ドキュメントID
    try {
      // ドキュメントを取得
      DocumentSnapshot doc = await firestore.collection('newUserData').doc(docId).get();
      if (doc.exists) {
        // `grid`フィールドを取得してリストに格納
        allGrids = List<String>.from((doc['icon'] as List).map((e) => e.toString()));
        print(allGrids);
      } else {
        print('Document $docId not found');
      }
    } catch (e) {
      print('Error loading grid for $docId: $e');
      createGridFields();
    }

    setState(() {
      loadingState = 'setting';
    });

    // すべてのグリッドがロードされたら、状態を更新
    setState(() {
      grid = List.generate(gridNumber, (y) {
        return List.generate(gridNumber, (x) {
          int index = y * gridNumber + x;

          // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
          if (index >= 0 && index < allGrids.length) {
            return allGrids[index]; // String を返す
          } else {
            return ''; // デフォルト値
          }
        });
      });
    });
  }

  Future<void> _loadTemplateList() async { //画面全体をロード
    final firestore = FirebaseFirestore.instance;
    try {
      // ドキュメントを取得
      DocumentSnapshot doc = await firestore.collection('iconTemplate').doc('initial').get();
      if (doc.exists) {
        // `grid`フィールドを取得してリストに格納
        templateList = List<String>.from((doc['nameList'] as List).map((e) => e.toString()));
        print(templateList);
      } else {
        print('Document "initial" not found');
      }
    } catch (e) {
      print('Error loading grid for "inital": $e');
    }
  }

  Future<void> _loadTemplateGrid(String templateField, bool booling) async { //画面全体をロード
    final firestore = FirebaseFirestore.instance;
    setState(() {
      loadingState = 'load';
    });

    // `masFill`コレクションの中から`fun1`から`fun64`までのドキュメントを取得
    List<String> allGrids = [];
    try {
      // ドキュメントを取得
      DocumentSnapshot doc = await firestore.collection('iconTemplate').doc('initial').get();
      if (doc.exists) {
        // `grid`フィールドを取得してリストに格納
        allGrids = List<String>.from((doc[templateField] as List).map((e) => e.toString()));
        print(allGrids);
      } else {
        print('Document $templateField not found');
      }
    } catch (e) {
      print('Error loading grid for $templateField: $e');
    }

    setState(() {
      loadingState = 'setting';
    });

    // すべてのグリッドがロードされたら、状態を更新
    setState(() {
      templateGrid = List.generate(gridNumber, (y) {
        return List.generate(gridNumber, (x) {
          int index = y * gridNumber + x;

          // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
          if (index >= 0 && index < allGrids.length) {
            return allGrids[index]; // String を返す
          } else {
            return ''; // デフォルト値
          }
        });
      });

    });
    if (booling){
      templateMode = true;
    } else {
      templateMode = false;
    }
  }

  void openColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('色を選択'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              setState(() {
                selectedColor = color;
              });
            },
            showLabel: false,
            pickerAreaHeightPercent: 1.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void openMaterialPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('色を選択'),
        content: SingleChildScrollView(
          child: MaterialPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              setState(() {
                selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void handleTap(int row, int col) {
    if (drawMode && !isZoomMode) {
      setState(() {
        grid[col][row] = selectedColor.value.toRadixString(16); // カラーコードを保存
        print(selectedColor.value.toRadixString(16));
      });
    }
  }

  void _showPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    const correctPassword = 'kassey030111'; // 正しいパスワード

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true, // パスワードを隠す
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // パスワードの確認
                if (passwordController.text == correctPassword) {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  setState(() {
                    developerMode = true;
                  });
                } else {
                  // パスワードが間違っている場合の処理
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Password!')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void updateNowPost(String option) {
      switch (option) {
        case 'timeLine':
        fetchLatestIconsWithLikes();
          break;
        case 'weekRanking':
        setState(() {
          isLoading = true;
        });
        fetchWeekPopularPosts((posts) {
          if (posts.isNotEmpty) {
            print("Fetched ${posts.length} popular posts for the week:");
            for (var post in posts) {
            }
            setState(() {
              popularWeekIcons = [];
              popularWeekIcons = posts;
            });
          } else {
            print("No popular posts found for the week.");
          }
          setState(() {
            isLoading = false;
          });
        });

        break;
        case 'monthRanking':
        setState(() {
          isLoading = true;
        });
        fetchMonthPopularPosts((posts) {
          if (posts.isNotEmpty) {
            print("Fetched ${posts.length} popular posts for the month:");
            for (var post in posts) {
            }
            setState(() {
              popularMonthIcons = [];
              popularMonthIcons = posts;
            });
          } else {
            print("No popular posts found for the month.");
          }
          setState(() {
            isLoading = false;
          });
        });
        break;
        case 'allRanking':
        setState(() {
          isLoading = true;
        });
        fetchTopPopularPosts((posts) {
          if (posts.isNotEmpty) {
            print("Fetched ${posts.length} popular posts for the month:");
            for (var post in posts) {
            }
            setState(() {
              popularAllIcons = [];
              popularAllIcons = posts;
            });
          } else {
            print("No popular posts found for the month.");
          }
          setState(() {
            isLoading = false;
          });
        });
        break;
        case 'likeIcon':
        setState(() {
          isLoading = true;
        });
        fetchPostsLikedByUser(uid, (posts) {
          if (posts != null) {
            print("Fetched ${posts.length} liked posts:");
            posts.forEach((post) {
            });
            setState(() {
              likeIcons = [];
              likeIcons = posts;
            });
          } else {
            print("No posts found or an error occurred.");
          }
          setState(() {
            isLoading = false;
          });
        });
        break;
        case 'installIcon':
        setState(() {
          isLoading = true;
        });
        fetchPostsInstalledByUser(uid, (posts) {
          if (posts != null) {
            print('Fetched ${posts.length} liked posts:');
            posts.forEach((post) {
              print('Post ID: ${post.id}, Skill Name: ${post.iconTitle}');
            });
            setState(() {
              installIcons = posts;
            });
          } else {
            print('No posts found or an error occurred.');
          }
          setState(() {
            isLoading = false;
          });
        });
        break;
        case 'myTweet':
        setState(() {
          isLoading = true;
        });
        fetchPostsByUser(uid, (posts) {
          if (posts != null) {
            print("Fetched ${posts.length} posts by user:");
            for (var post in posts) {
            }
            setState(() {
              postsByUser = [];
              postsByUser = posts;
            });
          } else {
            print("No posts found or an error occurred.");
          }
          setState(() {
            isLoading = false;
          });
        });
        break;
        default:
      }
    }

    void _initializeControllers() {
      _titleController = TextEditingController();
      _detailController = TextEditingController();
      _priceController = TextEditingController();
    }

    void _disposeControllers() {
      _titleController?.dispose();
      _detailController?.dispose();
      _priceController?.dispose();
      _titleController = null;
      _detailController = null;
      _priceController = null;
    }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController(); // 入力コントローラ
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final cellSize = (min(screenWidth * 0.9, screenHeight * 0.45) / gridNumber).floorToDouble();
    final containerSize = cellSize * gridNumber;
    //投稿用関数
    const itemsPerPage = 4;
    return Scaffold(
      body:
      Stack(
        children: [
          Column(
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
                        if (!postCheck)
                        MovingLeftImage(
                          onTap: (){
                            context.go('/miniGame');
                          },
                          screenHeight: screenHeight,
                          screenWidth: screenWidth,
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onLongPress: () {
                      _showPasswordDialog(context);
                    },
                    child: Text(
                      'アイコンメーカー',
                      style: TextStyle(
                        fontFamily: 'makinas4',
                        fontSize: screenWidth * 0.05,
                      ),
                    ),
                  ),
                  Spacer(),

                  if(nowPost != 'makeIcon')
                  DropdownButton<String>(
                  value: nowPost,
                  items: [
                    DropdownMenuItem(value: 'timeLine', child: Text('タイムライン', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'weekRanking', child: Text('週間人気', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'monthRanking', child: Text('月間人気', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'allRanking', child: Text('全期間人気', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'likeIcon', child: Text('いいねした投稿', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'installIcon', child: Text('購入した投稿', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'myIcon', child: Text('自分の投稿', style: TextStyle(fontFamily: 'makinas4', ))),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        nowPost = newValue;
                        updateNowPost(newValue); // nowPostを更新
                      });
                    }
                  },
                ),

                if(loadingState != 'finish' && nowPost == 'makeIcon' && !postCheck)
                CustomImageButton(screenWidth: screenWidth, buttonText: templateMode ? '描画' : 'テンプレ', onPressed: (){
                  setState((){
                    _loadTemplateGrid('initial', !templateMode);
                  });
                }),
                ],
              ),

              if (nowPost == 'timeLine' && !isLoading)
              SizedBox(
                height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 100,
                child: // タイムライン
                Stack (
                  children: [


                NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is OverscrollNotification &&
              notification.overscroll > 0 &&
              !isLoading &&
              _currentPageIndex == (timeLineIcons.length / itemsPerPage).ceil() - 1) {
            // 最後のページでフェッチをトリガー
            setState(() {
              olderFetching = true;
            });
            fetchOlderIconsWithLikes().then((_) {
              // データフェッチ後、現在のページに戻る
              WidgetsBinding.instance.addPostFrameCallback((_) {
                print('jump前pageIndex$_currentPageIndex');
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(_currentPageIndex + 1);
                }
                setState(() {
                 olderFetching = false;
                });
              });
            });
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
  scrollDirection: Axis.vertical, // 上下にスクロール
  onPageChanged: (pageIndex) async {
          setState(() {
            _currentPageIndex = pageIndex; // 現在のページを記録
            print('今のペーず　$_currentPageIndex');
          });
        },
  itemCount: (timeLineIcons.length / 4).ceil(), // 各ページ4つのアイテムを表示
  itemBuilder: (context, pageIndex) {
    // ページごとのアイテムを取得
    final pageItems = timeLineIcons
        .where((post) => !myBlockList.contains(post.userId))
        .skip(pageIndex * 4)
        .take(4)
        .toList();

    double postHeight = (screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 106) / 4;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: pageItems.map((post) {
          return SizedBox(
            height: postHeight, // 1つの投稿の高さを固定（例: 150ピクセル）
            child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                selectedIconPost = post;
                postDetail = true;
              });
            },
            child:
            PostCard(
              post: post,
              postHeight: postHeight,
              likePost: likePost,
              showReportAlert: showReportAlert,
              showBlockAlert: showBlockAlert,
              showDeleteAlert: showDeleteAlert,
              onInstallPressed: () {
                setState(() {
                  selectedIconPost = post;
                  postDetail = true;
                });
              },
              postDetailCheck: () {
                setState(() {
                  selectedIconPost = post;
                  postDetail = true;
                });
              },
              currentUserId: uid,
            ),
            ),
          );
        }).toList(),
      ),
    );
  },
),


      ),
      if (olderFetching)
      Container(
        color: Colors.white,
      ),
      if (olderFetching)
      CircularProgressIndicator(),
                  ]
                ),
            ),
            if (nowPost == 'timeLine' && isLoading)
            CircularProgressIndicator(),



            if (nowPost == 'myIcon' && !isLoading)
              SizedBox(
                height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 100,
                child: // 自分の投稿
                PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // 上下にスクロール
                onPageChanged: (pageIndex) async {
                  setState(() {
                    _currentPageIndex = pageIndex; // 現在のページを記録
                    print('今のペーず　$_currentPageIndex');
                  });
                },
                itemCount: (postsByUser.length / 4).ceil(), // 各ページ4つのアイテムを表示
                itemBuilder: (context, pageIndex) {
                  // ページごとのアイテムを取得
                  final pageItems = postsByUser
                      .where((post) => !myBlockList.contains(post.userId))
                      .skip(pageIndex * 4)
                      .take(4)
                      .toList();

                  double postHeight = (screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 106) / 4;

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: pageItems.map((post) {
                        return SizedBox(
                          height: postHeight, // 1つの投稿の高さを固定（例: 150ピクセル）
                          child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      selectedIconPost = post;
                      postDetail = true;
                    });
                  },
                  child:
                  PostCard(
                    post: post,
                    postHeight: postHeight,
                    likePost: likePost,
                    showReportAlert: showReportAlert,
                    showBlockAlert: showBlockAlert,
                    showDeleteAlert: showDeleteAlert,
                    onInstallPressed: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    postDetailCheck: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    currentUserId: uid,
                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            if (nowPost == 'myIcon' && isLoading)
            CircularProgressIndicator(),

            if (nowPost == 'likeIcon' && !isLoading)
              SizedBox(
                height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 100,
                child: // 自分の投稿
                PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // 上下にスクロール
                onPageChanged: (pageIndex) async {
                  setState(() {
                    _currentPageIndex = pageIndex; // 現在のページを記録
                    print('今のペーず　$_currentPageIndex');
                  });
                },
                itemCount: (likeIcons.length / 4).ceil(), // 各ページ4つのアイテムを表示
                itemBuilder: (context, pageIndex) {
                  // ページごとのアイテムを取得
                  final pageItems = likeIcons
                      .where((post) => !myBlockList.contains(post.userId))
                      .skip(pageIndex * 4)
                      .take(4)
                      .toList();

                  double postHeight = (screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 106) / 4;

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: pageItems.map((post) {
                        return SizedBox(
                          height: postHeight, // 1つの投稿の高さを固定（例: 150ピクセル）
                          child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      selectedIconPost = post;
                      postDetail = true;
                    });
                  },
                  child:
                  PostCard(
                    post: post,
                    postHeight: postHeight,
                    likePost: likePost,
                    showReportAlert: showReportAlert,
                    showBlockAlert: showBlockAlert,
                    showDeleteAlert: showDeleteAlert,
                    onInstallPressed: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    postDetailCheck: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    currentUserId: uid,
                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            if (nowPost == 'likeIcon' && isLoading)
            CircularProgressIndicator(),

            if (nowPost == 'installIcon' && !isLoading)
              SizedBox(
                height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 100,
                child: // 自分の投稿
                PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // 上下にスクロール
                onPageChanged: (pageIndex) async {
                  setState(() {
                    _currentPageIndex = pageIndex; // 現在のページを記録
                    print('今のペーず　$_currentPageIndex');
                  });
                },
                itemCount: (installIcons.length / 4).ceil(), // 各ページ4つのアイテムを表示
                itemBuilder: (context, pageIndex) {
                  // ページごとのアイテムを取得
                  final pageItems = installIcons
                      .where((post) => !myBlockList.contains(post.userId))
                      .skip(pageIndex * 4)
                      .take(4)
                      .toList();

                  double postHeight = (screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 106) / 4;

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: pageItems.map((post) {
                        return SizedBox(
                          height: postHeight, // 1つの投稿の高さを固定（例: 150ピクセル）
                          child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      selectedIconPost = post;
                      postDetail = true;
                    });
                  },
                  child:
                  PostCard(
                    post: post,
                    postHeight: postHeight,
                    likePost: likePost,
                    showReportAlert: showReportAlert,
                    showBlockAlert: showBlockAlert,
                    showDeleteAlert: showDeleteAlert,
                    onInstallPressed: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    postDetailCheck: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    currentUserId: uid,
                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            if (nowPost == 'installIcon' && isLoading)
            CircularProgressIndicator(),

            if (nowPost == 'weekRanking' && !isLoading)
              SizedBox(
                height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 100,
                child: // 自分の投稿
                PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // 上下にスクロール
                onPageChanged: (pageIndex) async {
                  setState(() {
                    _currentPageIndex = pageIndex; // 現在のページを記録
                    print('今のペーず　$_currentPageIndex');
                  });
                },
                itemCount: (popularWeekIcons.length / 4).ceil(), // 各ページ4つのアイテムを表示
                itemBuilder: (context, pageIndex) {
                  // ページごとのアイテムを取得
                  final pageItems = popularWeekIcons
                      .where((post) => !myBlockList.contains(post.userId))
                      .skip(pageIndex * 4)
                      .take(4)
                      .toList();

                  double postHeight = (screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 106) / 4;

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: pageItems.map((post) {
                        return SizedBox(
                          height: postHeight, // 1つの投稿の高さを固定（例: 150ピクセル）
                          child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      selectedIconPost = post;
                      postDetail = true;
                    });
                  },
                  child:
                  PostCard(
                    post: post,
                    postHeight: postHeight,
                    likePost: likePost,
                    showReportAlert: showReportAlert,
                    showBlockAlert: showBlockAlert,
                    showDeleteAlert: showDeleteAlert,
                    onInstallPressed: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    postDetailCheck: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    currentUserId: uid,
                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            if (nowPost == 'weekRanking' && isLoading)
            CircularProgressIndicator(),

            if (nowPost == 'monthRanking' && !isLoading)
              SizedBox(
                height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 100,
                child: // 自分の投稿
                PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // 上下にスクロール
                onPageChanged: (pageIndex) async {
                  setState(() {
                    _currentPageIndex = pageIndex; // 現在のページを記録
                    print('今のペーず　$_currentPageIndex');
                  });
                },
                itemCount: (popularMonthIcons.length / 4).ceil(), // 各ページ4つのアイテムを表示
                itemBuilder: (context, pageIndex) {
                  // ページごとのアイテムを取得
                  final pageItems = popularMonthIcons
                      .where((post) => !myBlockList.contains(post.userId))
                      .skip(pageIndex * 4)
                      .take(4)
                      .toList();

                  double postHeight = (screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 106) / 4;

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: pageItems.map((post) {
                        return SizedBox(
                          height: postHeight, // 1つの投稿の高さを固定（例: 150ピクセル）
                          child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      selectedIconPost = post;
                      postDetail = true;
                    });
                  },
                  child:
                  PostCard(
                    post: post,
                    postHeight: postHeight,
                    likePost: likePost,
                    showReportAlert: showReportAlert,
                    showBlockAlert: showBlockAlert,
                    showDeleteAlert: showDeleteAlert,
                    onInstallPressed: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    postDetailCheck: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    currentUserId: uid,
                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            if (nowPost == 'monthRanking' && isLoading)
            CircularProgressIndicator(),

            if (nowPost == 'allRanking' && !isLoading)
              SizedBox(
                height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 100,
                child: // 自分の投稿
                PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // 上下にスクロール
                onPageChanged: (pageIndex) async {
                  setState(() {
                    _currentPageIndex = pageIndex; // 現在のページを記録
                    print('今のペーず　$_currentPageIndex');
                  });
                },
                itemCount: (popularAllIcons.length / 4).ceil(), // 各ページ4つのアイテムを表示
                itemBuilder: (context, pageIndex) {
                  // ページごとのアイテムを取得
                  final pageItems = popularAllIcons
                      .where((post) => !myBlockList.contains(post.userId))
                      .skip(pageIndex * 4)
                      .take(4)
                      .toList();

                  double postHeight = (screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - screenWidth * 0.1 - 106) / 4;

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: pageItems.map((post) {
                        return SizedBox(
                          height: postHeight, // 1つの投稿の高さを固定（例: 150ピクセル）
                          child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      selectedIconPost = post;
                      postDetail = true;
                    });
                  },
                  child:
                  PostCard(
                    post: post,
                    postHeight: postHeight,
                    likePost: likePost,
                    showReportAlert: showReportAlert,
                    showBlockAlert: showBlockAlert,
                    showDeleteAlert: showDeleteAlert,
                    onInstallPressed: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    postDetailCheck: () {
                      setState(() {
                        selectedIconPost = post;
                        postDetail = true;
                      });
                    },
                    currentUserId: uid,
                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            if (nowPost == 'allRanking' && isLoading)
            CircularProgressIndicator(),








            //ここからアイコン作り用

              SizedBox(height: 10,),

              if (nowPost == 'makeIcon' && templateMode && loadingState == 'load')
              CircularProgressIndicator(),

              if (!templateMode && nowPost == 'makeIcon' && !postCheck)
              Column(
                children: [
                  SizedBox(
                    height: containerSize,
                    width: containerSize,
                    child:
                    Stack(
                      children: [
                        Container(
                          width: containerSize,
                          height: containerSize,
                          child: isZoomMode
                        ?
                        InteractiveViewer(
                            transformationController: _transformationController,
                            maxScale: 10.0,
                            child: _buildPixelGrid(grid: grid),
                          )
                        : _buildPixelGrid(grid: grid),
                        ),

                        if (!isZoomMode)
                        GestureDetector(
                        onPanUpdate: (details) {
                          // タップ位置を取得
                          final position = details.localPosition;
                          int x = (position.dx / cellSize).floor();
                          int y = (position.dy / cellSize).floor();
                          print('${x},${y}');
                          // 範囲内なら色を変更
                          for (int i = 0; i < drawBold; i++) { //太さを変えるためのループ
                            int num = (i + 1) ~/ 2; // 0 , 1  , 1 ,  2 , 2 ,3 ,3 , 4, 4,
                            bool judge = (i % 2 == 1); // false, true , false
                            int changeX = judge ? x + num : x - num; // - 0, +1 ,-1, +2, -2
                            for (int j = 0; j < drawBold; j++) {
                              int num2 = (j + 1) ~/ 2; // 0 , 1  , 1 ,  2 , 2 ,3 ,3 , 4, 4,
                              bool judge2 = (j % 2 == 1); // false, true , false
                              int changeY = judge2 ? y + num2 : y - num2;
                              if (changeX >= 0 && changeX < gridNumber && changeY >= 0 && changeY < gridNumber) {
                                handleTap(changeX, changeY);
                              }
                            }
                          }
                        },

                        onTapUp: (details) {
                          // タップしたときの処理
                          final position = details.localPosition;
                          int x = (position.dx / cellSize).floor();
                          int y = (position.dy / cellSize).floor();
                          print('${position.dx} ${position.dy}');
                          // 範囲内なら色を変更
                          for (int i = 0; i < drawBold; i++) { //太さを変えるためのループ
                            int num = (i + 1) ~/ 2; // 0 , 1  , 1 ,  2 , 2 ,3 ,3 , 4, 4,
                            bool judge = (i % 2 == 1); // false, true , false
                            int changeX = judge ? x + num : x - num; // - 0, +1 ,-1, +2, -2
                            for (int j = 0; j < drawBold; j++) {
                              int num2 = (j + 1) ~/ 2; // 0 , 1  , 1 ,  2 , 2 ,3 ,3 , 4, 4,
                              bool judge2 = (j % 2 == 1); // false, true , false
                              int changeY = judge2 ? y + num2 : y - num2;
                              if (changeX >= 0 && changeX < gridNumber && changeY >= 0 && changeY < gridNumber) {
                                handleTap(changeX, changeY);
                              }
                            }
                          }
                          if (!drawMode) {
                            String tappedColorHex = grid[y][x]; // 保存されている色コード
                            Color tappedColor = Color(int.parse('0xFF$tappedColorHex'));
                            setState(() {
                              selectedColor = tappedColor; // 選択された色を更新
                            });
                          }
                        },
                        child:
                        Container(
                          width: containerSize,
                          height: containerSize,
                          color: const Color.fromARGB(0, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: screenHeight - (_bannerAd != null ? _bannerAd!.size.height.toDouble() : 50) - containerSize - 76 - screenWidth * 0.1,
                    child:
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child:
                    Column(
                      children: [
                        if (originId != uid)
                        Text('$originNameさんの作品を編集中です。'),
                        if (originId != uid)
                        ElevatedButton(onPressed: (){showResetAlert;}, child: Text('リセットして自分の作品を描く')),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomImageButton(
                              screenWidth: screenWidth,
                                buttonText: '変更適用',
                                onPressed: (){setState(() {
                                  setIconOriginToPref();
                                  saveChanges();
                              });}
                            ),
                            SizedBox(width: 30),
                            CustomImageButton(
                              screenWidth: screenWidth,
                                buttonText: '投稿する',
                                onPressed: (){setState(() {
                                  _initializeControllers();
                                  postCheck = true;
                              });}
                            ),
                          ],
                        ),

                        if (developerMode)
                        Row(
                          children: [
                            ElevatedButton(onPressed: (){setState(() {
                              saveTemplates();
                            });}, child: Text(templateName)),
                            ElevatedButton(onPressed: (){setState(() {
                              templateName = _controller.text;
                            });}, child: Text('決定'))
                          ],
                        ),
                        if (developerMode)
                        TextField(
                          controller: _controller,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Switch(
                              value: isZoomMode,
                              onChanged: (value) {
                                setState(() {
                                  isZoomMode = value;
                                  drawBold = 1;

                                  if (!isZoomMode) {
                                    // 拡大モードをオフにする際に現在のズーム状態を保存
                                    _cachedMatrix = _transformationController.value;
                                  }
                                });
                              },
                            ),
                            Text(isZoomMode ? '拡大中(なぞりではかけません)' : '描画中（なぞりでもかけます）')
                          ],
                        ),
                        Text('↑絵を拡大縮小できるボタンです。'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: cellSize * drawBold, // サイズを drawBold に応じて変更
                              width: cellSize * drawBold,
                              decoration: BoxDecoration(
                                color: selectedColor, // 常に黒の背景
                                border: Border.all(
                                  color: Colors.black, // 外枠の色
                                  width: 1.0,
                                ),
                              ),
                            ),
                            if (!isZoomMode)
                            Slider(
                              value: drawBold.toDouble(), // 現在の値
                              min: 1,
                              max: 4,
                              divisions: 3, // 1 から 8 の整数のみ
                              label: '$drawBold', // 現在の値を表示
                              onChanged: (double newValue) {
                                setState(() {
                                  drawBold = newValue.round(); // 値を整数に変換
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomImageButton(
                            screenWidth: screenWidth,
                              buttonText: '色変更1',
                              onPressed: (){setState(() {
                              openColorPicker();
                            });}),
                            CustomImageButton(
                            screenWidth: screenWidth,
                              buttonText: '色変更2',
                              onPressed: (){setState(() {
                              openMaterialPicker();
                            });}),
                            SizedBox(width: 10,),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedColor = Colors.transparent;
                                });
                              },
                              child: Text('無色透明', style: TextStyle(fontFamily: 'makinas4'),),
                            ),
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
                        Text('↑欲しい色をコピーできるボタンです。'),
                        GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
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
                      ],
                    ),
                    )
                  ),
                ],
              ),

              if (templateMode && nowPost == 'makeIcon' && !postCheck)
              Column(
                children: [
                  SizedBox(
                    height: containerSize,
                    width: containerSize,
                    child:
                    Stack(
                      children: [
                        Container(
                          width: containerSize,
                          height: containerSize,
                          child: _buildPixelGrid(grid: templateGrid),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(onPressed: () {
                    setState(() {
                      grid = templateGrid;
                      originId = uid;
                      originName = myName;
                      originPostId = 'null';
                      originPostTitle = 'null';
                    });
                  }, child: Text('このアイコンを使う!')),
                  SizedBox(height: screenHeight * 0.3,
                  child:
                  Expanded(
                    child: ListView.builder(
                      itemCount: templateList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(templateList[index]),
                          onTap: () {
                            _loadTemplateGrid(templateList[index], true);
                          },
                        );
                      },
                    ),
                  ),
                  )
                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // TimeLine アイコン
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        nowPost = 'timeLine';
                        fetchLatestIconsWithLikes();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: nowPost == 'timeLine' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(Icons.text_snippet, size: screenWidth * 0.1),
                    ),
                  ),
                  //  アイコンメーカー
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        nowPost = 'makeIcon';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: nowPost == 'makeIcon' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(Icons.draw, size: screenWidth * 0.1),
                    ),
                  ),
                  //  購入したアイコン
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        nowPost = 'installIcon';
                        setState(() {
                          isLoading = true;
                        });
                        fetchPostsInstalledByUser(uid, (posts) {
                          if (posts != null) {
                            print('Fetched ${posts.length} liked posts:');
                            posts.forEach((post) {
                              print('Post ID: ${post.id}, Skill Name: ${post.iconTitle}');
                            });
                            setState(() {
                              installIcons = posts;
                            });
                          } else {
                            print('No posts found or an error occurred.');
                          }
                          setState(() {
                            isLoading = false;
                          });
                        });
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: nowPost == 'installIcon' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(Icons.download, size: screenWidth * 0.1),
                    ),
                  ),
                  // My Likes アイコン
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        nowPost = 'likeIcon';
                        setState(() {
                          isLoading = true;
                        });
                        fetchPostsLikedByUser(uid, (posts) {
                          if (posts != null) {
                            print('Fetched ${posts.length} liked posts:');
                            posts.forEach((post) {
                              print('Post ID: ${post.id}, Skill Name: ${post.iconTitle}');
                            });
                            setState(() {
                              likeIcons = posts;
                            });
                          } else {
                            print('No posts found or an error occurred.');
                          }
                          setState(() {
                            isLoading = false;
                          });
                        });
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: nowPost == 'likeIcon' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(Icons.favorite, size: screenWidth * 0.1),
                    ),
                  ),
                  // My Tweets アイコン
                  GestureDetector(
                    onTap: () {
                      print('my icon post fetching');
                      setState(() {
                        nowPost = 'myIcon';
                        if (iconInfoCount > 0) {
                          getIconMoney();
                          getMoneyView = true;
                        }
                        setState(() {
                          isLoading = true;
                        });
                        fetchPostsByUser(uid, (posts) {

                          if (posts != null) {
                            print('Fetched ${posts.length} posts by user:');
                            for (var post in posts) {
                              print('Post ID: ${post.id}, Skill Name: ${post.iconTitle}');
                            }
                            setState(() {
                              postsByUser = [];
                              postsByUser = posts;
                            });
                          } else {
                            print('No posts found or an error occurred.uid = $uid');
                          }
                          setState(() {
                            isLoading = false;
                          });
                        });
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: nowPost == 'myIcon' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child:
                      Stack(
                        children: [
                          Icon(Icons.person, size: screenWidth * 0.1,),
                          // 通知数バッジ
                          if (iconInfoCount > 0)
                          Positioned(
                            right: 0, // 右上に配置
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.red, // バッジの背景色
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  iconInfoCount < 100 ? iconInfoCount.toString() : 99.toString(), // 通知数（動的に変更可能）
                                  style: TextStyle(
                                    color: Colors.white, // テキストの色
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (nowPost == 'makeIcon' && postCheck)
          Container(
            height: screenHeight * 0.5, // 高さをscreenHeightの0.5倍に設定
            margin: const EdgeInsets.all(20), // 外側の余白
            padding: const EdgeInsets.all(10), // 内側の余白
            decoration: BoxDecoration(
              color: Colors.white, // 背景色
              border: Border.all(color: Colors.black, width: 2), // 外枠
              borderRadius: BorderRadius.circular(10), // 角丸
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '投稿内容',
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenHeight * 0.027,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pixel Grid
                      PixelGrid(
                        screenWidth: screenWidth * 0.7, // グリッドの幅を調整
                        screenHeight: screenHeight * 0.7,
                        grid: grid,
                        gridNumber: gridNumber,
                      ),
                      const SizedBox(width: 10), // グリッドとテキストフィールド間のスペース
                      // タイトルフィールド
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'タイトル(20字以下)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // 下部要素とのスペース
                  TextField(
                    controller: _detailController,
                    maxLines: 3, // 3行分の高さ
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '作品の説明',
                      alignLabelWithHint: true, // ラベルの位置を調整
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), // 内側の余白
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('売値',style: TextStyle(fontFamily: 'makinas4', fontSize: 20, fontWeight: FontWeight.bold),),
                      SizedBox(width: 10,),
                      Icon(Icons.military_tech, size: 40,),
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (iconPrice > 0) {
                              iconPrice = int.tryParse(_priceController!.text) ?? 0;
                              iconPrice = iconPrice - 1000;
                              _priceController!.text = iconPrice.toString();
                            }
                          });
                        },
                      ),
                      IntrinsicWidth(child:
                        TextField(
                          keyboardType: TextInputType.number, // 数字入力用キーボードを表示
                          controller: _priceController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // 数字のみ許可
                          ],
                          decoration: InputDecoration(
                            border: UnderlineInputBorder(), // 枠線付きのデザイン
                          ),
                        ),
                      ),
                      Text('枚', style: TextStyle(fontFamily: 'makinas4'),),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            iconPrice = int.tryParse(_priceController!.text) ?? 0;
                            iconPrice = iconPrice + 1000;
                            _priceController!.text = iconPrice.toString();
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('売値とは？', style: TextStyle(fontFamily: 'makinas4'),),
                              content: Text('あなたの作ったアイコンをコピーしたい人に払ってもらう枚数です。売れた分だけあなたにも枚数が入ってきます。0枚でも大丈夫です。ちなみにいいねを１つもらうごとに100枚もらえます。', style: TextStyle(fontFamily: 'makinas4'),),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('閉じる'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('売値とは？', style: TextStyle(fontFamily: 'makinas4'),),
                    ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: postMoral,
                        onChanged: (bool? newValue) {
                          setState(() {
                            postMoral = newValue!;
                          });
                        },
                      ),
                      Text('不適切な投稿の可能性がある。')
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomImageButton(
                        screenWidth: screenWidth,
                        buttonText: '閉じる',
                        onPressed: () {
                          setState(() {
                            postCheck = false;
                            _disposeControllers();
                          });
                        },
                      ),
                      const SizedBox(width: 10), // ボタン間のスペース
                      //if (_detailController.text.length > 0 && _titleController.text.length > 0 && _titleController.text.length <= 20)
                      CustomImageButton(
                        screenWidth: screenWidth,
                        buttonText: '投稿する',
                        onPressed: () {
                          setState(() {
                            if (_detailController!.text.length == 0 || _titleController!.text.length == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('タイトルと説明を入力してください。'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else if ( _titleController!.text.length > 20) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('タイトルは20字以下です。'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              postCheck = false;
                              String iconTitle = _titleController!.text;
                              String iconDetail = _detailController!.text;
                              print('iconTitle: $iconTitle, iconDetail: $iconDetail');
                              createPostWithLikes(userId: uid, iconTitle: iconTitle, iconDetail: iconDetail, sensitivity: postMoral, userName: myName, originId: originId, originName: originName, originPostId:  originPostId, originPostTitle: originPostTitle, completion:(success) {
                                if (success) {
                                  print("Post created successfully!");
                                  setState(() {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('投稿が完了しました。'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    _titleController!.text = '';
                                    _detailController!.text = '';
                                  });
                                } else {
                                  print("Failed to create post.");
                                }
                              },);
                              _disposeControllers();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30,),
                  Text('※投稿の内容は誰でも見れるので、不適切な表現のある投稿は告知なしに削除する場合があります。何度も不適切な投稿をする場合は、アカウントを削除する場合もありますので、注意して投稿してください。グレーゾーンだと思ったら、「不適切な投稿の可能性がある」にチェックマークを入れてください。チェックマークを入れた場合でも、投稿、もしくはアカウントが削除される可能性があります。')
                ],
              ),
            ),
          ),

          //投稿の詳細
          if (postDetail)
          Container(
            height: screenHeight * 0.8, // 高さをscreenHeightの0.5倍に設定
            margin: const EdgeInsets.all(10), // 外側の余白
            padding: const EdgeInsets.all(10), // 内側の余白
            decoration: BoxDecoration(
              color: Colors.white, // 背景色
              border: Border.all(color: Colors.black, width: 2), // 外枠
              borderRadius: BorderRadius.circular(10), // 角丸
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'タイトル:  ${selectedIconPost.iconTitle}',
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenHeight * 0.027,
                    ),
                  ),
                  Text(
                    '投稿主:  ${selectedIconPost.userName}',
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenHeight * 0.027,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pixel Grid

                      _buildPixelGridFromFlat(flatGrid: selectedIconPost.flatGrid, postHeight: screenWidth * 0.8 / 0.65),
                      const SizedBox(width: 10), // グリッドとテキストフィールド間のスペース

                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(selectedIconPost.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
                            ? Icons.favorite
                            : Icons.favorite_border),
                            iconSize:  30,
                        onPressed: () {
                          likePost(selectedIconPost.id, selectedIconPost.userId,selectedIconPost);
                          setState(() {
                            selectedIconPost.usersWhoLiked.add(uid);
                          });
                        },
                      ),
                      Text('${selectedIconPost.likeCount}'),
                      IconButton(
                        icon: Icon(selectedIconPost.usersWhoInstalled.contains(_auth.currentUser?.uid ?? '')
                            ? Icons.download_done
                            : Icons.download),
                            iconSize: 30,
                        onPressed: () {
                          setState(() {
                            postDetail = true;
                          });
                        },
                      ),
                      Text('${selectedIconPost.installCount}'),
                      Spacer(),
                          IconButton(
                            icon: Icon(Icons.report),
                            onPressed: () {
                              showReportAlert(selectedIconPost.id, selectedIconPost.userId);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.block),
                            onPressed: () {
                              showBlockAlert(selectedIconPost.userId, selectedIconPost.userName);
                            },
                          ),
                          if (selectedIconPost.userId == _auth.currentUser?.uid)
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                showDeleteAlert(selectedIconPost.id);
                              },
                            ),
                    ],
                  ),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey), // 外枠の色
                      borderRadius: BorderRadius.circular(5), // 角を丸める（オプション）
                    ),
                    padding: const EdgeInsets.all(15), // 内側の余白
                    constraints: BoxConstraints(
                      maxHeight: 200, // 最大の高さを指定してスクロール領域を制限
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedIconPost.originId != selectedIconPost.userId)
                          Text(
                            'これは${selectedIconPost.originName}さんの「${selectedIconPost.originPostTitle}」を編集したものです。',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '作品の説明: ${selectedIconPost.iconDetail}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('売値',style: TextStyle(fontFamily: 'makinas4', fontSize: 20, fontWeight: FontWeight.bold),),
                      SizedBox(width: 10,),
                      Icon(Icons.military_tech, size: 40,),
                      Text('${selectedIconPost.price.toString() } 枚',style: TextStyle(fontFamily: 'makinas4', fontSize: 20, fontWeight: FontWeight.bold),),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('（所持：$myGachaPoint 枚)',style: TextStyle(fontFamily: 'makinas4', fontSize: 20, fontWeight: FontWeight.bold),),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('売値とは？', style: TextStyle(fontFamily: 'makinas4'),),
                              content: Text('誰かの作ったアイコンをコピーしたい人に払ってもらう枚数です。この金額を払うことであなたはいつでもこのアイコンを使ったり、編集したりできます。', style: TextStyle(fontFamily: 'makinas4'),),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('閉じる'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('売値とは？', style: TextStyle(fontFamily: 'makinas4'),),
                    ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomImageButton(
                        screenWidth: screenWidth,
                        buttonText: '閉じる',
                        onPressed: () {
                          setState(() {
                            postDetail = false;
                          });
                        },
                      ),
                      const SizedBox(width: 10), // ボタン間のスペース
                      if (!(selectedIconPost.usersWhoInstalled.contains(uid) || selectedIconPost.userId == uid))
                      CustomImageButton(
                        screenWidth: screenWidth,
                        buttonText: '購入する',
                        onPressed: () {
                          setState(() {
                            showPurchaseAlert(selectedIconPost.id);
                          });
                        },
                      ),
                      if (selectedIconPost.usersWhoInstalled.contains(uid) || selectedIconPost.userId == uid)
                      CustomImageButton(
                        screenWidth: screenWidth,
                        buttonText: '使用する',
                        onPressed: () {
                          setState(() {
                            setIconOrigin(selectedIconPost);
                            grid = List.generate(gridNumber, (y) {
                              return List.generate(gridNumber, (x) {
                                int index = y * gridNumber + x;

                                // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
                                if (index >= 0 && index < selectedIconPost.flatGrid.length) {
                                  return selectedIconPost.flatGrid[index]; // String を返す
                                } else {
                                  return ''; // デフォルト値
                                }
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('アイコンのコピーが完了しました。'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (getMoneyView)
          Container(
            height: screenHeight * 0.8, // 高さをscreenHeightの0.5倍に設定
            width: screenWidth * 0.9,
            margin: EdgeInsets.all(screenWidth * 0.05), // 外側の余白
            padding: const EdgeInsets.all(10), // 内側の余白
            decoration: BoxDecoration(
              color: Colors.white, // 背景色
              border: Border.all(color: Colors.black, width: 2), // 外枠
              borderRadius: BorderRadius.circular(10), // 角丸
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), // 影の色と透明度
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // 影の位置
                ),
              ],
            ),
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('おめでとう！！', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),),
                SizedBox(height: 30,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text('総いいね', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _heartAnimation,
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 60,
                              ),
                            ),
                          ],
                        ),

                            Text('$iconAllLike', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06),),
                      ],
                    ),
                    SizedBox(width: 30),
                    Column(
                      children: [
                        Text('総購入数', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SlideTransition(
                              position: _downloadAnimation,
                              child: Icon(
                                Icons.download,
                                color: Colors.blue,
                                size: 60,
                              ),
                            ),
                          ],

                        ),

                            Text('$iconAllInstall', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06),),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 30,),

                Text('いいねと購入数が\n合計$displayIconInfoCount増えたよ！', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06),),
                SizedBox(height: 15,),
                Text('今回の報酬は\n${endIconMoney - startIconMoney}枚！', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06)),
                SizedBox(height: 40,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('現在', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06),),
                    Icon(Icons.military_tech, size: 40,),
                    Text('$displayedGachaPoint枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06),),
                  ],
                ),

                SizedBox(height: 40,),





                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageButton(screenWidth: screenWidth, buttonText: '受け取る', onPressed: () {
                      animateGachaPoint(startIconMoney, endIconMoney);
                      setState(() {
                        getMoneyClose = true;
                      });
                    }),
                    if (getMoneyClose)
                    CustomImageButton(screenWidth: screenWidth, buttonText: '閉じる', onPressed: () {
                      setState(() {
                        getMoneyView = false;
                      });
                    }),
                  ],
                )

              ],
            ),
          ), //ここまでが、受け取り画面
        ]
      ),
    );
  }

  /*




  ここから投稿用関数




  */
  Future<void> createPostWithLikes({
    required String userId,
    required String iconTitle,
    required String iconDetail,
    required bool sensitivity,
    required String userName,
    required String originId,
    required String originName,
    required String originPostId,
    required String originPostTitle,
    required Function(bool) completion,
  }) async {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final postRef = db.collection('iconPosts').doc();
    final usersRef = db.collection('newUserData').doc(auth.currentUser?.uid);
    List<String> flatGrid = grid.expand((row) => row).toList();

    final postData = {
      'userId': userId,
      'userName': userName,
      'originId': originId,
      'originName': originName,
      'originPostId': originPostId, //'null'ならオリジナル。
      'originPostTitle': originPostTitle,
      'icon': flatGrid,
      'iconTitle': iconTitle,
      'iconDetail': iconDetail,
      'sensitivity': sensitivity,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'bads': 0,
      'price': int.tryParse(_priceController!.text) ?? 0,
      'reports': 0,
      'usersWhoLiked': [],
      'installs': 0,
      'usersWhoInstalled': [],
    };

    try {
      // バッチ書き込み
      WriteBatch batch = db.batch();
      batch.set(postRef, postData);
      await batch.commit();

      // ユーザーデータを更新
      DocumentSnapshot userSnapshot = await usersRef.get();
      if (userSnapshot.exists) {
        Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;
        if (userData?['iconPosts'] != null) {
          List<dynamic> myPosts = userData?['iconPosts'] as List<dynamic>;
          myPosts.add(postRef.id);
          await usersRef.set({'iconPosts': myPosts}, SetOptions(merge: true));
        } else {
          await usersRef.set({'iconPosts': [postRef.id]}, SetOptions(merge: true));
        }
      } else {
        // ユーザーデータが存在しない場合、新規作成
        await usersRef.set({'iconPosts': [postRef.id]}, SetOptions(merge: true));
      }

      print('Documents added with ID: ${postRef.id}');
      completion(true);
    } catch (e) {
      print('Error adding documents: $e');
      completion(false);
    }
  }

  Future<void> fetchLatestIconsWithLikes({int limit = 8}) async {
  if (isLoading) return; // Prevent multiple simultaneous fetches
  timeLineIcons = [];
  setState(() {
    isLoading = true;
  });


  print('fetching latest post!!');

  try {
    Query query = _firestore.collection('iconPosts')
        .orderBy('timestamp', descending: true) // 新しい順に並べる
        .limit(limit);

    if (timeLineIcons.isNotEmpty) {
      // 最初の投稿のタイムスタンプより新しいものを取得
      query = query.startAt([timeLineIcons.first.timestamp]);
    }

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    List<IconWithLikes> latestIconsWithLikes = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String userId = data['userId']  as String;
        String userName = data['userName']as String;
        String postOriginId = data['originId']as String;
        String postOriginName = data['originName']as String;
        String postOriginPostId = data['originPostId']as String;
        String postOriginPostTitle = data['originPostTitle']as String;
        String iconTitle = data['iconTitle']as String;
        print(iconTitle);
        String iconDetail = data['iconDetail']as String;
        print(iconDetail);
        Timestamp timestamp = data['timestamp'] as Timestamp;
        int likes = data['likes'] as int;
        int installs = data['installs'] as int;
        int bads = data['bads'] as int;
        int price = data['price'] as int;
        bool sensitivity = data['sensitivity'] as bool;

        String postId = doc.id;
        List<String> flatGrid = List<String>.from((data['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: postId,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );

        if (!timeLineIcons.any((post) => post.id == postId && post.timestamp == postWithLikes.timestamp)) {
          latestIconsWithLikes.add(postWithLikes);
        }
        print('post loaded!');
      }
      setState(() {
        timeLineIcons.insertAll(0, latestIconsWithLikes); // 新しい投稿をリストの先頭に追加
        timeLineIcons.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 並べ替え
        lastDocument = querySnapshot.docs.last;
        isLoading = false;
      });

    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching latest posts: $error");
    }
  }

  Future<void> fetchOlderIconsWithLikes({int limit = 8}) async {
    if (isLoading) return;  // Prevent multiple simultaneous fetches
    setState(() {
      isLoading = true;
    });

    try {
      Query query = _firestore.collection('iconPosts')
          .orderBy('timestamp', descending: true) // 降順で新しい順に並べる
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!); // 最後のドキュメントから開始
      }

      // Fetch the posts
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<IconWithLikes> newIconsWithLikes = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        String userId = data['userId']  as String;
        String userName = data['userName']as String;
        String postOriginId = data['originId']as String;
        String postOriginName = data['originName']as String;
        String postOriginPostId = data['originPostId']as String;
        String postOriginPostTitle = data['originPostTitle']as String;
        String iconTitle = data['iconTitle']as String;
        String iconDetail = data['iconDetail']as String;
        Timestamp timestamp = data['timestamp'] as Timestamp;
        int likes = data['likes'] as int;
        int installs = data['installs'] as int;
        int bads = data['bads'] as int;
        int price = data['price'] as int;
        bool sensitivity = data['sensitivity'] as bool;

        String postId = doc.id;
        List<String> flatGrid = List<String>.from((data['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: postId,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );

        if (!timeLineIcons.any((post) => post.id == postId && post.timestamp == postWithLikes.timestamp)) {
          newIconsWithLikes.add(postWithLikes);
        }
      }

      // Update the posts with the fetched data
      setState(() {
        timeLineIcons.addAll(newIconsWithLikes); // 新しい投稿をリストの末尾に追加
        timeLineIcons.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        lastDocument = querySnapshot.docs.last;
        isLoading = false;
      });

    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching posts: $error");
    }
  }

  Future<void> fetchPostsByUser(String userId, Function(List<IconWithLikes>?) completion) async {
    final db = FirebaseFirestore.instance;
    postsByUser = [];

    try {
      // Fetch the user's document from Firestore
      DocumentSnapshot userDocument = await db.collection("newUserData").doc(userId).get();

      if (!userDocument.exists || userDocument.data() == null) {
        print("No posts found for the user");
        completion(null);
        return;
      }

      Map<String, dynamic>? userData = userDocument.data() as Map<String, dynamic>?;
      print('kokokamo');
      List<String> myPosts = List<String>.from((userData?["iconPosts"] as List).map((e) => e.toString()));
      print('kokokamo');
      List<IconWithLikes> postsWithLikes = [];
      List<Future> fetchFutures = [];

      for (String postId in myPosts) {
        print("Fetching post with ID: $postId");

        fetchFutures.add(db.collection("iconPosts").doc(postId).get().then((postDocument) async {
          if (!postDocument.exists || postDocument.data() == null) {
            print("Post not found");
            return;
          }

          Map<String, dynamic>? data = postDocument.data();
          String userId = data?['userId']  as String;
        String userName = data?['userName']as String;
        String postOriginId = data?['originId']as String;
        String postOriginName = data?['originName']as String;
        String postOriginPostId = data?['originPostId']as String;
        String postOriginPostTitle = data?['originPostTitle']as String;
        String iconTitle = data?['iconTitle']as String;
        String iconDetail = data?['iconDetail']as String;
        Timestamp timestamp = data?['timestamp'] as Timestamp;
        int likes = data?['likes'] as int;
        int installs = data?['installs'] as int;
        int bads = data?['bads'] as int;
        int price = data?['price'] as int;
        bool sensitivity = data?['sensitivity'] as bool;

        List<String> flatGrid = List<String>.from((data?['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data?['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data?['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: postId,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );


          postsWithLikes.add(postWithLikes);
        }));
      }

      await Future.wait(fetchFutures);
      completion(postsWithLikes);
    } catch (e) {
      print("Error fetching posts by user: $e");
      completion(null);
    }
  }

  Future<void> fetchPostsLikedByUser(String userId, Function(List<IconWithLikes>?) completion) async {
    final db = FirebaseFirestore.instance;
    likeIcons = [];

    try {
      // Fetch the user's document from Firestore
      DocumentSnapshot userDocument = await db.collection("newUserData").doc(userId).get();

      if (!userDocument.exists || userDocument.data() == null) {
        print("No posts found for the user");
        completion(null);
        return;
      }

      Map<String, dynamic>? userData = userDocument.data() as Map<String, dynamic>?;
      List<String> myPosts = List<String>.from((userData?["likeIcons"] as List).map((e) => e.toString()));
      List<IconWithLikes> postsWithLikes = [];
      List<Future> fetchFutures = [];

      for (String postId in myPosts) {
        print("Fetching post with ID: $postId");

        fetchFutures.add(db.collection("iconPosts").doc(postId).get().then((postDocument) async {
          if (!postDocument.exists || postDocument.data() == null) {
            print("Post not found");
            return;
          }

          Map<String, dynamic>? data = postDocument.data();
          String userId = data?['userId']  as String;
        String userName = data?['userName']as String;
        String postOriginId = data?['originId']as String;
        String postOriginName = data?['originName']as String;
        String postOriginPostId = data?['originPostId']as String;
        String postOriginPostTitle = data?['originPostTitle']as String;
        String iconTitle = data?['iconTitle']as String;
        String iconDetail = data?['iconDetail']as String;
        Timestamp timestamp = data?['timestamp'] as Timestamp;
        int likes = data?['likes'] as int;
        int installs = data?['installs'] as int;
        int bads = data?['bads'] as int;
        int price = data?['price'] as int;
        bool sensitivity = data?['sensitivity'] as bool;

        List<String> flatGrid = List<String>.from((data?['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data?['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data?['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: postId,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );


          postsWithLikes.add(postWithLikes);
        }));
      }

      await Future.wait(fetchFutures);
      completion(postsWithLikes);
    } catch (e) {
      print("Error fetching posts by user: $e");
      completion(null);
    }
  }

  Future<void> fetchPostsInstalledByUser(String userId, Function(List<IconWithLikes>?) completion) async {
    final db = FirebaseFirestore.instance;
    installIcons = [];

    try {
      // Fetch the user's document from Firestore
      DocumentSnapshot userDocument = await db.collection("newUserData").doc(userId).get();

      if (!userDocument.exists || userDocument.data() == null) {
        print("No posts found for the user");
        completion(null);
        return;
      }

      Map<String, dynamic>? userData = userDocument.data() as Map<String, dynamic>?;
      List<String> myPosts = List<String>.from((userData?["installIcons"] as List).map((e) => e.toString()));
      List<IconWithLikes> postsWithLikes = [];
      List<Future> fetchFutures = [];

      for (String postId in myPosts) {
        print("Fetching post with ID: $postId");

        fetchFutures.add(db.collection("iconPosts").doc(postId).get().then((postDocument) async {
          if (!postDocument.exists || postDocument.data() == null) {
            print("Post not found");
            return;
          }

          Map<String, dynamic>? data = postDocument.data();
          String userId = data?['userId']  as String;
        String userName = data?['userName']as String;
        String postOriginId = data?['originId']as String;
        String postOriginName = data?['originName']as String;
        String postOriginPostId = data?['originPostId']as String;
        String postOriginPostTitle = data?['originPostTitle']as String;
        String iconTitle = data?['iconTitle']as String;
        String iconDetail = data?['iconDetail']as String;
        Timestamp timestamp = data?['timestamp'] as Timestamp;
        int likes = data?['likes'] as int;
        int installs = data?['installs'] as int;
        int bads = data?['bads'] as int;
        int price = data?['price'] as int;
        bool sensitivity = data?['sensitivity'] as bool;

        List<String> flatGrid = List<String>.from((data?['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data?['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data?['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: postId,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );


          postsWithLikes.add(postWithLikes);
        }));
      }

      await Future.wait(fetchFutures);
      completion(postsWithLikes);
    } catch (e) {
      print("Error fetching posts by user: $e");
      completion(null);
    }
  }

  Future<void> fetchWeekPopularPosts(Function(List<IconWithLikes>) completion) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(Duration(days: 7));

    try {
      // Query Firestore for posts within the past week, ordered by likes
      QuerySnapshot querySnapshot = await db
          .collection("iconPosts")
          .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
          .orderBy("likes", descending: true)
          .limit(40)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No documents found");
        completion([]);
        return;
      }

      List<IconWithLikes> topLikedPostsTemp = [];
      List<Future> fetchFutures = [];

      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        String id = document.id;
        String userId = data['userId']  as String;
        String userName = data['userName']as String;
        String postOriginId = data['originId']as String;
        String postOriginName = data['originName']as String;
        String postOriginPostId = data['originPostId']as String;
        String postOriginPostTitle = data['originPostTitle']as String;
        String iconTitle = data['iconTitle']as String;
        String iconDetail = data['iconDetail']as String;
        Timestamp timestamp = data['timestamp'] as Timestamp;
        int likes = data['likes'] as int;
        int installs = data['installs'] as int;
        int bads = data['bads'] as int;
        int price = data['price'] as int;
        bool sensitivity = data['sensitivity'] as bool;

        List<String> flatGrid = List<String>.from((data['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: id,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );

        topLikedPostsTemp.add(postWithLikes);
      }

      // Wait for all like data to be fetched
      await Future.wait(fetchFutures);
      topLikedPostsTemp.sort((a, b) => b.likeCount.compareTo(a.likeCount)); // Sort by likes descending
      completion(topLikedPostsTemp);
    } catch (error) {
      print("Error fetching top liked posts: $error");
      completion([]);
    }
  }

  Future<void> fetchMonthPopularPosts(Function(List<IconWithLikes>) completion) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(Duration(days: 30));

    try {
      // Query Firestore for posts within the past week, ordered by likes
      QuerySnapshot querySnapshot = await db
          .collection("iconPosts")
          .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(oneMonthAgo))
          .orderBy("likes", descending: true)
          .limit(40)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No documents found");
        completion([]);
        return;
      }

      List<IconWithLikes> topLikedPostsTemp = [];
      List<Future> fetchFutures = [];

      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        String id = document.id;
        String userId = data['userId']  as String;
        String userName = data['userName']as String;
        String postOriginId = data['originId']as String;
        String postOriginName = data['originName']as String;
        String postOriginPostId = data['originPostId']as String;
        String postOriginPostTitle = data['originPostTitle']as String;
        String iconTitle = data['iconTitle']as String;
        String iconDetail = data['iconDetail']as String;
        Timestamp timestamp = data['timestamp'] as Timestamp;
        int likes = data['likes'] as int;
        int installs = data['installs'] as int;
        int bads = data['bads'] as int;
        int price = data['price'] as int;
        bool sensitivity = data['sensitivity'] as bool;

        List<String> flatGrid = List<String>.from((data['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: id,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );

        topLikedPostsTemp.add(postWithLikes);
      }

      // Wait for all like data to be fetched
      await Future.wait(fetchFutures);
      topLikedPostsTemp.sort((a, b) => b.likeCount.compareTo(a.likeCount)); // Sort by likes descending
      completion(topLikedPostsTemp);
    } catch (error) {
      print("Error fetching top liked posts: $error");
      completion([]);
    }
  }

  Future<void> fetchTopPopularPosts(Function(List<IconWithLikes>) completion) async {
    final db = FirebaseFirestore.instance;

    try {
      // Query Firestore for posts within the past week, ordered by likes
      QuerySnapshot querySnapshot = await db
          .collection("iconPosts")
          .orderBy("likes", descending: true)
          .limit(40)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No documents found");
        completion([]);
        return;
      }

      List<IconWithLikes> topLikedPostsTemp = [];
      List<Future> fetchFutures = [];

      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        String id = document.id;
        String userId = data['userId']  as String;
        String userName = data['userName']as String;
        String postOriginId = data['originId']as String;
        String postOriginName = data['originName']as String;
        String postOriginPostId = data['originPostId']as String;
        String postOriginPostTitle = data['originPostTitle']as String;
        String iconTitle = data['iconTitle']as String;
        String iconDetail = data['iconDetail']as String;
        Timestamp timestamp = data['timestamp'] as Timestamp;
        int likes = data['likes'] as int;
        int installs = data['installs'] as int;
        int bads = data['bads'] as int;
        int price = data['price'] as int;
        bool sensitivity = data['sensitivity'] as bool;

        List<String> flatGrid = List<String>.from((data['icon'] as List).map((e) => e.toString()));
        List<String> usersWhoLiked = List<String>.from((data['usersWhoLiked'] as List).map((e) => e.toString()));
        List<String> usersWhoInstalled = List<String>.from((data['usersWhoInstalled'] as List).map((e) => e.toString()));

        var postWithLikes = IconWithLikes(
          id: id,
          userId: userId,
          userName: userName,
          originId: postOriginId,
          originName: postOriginName,
          originPostId: postOriginPostId,
          originPostTitle: postOriginPostTitle,
          iconTitle: iconTitle,
          iconDetail: iconDetail,
          flatGrid: flatGrid,
          timestamp: timestamp.toDate(),
          likeCount: likes,
          installCount: installs,
          badCount: bads,
          price: price,
          usersWhoLiked: usersWhoLiked,
          usersWhoInstalled: usersWhoInstalled,
          sensitivity: sensitivity,
        );

        topLikedPostsTemp.add(postWithLikes);
      }

      // Wait for all like data to be fetched
      await Future.wait(fetchFutures);
      topLikedPostsTemp.sort((a, b) => b.likeCount.compareTo(a.likeCount)); // Sort by likes descending
      completion(topLikedPostsTemp);
    } catch (error) {
      print("Error fetching top liked posts: $error");
      completion([]);
    }
  }

  String formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month}-${timestamp.day} ${timestamp.hour}:${timestamp.minute}';
  }

  Future<void> likePost(String postId, String postUserId, IconWithLikes postList) async {
    try {
      final db = FirebaseFirestore.instance;
      final postRef = db.collection('iconPosts').doc(postId);
      final usersRef = db.collection('newUserData').doc(FirebaseAuth.instance.currentUser?.uid ?? '');
      final postUsersRef = db.collection('newUserData').doc(postUserId);
      print(FirebaseAuth.instance.currentUser?.uid);

      // トランザクションを使用して、複数のドキュメントを安全に更新
      await db.runTransaction((transaction) async {

        // userDataドキュメントを取得
        final userSnapshot = await transaction.get(usersRef);
        if (!userSnapshot.exists) {
          throw Exception("User document does not exist");
        }

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw Exception("Post document does not exist");
        }

        final postUserSnapshot = await transaction.get(postUsersRef);
        if (!postUserSnapshot.exists) {
          throw Exception("Post document does not exist");
        }

        if (userSnapshot.data()?['likeIcons'] != null) {
          List<String> likePosts = List<String>.from(
            ((userSnapshot.data()?['likeIcons']) as List).map((e) => e.toString()),
          );
          if (!likePosts.contains(postId)){
            likePosts.add(postId);
          }
          transaction.update(usersRef, {'likeIcons': likePosts});
        } else {
          await usersRef.set({'likeIcons': [postId]}, SetOptions(merge: true));
        }
        // skillLikesのデータを取得
        List<String> usersWhoLiked = List<String>.from((postSnapshot.data()?['usersWhoLiked'] as List).map((e) => e.toString())) ?? [];
        var likeCount = postSnapshot.data()?['likes'] ?? 0;
        // // 既に「いいね」している場合、処理を終了
        if (usersWhoLiked.contains(FirebaseAuth.instance.currentUser?.uid ?? '')) {
          print('いいね済み');
          return;
        }

        // // いいねを追加


        setState(() {
          usersWhoLiked.add(FirebaseAuth.instance.currentUser?.uid ?? '');
        });

        // トランザクションでデータを更新
        transaction.update(postRef, {'likes': likeCount + 1});
        transaction.update(postRef, {'usersWhoLiked': usersWhoLiked});

        transaction.update(postUsersRef, {
          'iconLikeCount': FieldValue.increment(1),
          'iconAllMoney': FieldValue.increment(100),
        });
      });

      print("Transaction successfully committed!");
    } catch (e) {
      print("Error liking post: $e");
    }
  }

  Future<void> installPost(String postId, String postUserId, IconWithLikes postList) async {
    try {
      final db = FirebaseFirestore.instance;
      final postRef = db.collection('iconPosts').doc(postId);
      final usersRef = db.collection('newUserData').doc(FirebaseAuth.instance.currentUser?.uid ?? '');
      final postUsersRef = db.collection('newUserData').doc(postUserId);
      print(FirebaseAuth.instance.currentUser?.uid);

      // トランザクションを使用して、複数のドキュメントを安全に更新
      await db.runTransaction((transaction) async {

        // userDataドキュメントを取得
        final userSnapshot = await transaction.get(usersRef);
        if (!userSnapshot.exists) {
          throw Exception("User document does not exist");
        }

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw Exception("Post document does not exist");
        }

        if (userSnapshot.data()?['installIcons'] != null) {
          List<String> installIcons = List<String>.from(
            ((userSnapshot.data()?['installIcons']) as List).map((e) => e.toString()),
          );
          if (!installIcons.contains(postId)){
            setState(() {
              installIcons.add(postId);
            });
          }
          transaction.update(usersRef, {'installIcons': installIcons});
        } else {
          await usersRef.set({'installIcons': [postId]}, SetOptions(merge: true));
        }
        // skillLikesのデータを取得
        List<String> usersWhoInstalled = List<String>.from((postSnapshot.data()?['usersWhoInstalled'] as List).map((e) => e.toString())) ?? [];
        var installCount = postSnapshot.data()?['installs'] ?? 0;
        // // 既に「いいね」している場合、処理を終了
        if (usersWhoInstalled.contains(FirebaseAuth.instance.currentUser?.uid ?? '')) {
          print('インストール済み');
          return;
        }

        // // いいねを追加

        setState(() {
          usersWhoInstalled.add(FirebaseAuth.instance.currentUser?.uid ?? '');
        });

        // トランザクションでデータを更新
        transaction.update(postRef, {'installs': installCount + 1});
        transaction.update(postRef, {'usersWhoInstalled': usersWhoInstalled});

        transaction.update(postUsersRef, {
          'iconInstallCount': FieldValue.increment(1),
          'iconAllMoney': FieldValue.increment(postList.price),
        });
      });

      print("Transaction successfully committed!");
    } catch (e) {
      print("Error installing post: $e");
    }
  }

  void addBlockUser(String userId) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('myBlockList', (prefs.getStringList('myBlockList') ?? []) + [userId]);
    setState(() {
      myBlockList = prefs.getStringList('myBlockList') ?? [];
    });
  }

  void showReportAlert(String postId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("確認"),
          content: Text("この投稿を通報してもよろしいですか？"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                reportPost(postId); // 投稿を通報する処理を実行
              },
              child: Text("はい"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("いいえ"),
            ),
          ],
        );
      },
    );
  }

  void showBlockAlert(String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("確認", style: TextStyle(fontFamily: 'makinas4'),),
          content: Text("$userNameさんをブロックしますか？", style: TextStyle(fontFamily: 'makinas4'),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                addBlockUser(userId); // ユーザーをブロックする処理を実行
              },
              child: Text("はい", style: TextStyle(fontFamily: 'makinas4'),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("いいえ", style: TextStyle(fontFamily: 'makinas4'),),
            ),
          ],
        );
      },
    );
  }

  Future<void> reportPost(String postId) async {
    try {
      // Firestoreのインスタンスを取得
      final db = FirebaseFirestore.instance;
      final reportRef = db.collection('iconPosts').doc(postId);

      // ドキュメントが存在するか確認
      final docSnapshot = await reportRef.get();

      if (docSnapshot.exists) {
        // ドキュメントが存在する場合、reportCountをインクリメント
        await reportRef.update({
          'reports': FieldValue.increment(1),
        });
        print("Document successfully updated");
      } else {
        // ドキュメントが存在しない場合、新しいドキュメントを作成
        await reportRef.set({
          'reportCount': 1,
        });
        print("Document successfully created");
      }
    } catch (e) {
      print("Error reporting post: $e");
    }
  }

  void showDeleteAlert(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("確認"),
          content: Text("この投稿を削除してもよろしいですか？"),
          actions: [
            TextButton(
              onPressed: () {
                // はいボタンが押された場合
                deletePostWithLikes(postId); // 削除処理を呼び出す
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("はい"),
            ),
            TextButton(
              onPressed: () {
                // いいえボタンが押された場合
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("いいえ"),
            ),
          ],
        );
      },
    );
  }

  void showPurchaseAlert(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("確認"),
          content: Text('この投稿を購入しますか？\n売値: ${selectedIconPost.price} 枚\n所持: $myGachaPoint 枚', style: TextStyle(fontFamily: 'makinas4'),),
          actions: [
            TextButton(
              onPressed: () {
                // はいボタンが押された場合
                if (myGachaPoint >= selectedIconPost.price) {
                  installPost(postId, selectedIconPost.userId, selectedIconPost); // 削除処理を呼び出す
                  purchaseIcon(selectedIconPost.price);
                  selectedIconPost.usersWhoInstalled.add(uid);
                  Navigator.of(context).pop(); // ダイアログを閉じる
                } else {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                }
              },
              child: Text("はい"),
            ),
            TextButton(
              onPressed: () {
                // いいえボタンが押された場合
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("いいえ"),
            ),
          ],
        );
      },
    );
  }

  void showResetAlert(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("確認"),
          content: Text("キャンバスをリセットしてもいいですか？今の状況を保存したいなら投稿してからリセットしてください。"),
          actions: [
            TextButton(
              onPressed: () {
                // はいボタンが押された場合
                resetIconOrigin();
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("リセット"),
            ),
            TextButton(
              onPressed: () {
                // いいえボタンが押された場合
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text("編集を続行"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deletePostWithLikes(String postId) async {
    try {
      final db = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      final userId = user.uid;
      final postRef = db.collection('iconPosts').doc(postId);
      final usersRef = db.collection('newUserData').doc(userId);

      // バッチ書き込みで、複数の削除処理をまとめて実行
      WriteBatch batch = db.batch();

      batch.delete(postRef);

      // バッチコミットを実行
      await batch.commit();

      print("Documents deleted with ID: $postId");

      // ユーザー情報を更新
      final userDocSnapshot = await usersRef.get();

      if (!userDocSnapshot.exists) {
        print("User document does not exist");
        return;
      }

      final userData = userDocSnapshot.data();
      if (userData != null) {
        List<String> myPosts = List<String>.from((userData['iconPosts'] as List).map((e) => e.toString()));

        // 投稿IDをユーザーの投稿リストから削除
        myPosts.remove(postId);

        // 更新された投稿IDリストをユーザー情報にセット
        await usersRef.set({
          'iconPosts': myPosts,
        }, SetOptions(merge: true));

        print("User document updated");
      } else {
        print("User data is not in the expected format");
      }
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  /*






  ピクセルアート用






  */

  Widget _buildPixelGrid({
    required List<List<String>> grid,
  })  {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;

  final cellSize = (min(screenWidth * 0.9, screenHeight * 0.45) / gridNumber).floorToDouble();
  final containerSize = cellSize * gridNumber;

  return Stack(
    children: [
      Image.asset(
        'Images/backGround.png',
        height: containerSize,
        width: containerSize,
        fit: BoxFit.fill,
      ),
      Container(
        height: containerSize,
        width: containerSize,
        color: const Color.fromARGB(148, 255, 255, 255),
      ),
      SizedBox(
        width: containerSize,
        height: containerSize,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridNumber,
            childAspectRatio: 1,
          ),
          itemCount: gridNumber * gridNumber,
          itemBuilder: (context, index) {
            int row = index ~/ gridNumber;
            int col =
            index % gridNumber;
            return GestureDetector(
              onTap: () {
                if (drawMode) {
                  setState(() {
                    grid[row][col] = selectedColor.value.toRadixString(16);// 色コードを変更（赤色に設定）
                  });
                }
                if (!drawMode) {
                  String tappedColorHex = grid[row][col]; // 保存されている色コード
                  Color tappedColor = Color(int.parse('0xFF$tappedColorHex'));
                  setState(() {
                    selectedColor = tappedColor; // 選択された色を更新
                  });
                }
              },
              child: Container(
                color: Color(int.parse('0xFF' + grid[row][col])),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildPixelGridFromFlat({
    required List<String> flatGrid,
    required double postHeight,
  })  {

  final cellSize = ((postHeight * 0.65) / gridNumber).floorToDouble();
  final containerSize = cellSize * gridNumber;

  List<List<String>> grid = List.generate(gridNumber, (y) {
    return List.generate(gridNumber, (x) {
      int index = y * gridNumber + x;

      // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
      if (index >= 0 && index < flatGrid.length) {
        return flatGrid[index]; // String を返す
      } else {
        return ''; // デフォルト値
      }
    });
  });

  return Stack(
    children: [
      SizedBox(
        width: containerSize,
        height: containerSize,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridNumber,
            childAspectRatio: 1,
          ),
          itemCount: gridNumber * gridNumber,
          itemBuilder: (context, index) {
            int row = index ~/ gridNumber;
            int col =
            index % gridNumber;
            return Container(
                color: Color(int.parse('0xFF' + grid[row][col])),
              );
          },
        ),
      ),
    ],
  );
}

  Widget _buildCachedView() {
    return ClipRect(
      child:
    Transform(
      transform: _cachedMatrix ?? Matrix4.identity(),
      child: _buildPixelGrid(grid: grid),
    )
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

class PostCard extends StatefulWidget {
  final IconWithLikes post;
  final double postHeight;
  final Function(String postId, String userId, IconWithLikes post) likePost;
  final Function(String postId, String userId) showReportAlert;
  final Function(String userId, String userName) showBlockAlert;
  final Function(String postId) showDeleteAlert;
  final VoidCallback onInstallPressed;
  final VoidCallback postDetailCheck;
  final String currentUserId;

  const PostCard({
    Key? key,
    required this.post,
    required this.postHeight,
    required this.likePost,
    required this.showReportAlert,
    required this.showBlockAlert,
    required this.showDeleteAlert,
    required this.onInstallPressed,
     required this.postDetailCheck,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

String formatTimestamp(DateTime timestamp) {
  return '${timestamp.year}-${timestamp.month}-${timestamp.day} ${timestamp.hour}:${timestamp.minute}';
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isCurrentUser = widget.currentUserId == post.userId;

    return Card(
  margin: const EdgeInsets.symmetric(vertical: 10),
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!post.sensitivity)
                  _buildPixelGridFromFlat(
                    post: post,
                    postHeight: widget.postHeight,
                    gridNumber: 32,
                  ),
                if (post.sensitivity)
                  const Text('不適切な内容の可能性があります。\nタップして閲覧できます。'),
                if (!post.sensitivity)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ' 投稿主: ${post.userName}',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 111, 111, 111),
                                fontFamily: 'makinas4',
                              ),
                            ),
                            Text(
                              formatTimestamp(post.timestamp),
                              style: const TextStyle(
                                color: Color.fromARGB(255, 111, 111, 111),
                              ),
                            ),
                          ],
                        ),
                        if (post.userId != post.originId)
                          const Text(
                            ' 二次創作',
                            style: TextStyle(
                              color: Color.fromARGB(255, 111, 111, 111),
                              fontFamily: 'makinas4',
                            ),
                          ),
                        if (post.userId == post.originId)
                          const Text(
                            ' オリジナル作品',
                            style: TextStyle(fontFamily: 'makinas4'),
                          ),
                        Text(
                          ' タイトル: ${post.iconTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'makinas4', fontSize: 18),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (post.sensitivity)
              ElevatedButton(
                onPressed: () {
                  widget.postDetailCheck;
                },
                child: const Text('表示する'),
              ),
          ],
        ),
      ),
      Positioned(
        bottom: - widget.postHeight * 0.1,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.usersWhoLiked.contains(widget.currentUserId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  iconSize: widget.postHeight * 0.12,
                  onPressed: () {
                    widget.likePost(post.id, post.userId, post);
                    setState(() {
                      post.usersWhoLiked.add(widget.currentUserId);
                    });
                  },
                ),
                Text('${post.likeCount}'),
                IconButton(
                  icon: Icon(
                    post.usersWhoInstalled.contains(widget.currentUserId)
                        ? Icons.download_done
                        : Icons.download,
                  ),
                  iconSize: widget.postHeight * 0.12,
                  onPressed: () => widget.onInstallPressed(),
                ),
                Text('${post.installCount}'),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon:  const Icon(Icons.report),
                  iconSize: widget.postHeight * 0.12,
                  onPressed: () => widget.showReportAlert(post.id, post.userId),
                ),
                IconButton(
                  icon: const Icon(Icons.block),
                  iconSize: widget.postHeight * 0.12,
                  onPressed: () => widget.showBlockAlert(post.userId, post.userName),
                ),
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: widget.postHeight * 0.12,
                    onPressed: () => widget.showDeleteAlert(post.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
);

    // Card(
    //   margin: const EdgeInsets.symmetric(vertical: 10),
    //   child: Padding(
    //     padding: const EdgeInsets.all(5),
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             if (!post.sensitivity)
    //               _buildPixelGridFromFlat(post: post, postHeight: widget.postHeight, gridNumber: 32,),
    //             if (post.sensitivity)
    //               const Text('不適切な内容の可能性があります。\nタップして閲覧できます。'),
    //             if (!post.sensitivity)
    //               Expanded(
    //                 child: Column(
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     Row(
    //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                       children: [
    //                         Text(
    //                           ' 投稿主: ${post.userName}',
    //                           style: const TextStyle(
    //                             color: Color.fromARGB(255, 111, 111, 111),
    //                             fontFamily: 'makinas4',
    //                           ),
    //                         ),
    //                         Text(
    //                           formatTimestamp(post.timestamp),
    //                           style: const TextStyle(
    //                             color: Color.fromARGB(255, 111, 111, 111),
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                     if (post.userId != post.originId)
    //                       const Text(
    //                         ' 二次創作',
    //                         style: TextStyle(
    //                           color: Color.fromARGB(255, 111, 111, 111),
    //                           fontFamily: 'makinas4',
    //                         ),
    //                       ),
    //                     if (post.userId == post.originId)
    //                       const Text(
    //                         ' オリジナル作品',
    //                         style: TextStyle(fontFamily: 'makinas4'),
    //                       ),
    //                     const SizedBox(height: 8),
    //                     Text(
    //                       ' タイトル: ${post.iconTitle}',
    //                       maxLines: 1,
    //                       overflow: TextOverflow.ellipsis,
    //                       style: const TextStyle(fontFamily: 'makinas4', fontSize: 18),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //           ],
    //         ),
    //         if (post.sensitivity)
    //           ElevatedButton(
    //             onPressed: () {widget.postDetailCheck;},
    //             child: const Text('表示する'),
    //           ),
    //         Row(
    //           children: [
    //             IconButton(
    //               icon: Icon(
    //                 post.usersWhoLiked.contains(widget.currentUserId)
    //                     ? Icons.favorite
    //                     : Icons.favorite_border,
    //               ),
    //               iconSize: widget.postHeight * 0.14,
    //               onPressed: () {
    //                 widget.likePost(post.id, post.userId, post);
    //                 setState(() {
    //                   post.usersWhoLiked.add(widget.currentUserId);
    //                 });
    //               },
    //             ),
    //             Text('${post.likeCount}'),
    //             IconButton(
    //               icon: Icon(
    //                 post.usersWhoInstalled.contains(widget.currentUserId)
    //                     ? Icons.download_done
    //                     : Icons.download,
    //               ),
    //               iconSize: widget.postHeight * 0.14,
    //               onPressed: () => widget.onInstallPressed(),
    //             ),
    //             Text('${post.installCount}'),
    //             const Spacer(),
    //             IconButton(
    //               icon: const Icon(Icons.report),
    //               onPressed: () => widget.showReportAlert(post.id, post.userId),
    //             ),
    //             IconButton(
    //               icon: const Icon(Icons.block),
    //               onPressed: () => widget.showBlockAlert(post.userId, post.userName),
    //             ),
    //             if (isCurrentUser)
    //               IconButton(
    //                 icon: const Icon(Icons.delete),
    //                 onPressed: () => widget.showDeleteAlert(post.id),
    //               ),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}

class _buildPixelGridFromFlat extends StatefulWidget {
  final IconWithLikes post;
  final double postHeight;
  final int gridNumber;

  const _buildPixelGridFromFlat({
    Key? key,
    required this.post,
    required this.postHeight,
    required this.gridNumber,
  }) : super(key: key);

  @override
  __buildPixelGridFromFlatState createState() => __buildPixelGridFromFlatState();
}

class __buildPixelGridFromFlatState extends State<_buildPixelGridFromFlat> {
  @override
  Widget build(BuildContext context) {
    final cellSize = ((widget.postHeight * 0.65) / widget.gridNumber).floorToDouble();
    final containerSize = cellSize * widget.gridNumber;

    List<List<String>> grid = List.generate(widget.gridNumber, (y) {
      return List.generate(widget.gridNumber, (x) {
        int index = y * widget.gridNumber + x;

        // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
        if (index >= 0 && index < widget.post.flatGrid.length) {
          return widget.post.flatGrid[index]; // String を返す
        } else {
          return ''; // デフォルト値
        }
      });
    });

    return Stack(
      children: [
        SizedBox(
          width: containerSize,
          height: containerSize,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.gridNumber,
              childAspectRatio: 1,
            ),
            itemCount: widget.gridNumber * widget.gridNumber,
            itemBuilder: (context, index) {
              int row = index ~/ widget.gridNumber;
              int col =
              index % widget.gridNumber;
              return Container(
                  color: Color(int.parse('0xFF' + grid[row][col])),
                );
            },
          ),
        ),
      ],
    );
  }
}

// Card(
            //   margin: const EdgeInsets.symmetric(vertical: 10),
            //   child: Padding(
            //     padding: const EdgeInsets.all(5),
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             if (!post.sensitivity)
            //             _buildPixelGridFromFlat(flatGrid: post.flatGrid, postHeight: postHeight),
            //             if (post.sensitivity)
            //             Text('不適切な内容の可能性があります。\nタップして閲覧できます。'),


            //             if (!post.sensitivity)
            //             Expanded( // スペースに応じて適切に配置
            //               child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 Row(
            //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                   children: [
            //                     Text(' 投稿主: ${post.userName}',style: TextStyle(
            //                         color: const Color.fromARGB(255, 111, 111, 111),
            //                         fontFamily: 'makinas4'
            //                       ),), // 名前
            //                     Text(
            //                       formatTimestamp(post.timestamp), // 日時
            //                       style: TextStyle(
            //                         color: const Color.fromARGB(255, 111, 111, 111),
            //                       ),
            //                     ),
            //                   ],
            //                 ),

            //         if (post.userId != post.originId)
            //         Text(' 二次創作', style: TextStyle(
            //                 color: const Color.fromARGB(255, 111, 111, 111),
            //                 fontFamily: 'makinas4'
            //               ),),
            //         if (post.userId == post.originId)
            //         Text(' オリジナル作品',style: TextStyle(
            //           fontFamily: 'makinas4'
            //               ),),
            //         const SizedBox(height: 8), // 名前とタイトル間の余白
            //         Text(' タイトル: ${post.iconTitle}', style: TextStyle(fontFamily: 'makinas4', fontSize: 18),),

            //       ],
            //     ),
            //   ),

            //           ],
            //         ),
            //         if (post.sensitivity)
            //         ElevatedButton(onPressed: (){setState(() {postDetail = true;});}, child: Text('表示する')),
            //         Row(
            //           children: [
            //             IconButton(
            //               icon: Icon(post.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
            //                   ? Icons.favorite
            //                   : Icons.favorite_border),
            //                   iconSize: postHeight * 0.14,
            //               onPressed: () {
            //                 likePost(post.id, post.userId, post);
            //                 setState(() {
            //                   post.usersWhoLiked.add(uid);
            //                 });
            //               },
            //             ),
            //             Text('${post.likeCount}'),
            //             IconButton(
            //               icon: Icon(post.usersWhoInstalled.contains(_auth.currentUser?.uid ?? '')
            //                   ? Icons.download_done
            //                   : Icons.download),
            //                   iconSize: postHeight * 0.14,
            //               onPressed: () {
            //                 setState(() {
            //                   selectedIconPost = post;
            //                   postDetail = true;
            //                 });
            //               },
            //             ),
            //             Text('${post.installCount}'),
            //             Spacer(),
            //                 IconButton(
            //                   icon: Icon(Icons.report),
            //                   onPressed: () {
            //                     showReportAlert(post.id, post.userId);
            //                   },
            //                 ),
            //                 IconButton(
            //                   icon: Icon(Icons.block),
            //                   onPressed: () {
            //                     showBlockAlert(post.userId, post.userName);
            //                   },
            //                 ),
            //                 if (post.userId == _auth.currentUser?.uid)
            //                   IconButton(
            //                     icon: Icon(Icons.delete),
            //                     onPressed: () {
            //                       showDeleteAlert(post.id);
            //                     },
            //                   ),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ),
            // ),





