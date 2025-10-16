import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screen/RankingScreen.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BoardScreen extends StatefulWidget {
  @override
  _BoardScreenState createState() => _BoardScreenState();
}
class _BoardScreenState extends State<BoardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late ScrollController _scrollController;
  DocumentSnapshot? lastDocument;
  List<PostWithLikes> timeLinePosts = [];
  List<PostWithLikes> likePosts = [];
  List<PostWithLikes> postsByUser = [];
  List<PostWithLikes> popularWeekPosts = [];
  List<PostWithLikes> popularMonthPosts = [];
  List<PostWithLikes> popularAllPosts = [];
  List<PostWithLikes> topLikedPosts = [];
  String nowPost = 'rule';

  String skillType = "強化系";
  String skillTypeDetail = "例）自分の得るポイントが増えるスキル";
  String skillName = "";
  String skillDetail = "";
  int skillNameLimit = 15;
  int skillDetailLimit = 200;
  bool showAlert = false;
  String alertMessage = "";
  bool viewSkillPostConfirm = false;

  List<String> viewList = ['timeLine', 'tweet', 'myLike', 'myTweet', 'weekRanking', 'monthRanking', 'allRanking', 'realSkill', 'rule'];
  List<String> myBlockList = [];

  String userName = '';

  bool isLoading = false;

  BannerAd? _bannerAd;

  void checkWord() {
    if (skillName.isEmpty || skillDetail.isEmpty) {
      setState(() {
        alertMessage = "スキル名とスキルの効果を入力してください。";
        showAlert = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkAndInitializeLikePosts();
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
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // スクロールが末尾に到達した場合にデータを読み込む
        if (!isLoading) {
          fetchOlderPostsWithLikes();
        }
      }
    });
    _loadPreferences();
    fetchLatestPostsWithLikes();
    setState(() {
      print(topLikedPosts);
      topLikedPosts = topLikedPosts;
    });
  }

  void _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    myBlockList = prefs.getStringList('myBlockList') ?? [];
    if (myBlockList.isNotEmpty) {
      setState(() {
        nowPost = 'timeLine';
      });
    }
    userName = prefs.getString('myName') ?? '';
  }

  void initBlockList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if ((prefs.getStringList('myBlockList') ?? []).isEmpty ) {
      prefs.setStringList('myBlockList', ['sample']);
    }
  }

  String formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month}-${timestamp.day} ${timestamp.hour}:${timestamp.minute}';
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 必ずdisposeする
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width ; // ボタンの幅
    final double screenHeight = screenSize.height ;  // ボタンの高さ


    _changeRoutePass() {
      context.go('/menu');
    }

    void updateNowPost(String option) {
      switch (option) {
        case 'timeLine':
        fetchLatestPostsWithLikes();
          break;
        case 'weekRanking':
        fetchWeekPopularPosts((posts) {
          if (posts.isNotEmpty) {
            print("Fetched ${posts.length} popular posts for the week:");
            for (var post in posts) {
              print("Post ID: ${post.id}, Skill Name: ${post.skillName}, Likes: ${post.likes}");
            }
            setState(() {
              popularWeekPosts = [];
              popularWeekPosts = posts;
            });
          } else {
            print("No popular posts found for the week.");
          }
        });
        break;
        case 'monthRanking':
        fetchMonthPopularPosts((posts) {
          if (posts.isNotEmpty) {
            print("Fetched ${posts.length} popular posts for the month:");
            for (var post in posts) {
              print("Post ID: ${post.id}, Skill Name: ${post.skillName}, Likes: ${post.likes}");
            }
            setState(() {
              popularMonthPosts = [];
              popularMonthPosts = posts;
            });
          } else {
            print("No popular posts found for the month.");
          }
        });
          break;
        case 'allRanking':
        fetchTopLikedPosts();
        break;
        case 'myLike':
        fetchPostsLikedByUser(uid, (posts) {
          if (posts != null) {
            print("Fetched ${posts.length} liked posts:");
            posts.forEach((post) {
              print("Post ID: ${post.id}, Skill Name: ${post.skillName}");
            });
            setState(() {
              likePosts = [];
              likePosts = posts;
            });
          } else {
            print("No posts found or an error occurred.");
          }
        });
        break;

        case 'myTweet':
        fetchPostsByUser(uid, (posts) {
          if (posts != null) {
            print("Fetched ${posts.length} posts by user:");
            for (var post in posts) {
              print("Post ID: ${post.id}, Skill Name: ${post.skillName}");
            }
            setState(() {
              postsByUser = [];
              postsByUser = posts;
            });
          } else {
            print("No posts found or an error occurred.");
          }
        });
        break;
        default:
      }
    }

    return Scaffold(
      body: Center( // Columnを画面全体の中央に配置
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center, // 子ウィジェットを横方向の中央に揃える
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
                Text('掲示板', style: TextStyle(fontFamily: 'makinas4', fontSize: 30),), // タイトルを追加
                Spacer(),
                DropdownButton<String>(
                  value: nowPost,
                  items: [
                    DropdownMenuItem(value: 'timeLine', child: Text('タイムライン', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'weekRanking', child: Text('週間人気', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'monthRanking', child: Text('月間人気', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'allRanking', child: Text('全期間人気', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'tweet', child: Text('投稿画面', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'myLike', child: Text('いいねした投稿', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'myTweet', child: Text('自分の投稿', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'realSkill', child: Text('実装されたスキル', style: TextStyle(fontFamily: 'makinas4', ))),
                    DropdownMenuItem(value: 'rule', child: Text('利用規約', style: TextStyle(fontFamily: 'makinas4', ))),
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
              ]
            ),
            if (nowPost == 'tweet')
            Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            skillType == "強化系"
                                ? SvgPicture.asset('Images/plus.svg', width: screenWidth * 0.15,)
                                : skillType == "妨害系"
                                    ? SvgPicture.asset('Images/minus.svg', width: screenWidth * 0.15,)
                                    : SvgPicture.asset('Images/special.svg', width: screenWidth * 0.15,),
                            SizedBox(width: 8),
                            DropdownButton<String>(
                              value: skillType,
                              onChanged: (String? newValue) {
                                setState(() {

                                  skillType = newValue!;
                                  if (skillType == "強化系") {
                                    skillTypeDetail = "例）自分の得るポイントが増えるスキル";
                                  } else if (skillType == "妨害系") {
                                    skillTypeDetail = "例）相手の得るポイントが減るスキル";
                                  } else if (skillType == "特殊系") {
                                    skillTypeDetail = "強化系でも妨害系でも無いスキル";
                                  }
                                });
                              },
                              items: <String>["強化系", "妨害系", "特殊系"]
                                  .map<DropdownMenuItem<String>>(
                                      (String value) => DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ))
                                  .toList(),
                            ),
                          ],
                        ),
                        Text(skillTypeDetail),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: "スキル名を入力",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              skillName = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${skillName.length}/$skillNameLimit"),
                            if (skillName.length > skillNameLimit)
                              Text(
                                "制限を超えています",
                                style: TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "スキルの効果を入力",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              skillDetail = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${skillDetail.length}/$skillDetailLimit"),
                            if (skillDetail.length > skillDetailLimit)
                              Text(
                                "制限を超えています",
                                style: TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: (skillName.length > skillNameLimit ||
                                  skillDetail.length > skillDetailLimit ||
                                  skillName.isEmpty ||
                                  skillDetail.isEmpty)
                              ? null
                              : () {
                                  checkWord();
                                  if (!showAlert) {
                                    createPostWithLikes(
                                      userId: uid,
                                      skillName: skillName,
                                      skillDetail: skillDetail,
                                      skillType: skillType,
                                      userName: userName,
                                      completion: (success) {
                                        if (success) {
                                          print("Post created successfully!");
                                          setState(() {
                                            skillDetail = '';
                                            skillName = '';
                                          });
                                        } else {
                                          print("Failed to create post.");
                                        }
                                      },
                                    );
                                  }
                                },
                          child: Text("投稿"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (timeLinePosts.isEmpty && nowPost == 'timeLine')
            Center(child: CircularProgressIndicator()),
            if (timeLinePosts.isNotEmpty && nowPost == 'timeLine')
            Expanded(child: // タイムライン
            ListView.builder(
              controller: _scrollController,
              itemCount: timeLinePosts.length,
              itemBuilder: (context, index) {
                PostWithLikes post = timeLinePosts[index];
                if (myBlockList.contains(post.userId)) {
                  return SizedBox.shrink(); // 空のウィジェットを返して非表示にする
                }
                return   Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("投稿主: ${post.userName}", style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111), fontFamily: 'makinas4'), ),
                            Text(formatTimestamp(post.timestamp), style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111))),
                          ],
                        ),
                        Row(
                          children: [
                            if (post.skillTypePost == "強化系")
                              SvgPicture.asset('Images/plus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "妨害系")
                              SvgPicture.asset('Images/minus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "特殊系")
                              SvgPicture.asset('Images/special.svg', width: screenWidth * 0.15),
                            SizedBox(width: 10,),
                            Text(post.skillName, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'makinas4', fontSize: screenWidth * 0.05)),
                          ],
                        ),
                        Text("スキルの説明: ${post.skillDetail}", style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline, fontSize: screenWidth * 0.04),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(post.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              onPressed: () {
                                likePost(post.id, post);
                                setState(() {
                                  post.usersWhoLiked.add(uid);
                                });
                              },
                            ),
                            Text("${post.likes}"),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.report),
                              onPressed: () {
                                showReportAlert(post.id, post.userId);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.block),
                              onPressed: () {
                                showBlockAlert(post.userId, post.userName);
                              },
                            ),
                            if (post.userId == _auth.currentUser?.uid)
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDeleteAlert(post.id);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),

            if (topLikedPosts.isEmpty && nowPost == 'allRanking')
            Center(child: CircularProgressIndicator()),
            if (topLikedPosts.isNotEmpty && nowPost == 'allRanking')
            Expanded(child: //全期間ランキング
            ListView.builder(
              itemCount: topLikedPosts.length,
              itemBuilder: (context, index) {
                PostWithLikes post = topLikedPosts[index];
                if (myBlockList.contains(post.userId)) {
                  return SizedBox.shrink(); // 空のウィジェットを返して非表示にする
                }
                return   Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("投稿主: ${post.userName}", style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111), fontFamily: 'makinas4'), ),
                            Text(formatTimestamp(post.timestamp), style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111))),
                          ],
                        ),
                        Row(
                          children: [
                            if (post.skillTypePost == "強化系")
                              SvgPicture.asset('Images/plus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "妨害系")
                              SvgPicture.asset('Images/minus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "特殊系")
                              SvgPicture.asset('Images/special.svg', width: screenWidth * 0.15),
                            SizedBox(width: 10,),
                            Text(post.skillName, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'makinas4', fontSize: screenWidth * 0.05)),
                          ],
                        ),
                        Text("スキルの説明: ${post.skillDetail}", style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline, fontSize: screenWidth * 0.04),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(post.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              onPressed: () {
                                likePost(post.id, post);
                                setState(() {
                                  post.usersWhoLiked.add(uid);
                                });
                              },
                            ),
                            Text("${post.likes}"),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.report),
                              onPressed: () {
                                showReportAlert(post.id, post.userId);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.block),
                              onPressed: () {
                                showBlockAlert(post.userId, post.userName);
                              },
                            ),
                            if (post.userId == _auth.currentUser?.uid)
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDeleteAlert(post.id);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),

            if (likePosts.isEmpty && nowPost == 'myLike')
            Center(child: CircularProgressIndicator()),
            if (likePosts.isNotEmpty && nowPost == 'myLike')
            Expanded(child: // いいねしたやつ
            ListView.builder(
              itemCount: likePosts.length,
              itemBuilder: (context, index) {
                PostWithLikes post = likePosts[index];
                if (myBlockList.contains(post.userId)) {
                  return SizedBox.shrink(); // 空のウィジェットを返して非表示にする
                }
                return   Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("投稿主: ${post.userName}", style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111), fontFamily: 'makinas4'), ),
                            Text(formatTimestamp(post.timestamp), style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111))),
                          ],
                        ),
                        Row(
                          children: [
                            if (post.skillTypePost == "強化系")
                              SvgPicture.asset('Images/plus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "妨害系")
                              SvgPicture.asset('Images/minus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "特殊系")
                              SvgPicture.asset('Images/special.svg', width: screenWidth * 0.15),
                            SizedBox(width: 10,),
                            Text(post.skillName, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'makinas4', fontSize: screenWidth * 0.05)),
                          ],
                        ),
                        Text("スキルの説明: ${post.skillDetail}", style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline, fontSize: screenWidth * 0.04),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(post.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              onPressed: () {
                                likePost(post.id, post);
                                setState(() {
                                  post.usersWhoLiked.add(uid);
                                });
                              },
                            ),
                            Text("${post.likes}"),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.report),
                              onPressed: () {
                                showReportAlert(post.id, post.userId);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.block),
                              onPressed: () {
                                showBlockAlert(post.userId, post.userName);
                              },
                            ),
                            if (post.userId == _auth.currentUser?.uid)
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDeleteAlert(post.id);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),

            if (postsByUser.isEmpty && nowPost == 'myTweet')
            Center(child: CircularProgressIndicator()),
            if (postsByUser.isNotEmpty && nowPost == 'myTweet')
            Expanded(child: //自分の投稿

            ListView.builder(
              itemCount: postsByUser.length,
              itemBuilder: (context, index) {
                PostWithLikes post = postsByUser[index];
                if (myBlockList.contains(post.userId)) {
                  return SizedBox.shrink(); // 空のウィジェットを返して非表示にする
                }
                return   Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("投稿主: ${post.userName}", style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111), fontFamily: 'makinas4'), ),
                            Text(formatTimestamp(post.timestamp), style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111))),
                          ],
                        ),
                        Row(
                          children: [
                            if (post.skillTypePost == "強化系")
                              SvgPicture.asset('Images/plus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "妨害系")
                              SvgPicture.asset('Images/minus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "特殊系")
                              SvgPicture.asset('Images/special.svg', width: screenWidth * 0.15),
                            SizedBox(width: 10,),
                            Text(post.skillName, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'makinas4', fontSize: screenWidth * 0.05)),
                          ],
                        ),
                        Text("スキルの説明: ${post.skillDetail}", style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline, fontSize: screenWidth * 0.04),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(post.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              onPressed: () {
                                likePost(post.id, post);
                                setState(() {
                                  post.usersWhoLiked.add(uid);
                                });
                              },
                            ),
                            Text("${post.likes}"),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.report),
                              onPressed: () {
                                showReportAlert(post.id, post.userId);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.block),
                              onPressed: () {
                                showBlockAlert(post.userId, post.userName);
                              },
                            ),
                            if (post.userId == _auth.currentUser?.uid)
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDeleteAlert(post.id);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),

            if (popularMonthPosts.isEmpty && nowPost == 'monthRanking')
            Center(child: CircularProgressIndicator()),
            if (popularMonthPosts.isNotEmpty && nowPost == 'monthRanking')
            Expanded(child: //自分の投稿

            ListView.builder(
              itemCount: popularMonthPosts.length,
              itemBuilder: (context, index) {
                PostWithLikes post = popularMonthPosts[index];
                if (myBlockList.contains(post.userId)) {
                  return SizedBox.shrink(); // 空のウィジェットを返して非表示にする
                }
                return   Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("投稿主: ${post.userName}", style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111), fontFamily: 'makinas4'), ),
                            Text(formatTimestamp(post.timestamp), style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111))),
                          ],
                        ),
                        Row(
                          children: [
                            if (post.skillTypePost == "強化系")
                              SvgPicture.asset('Images/plus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "妨害系")
                              SvgPicture.asset('Images/minus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "特殊系")
                              SvgPicture.asset('Images/special.svg', width: screenWidth * 0.15),
                            SizedBox(width: 10,),
                            Text(post.skillName, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'makinas4', fontSize: screenWidth * 0.05)),
                          ],
                        ),
                        Text("スキルの説明: ${post.skillDetail}", style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline, fontSize: screenWidth * 0.04),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(post.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              onPressed: () {
                                likePost(post.id, post);
                                setState(() {
                                  post.usersWhoLiked.add(uid);
                                });
                              },
                            ),
                            Text("${post.likes}"),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.report),
                              onPressed: () {
                                showReportAlert(post.id, post.userId);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.block),
                              onPressed: () {
                                showBlockAlert(post.userId, post.userName);
                              },
                            ),
                            if (post.userId == _auth.currentUser?.uid)
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDeleteAlert(post.id);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),

            if (popularWeekPosts.isEmpty && nowPost == 'weekRanking')
            Center(child: CircularProgressIndicator()),
            if (popularWeekPosts.isNotEmpty && nowPost == 'weekRanking')
            Expanded(child: //自分の投稿

            ListView.builder(
              itemCount: popularWeekPosts.length,
              itemBuilder: (context, index) {
                PostWithLikes post = popularWeekPosts[index];
                if (myBlockList.contains(post.userId)) {
                  return SizedBox.shrink(); // 空のウィジェットを返して非表示にする
                }
                return   Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("投稿主: ${post.userName}", style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111), fontFamily: 'makinas4'), ),
                            Text(formatTimestamp(post.timestamp), style: TextStyle(color: const Color.fromARGB(255, 111, 111, 111))),
                          ],
                        ),
                        Row(
                          children: [
                            if (post.skillTypePost == "強化系")
                              SvgPicture.asset('Images/plus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "妨害系")
                              SvgPicture.asset('Images/minus.svg', width: screenWidth * 0.15)
                            else if (post.skillTypePost == "特殊系")
                              SvgPicture.asset('Images/special.svg', width: screenWidth * 0.15),
                            SizedBox(width: 10,),
                            Text(post.skillName, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'makinas4', fontSize: screenWidth * 0.05)),
                          ],
                        ),
                        Text("スキルの説明: ${post.skillDetail}", style: TextStyle(fontFamily: 'makinas4', decoration: TextDecoration.underline, fontSize: screenWidth * 0.04),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(post.usersWhoLiked.contains(_auth.currentUser?.uid ?? '')
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              onPressed: () {
                                likePost(post.id, post);
                                setState(() {
                                  post.usersWhoLiked.add(uid);
                                });
                              },
                            ),
                            Text("${post.likes}"),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.report),
                              onPressed: () {
                                showReportAlert(post.id, post.userId);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.block),
                              onPressed: () {
                                showBlockAlert(post.userId, post.userName);
                              },
                            ),
                            if (post.userId == _auth.currentUser?.uid)
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDeleteAlert(post.id);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),

            if (nowPost != 'rule')
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // TimeLine アイコン
              GestureDetector(
                onTap: () {
                  setState(() {
                    nowPost = 'timeLine';
                    fetchLatestPostsWithLikes();
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: nowPost == 'timeLine' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(Icons.text_snippet, size: screenWidth * 0.13),
                ),
              ),
              // New Post アイコン
              GestureDetector(
                onTap: () {
                  setState(() {
                    nowPost = 'tweet';

                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: nowPost == 'tweet' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(Icons.add_box, size: screenWidth * 0.13),
                ),
              ),
              // My Likes アイコン
              GestureDetector(
                onTap: () {
                  setState(() {
                    nowPost = 'myLike';
                    fetchPostsLikedByUser(uid, (posts) {
                      if (posts != null) {
                        print("Fetched ${posts.length} liked posts:");
                        posts.forEach((post) {
                          print("Post ID: ${post.id}, Skill Name: ${post.skillName}");
                        });
                        setState(() {
                          likePosts = posts;
                        });
                      } else {
                        print("No posts found or an error occurred.");
                      }
                    });
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: nowPost == 'myLike' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(Icons.favorite, size: screenWidth * 0.13),
                ),
              ),
              // My Tweets アイコン
              GestureDetector(
                onTap: () {
                  setState(() {
                    nowPost = 'myTweet';
                    fetchPostsByUser(uid, (posts) {
                      if (posts != null) {
                        print("Fetched ${posts.length} posts by user:");
                        for (var post in posts) {
                          print("Post ID: ${post.id}, Skill Name: ${post.skillName}");
                        }
                        setState(() {
                          postsByUser = [];
                          postsByUser = posts;
                        });
                      } else {
                        print("No posts found or an error occurred.");
                      }
                    });
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: nowPost == 'myTweet' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(Icons.person, size: screenWidth * 0.13,)
                ),
              ),
            ],
          ),

          if (nowPost == 'rule')
          Expanded(
            child:
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "この利用規約（以下，「本規約」といいます。）は，心拳オンライン（以下，「当アプリ」といいます。）がこのウェブサイト上で提供するサービス（以下，「本サービス」といいます。）の利用条件を定めるものです。登録ユーザーの皆さま（以下，「ユーザー」といいます。）には，本規約に従って，本サービスをご利用いただきます。",
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "第一条(適用)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "1.本規約は，ユーザーと当アプリとの間の本サービスの利用に関わる一切の関係に適用されるものとします。",
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    "2.当アプリは本サービスに関し，本規約のほか，ご利用にあたってのルール等，各種の定め（以下，「個別規定」といいます。）をすることがあります。これら個別規定はその名称のいかんに関わらず，本規約の一部を構成するものとします。",
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    "3.本規約の規定が前条の個別規定の規定と矛盾する場合には，個別規定において特段の定めなき限り，個別規定の規定が優先されるものとします。",
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "第二条(ユーザーID及びパスワードの管理)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "1.ユーザーは，自己の責任において，本サービスのユーザーIDおよびパスワードを適切に管理するものとします。",
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    "2.ユーザーは，いかなる場合にも，ユーザーIDおよびパスワードを第三者に譲渡または貸与し，もしくは第三者と共用することはできません。当アプリは，ユーザーIDとパスワードの組み合わせが登録情報と一致してログインされた場合には，そのユーザーIDを登録しているユーザー自身による利用とみなします。",
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    "3.ユーザーID及びパスワードが第三者によって使用されたことによって生じた損害は，当アプリに故意又は重大な過失がある場合を除き，当アプリは一切の責任を負わないものとします。",
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "第三条(禁止事項)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("ユーザーは，本サービスの利用にあたり，以下の行為をしてはなりません。"),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("1. 法令または公序良俗に違反する行為"),
                        Text("2. 犯罪行為に関連する行為"),
                        Text("3. 当アプリ，本サービスの他のユーザー，または第三者のサーバーまたはネットワークの機能を破壊したり，妨害したりする行為"),
                        Text("4. 当アプリのサービスの運営を妨害するおそれのある行為"),
                        Text("5. 他のユーザーに関する個人情報等を収集または蓄積する行為"),
                        Text("6. 不正アクセスをし，またはこれを試みる行為"),
                        Text("7. 他のユーザーに成りすます行為"),
                        Text("8. 当アプリのサービスに関連して，反アプリ会的勢力に対して直接または間接に利益を供与する行為"),
                        Text("9. 当アプリ，本サービスの他のユーザーまたは第三者の知的財産権，肖像権，プライバシー，名誉その他の権利または利益を侵害する行為"),
                        Text("10. 以下の表現を含み，または含むと当アプリが判断する内容を本サービス上に投稿し，または送信する行為"),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("(1) 過度に暴力的な表現"),
                              Text("(2) 露骨な性的表現"),
                              Text("(3) 人種，国籍，信条，性別，アプリ会的身分，門地等による差別につながる表現"),
                              Text("(4) 自殺，自傷行為，薬物乱用を誘引または助長する表現"),
                              Text("(5) その他反アプリ会的な内容を含み他人に不快感を与える表現"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                "11. 以下を目的とし，または目的とすると当アプリが判断する行為",
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("(1) 営業，宣伝，広告，勧誘，その他営利を目的とする行為（当アプリの認めたものを除きます。）"),
                    Text("(2) 性行為やわいせつな行為を目的とする行為"),
                    Text("(3) 面識のない異性との出会いや交際を目的とする行為"),
                    Text("(4) 他のユーザーに対する嫌がらせや誹謗中傷を目的とする行為"),
                    Text("(5) 当アプリ，本サービスの他のユーザー，または第三者に不利益，損害または不快感を与えることを目的とする行為"),
                    Text("(6) その他本サービスが予定している利用目的と異なる目的で本サービスを利用する行為"),
                  ],
                ),
              ),
              Text("12. 宗教活動または宗教団体への勧誘行為"),
              Text("13. その他，当アプリが不適切と判断する行為"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "第四条（本サービスの提供の停止等)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text("1. 当アプリは，以下のいずれかの事由があると判断した場合，ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。"),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("(1) 本サービスにかかるコンピュータシステムの保守点検または更新を行う場合"),
                    Text("(2) 地震，落雷，火災，停電または天災などの不可抗力により，本サービスの提供が困難となった場合"),
                    Text("(3) コンピュータまたは通信回線等が事故により停止した場合"),
                    Text("(4) その他，当アプリが本サービスの提供が困難と判断した場合"),
                  ],
                ),
              ),
              Text("当アプリは，本サービスの提供の停止または中断により，ユーザーまたは第三者が被ったいかなる不利益または損害についても，一切の責任を負わないものとします。"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "第五条（著作権)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text("1. ユーザーは，自ら著作権等の必要な知的財産権を有するか，または必要な権利者の許諾を得た文章，画像や映像等の情報に関してのみ，本サービスを利用し，投稿ないしアップロードすることができるものとします。"),
              Text("2. ユーザーが本サービスを利用して投稿ないしアップロードした文章，画像，映像等の著作権については，当該ユーザーその他既存の権利者に留保されるものとします。ただし，当アプリは，本サービスを利用して投稿ないしアップロードされた文章，画像，映像等について，本サービスの改良，品質の向上，または不備の是正等ならびに本サービスの周知宣伝等に必要な範囲で利用できるものとし，ユーザーは，この利用に関して，著作者人格権を行使しないものとします。"),
              Text("3. 前項本文の定めるものを除き，本サービスおよび本サービスに関連する一切の情報についての著作権およびその他の知的財産権はすべて当アプリまたは当アプリにその利用を許諾した権利者に帰属し，ユーザーは無断で複製，譲渡，貸与，翻訳，改変，転載，公衆送信（送信可能化を含みます。），伝送，配布，出版，営業使用等をしてはならないものとします。"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "第六条（利用制限および登録抹消）",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text("1. 当アプリは，ユーザーが以下のいずれかに該当する場合には，事前の通知なく，投稿データを削除し，ユーザーに対して本サービスの全部もしくは一部の利用を制限しまたはユーザーとしての登録を抹消することができるものとします。"),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("(1) 本規約のいずれかの条項に違反した場合"),
                    Text("(2) 登録事項に虚偽の事実があることが判明した場合"),
                    Text("(3) 決済手段として当該ユーザーが届け出たクレジットカードが利用停止となった場合"),
                    Text("(4) 料金等の支払債務の不履行があった場合"),
                    Text("(5) 当アプリからの連絡に対し，一定期間返答がない場合"),
                    Text("(6) 本サービスについて，最終の利用から一定期間利用がない場合"),
                    Text("(7) その他，当アプリが本サービスの利用を適当でないと判断した場合"),
                  ],
                ),
              ),
              Text("3. 前項各号のいずれかに該当した場合，ユーザーは，当然に当アプリに対する一切の債務について期限の利益を失い，その時点において負担する一切の債務を直ちに一括して弁済しなければなりません。"),
              Text("4. 当アプリは，本条に基づき当アプリが行った行為によりユーザーに生じた損害について，一切の責任を負いません。"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "第七条（退会）",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text("ユーザーは，当アプリの定める退会手続により，本サービスから退会できるものとします。"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "第八条（保証の否認および免責事項）",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text("1. 当アプリは，本サービスに事実上または法律上の瑕疵（安全性，信頼性，正確性，完全性，有効性，特定の目的への適合性，セキュリティなどに関する欠陥，エラーやバグ，権利侵害などを含みます。）がないことを明示的にも黙示的にも保証しておりません。"),
              Text("2. 当アプリは，本サービスに起因してユーザーに生じたあらゆる損害について、当アプリの故意又は重過失による場合を除き、一切の責任を負いません。ただし，本サービスに関する当アプリとユーザーとの間の契約（本規約を含みます。）が消費者契約法に定める消費者契約となる場合，この免責規定は適用されません。"),
              Text("3.  前項ただし書に定める場合であっても，当アプリは，当アプリの過失（重過失を除きます。）による債務不履行または不法行為によりユーザーに生じた損害のうち特別な事情から生じた損害（当アプリまたはユーザーが損害発生につき予見し，または予見し得た場合を含みます。）について一切の責任を負いません。また，当アプリの過失（重過失を除きます。）による債務不履行または不法行為によりユーザーに生じた損害の賠償は，ユーザーから当該損害が発生した月に受領した利用料の額を上限とします。"),
              SizedBox(height: 8),
              Text("4.  当アプリは，本サービスに関して，ユーザーと他のユーザーまたは第三者との間において生じた取引，連絡または紛争等について一切責任を負いません。"),
              SizedBox(height: 16),
              Text("第九条（サービス内容の変更等）", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("当アプリは，ユーザーへの事前の告知をもって、本サービスの内容を変更、追加または廃止することがあり、ユーザーはこれを承諾するものとします。"),
              SizedBox(height: 16),
              Text("第十条（利用規約の変更）", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("1. 当アプリは以下の場合には、ユーザーの個別の同意を要せず、本規約を変更することができるものとします。"),
              SizedBox(height: 8),
              Text("2. 以下に該当する場合"),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("(1) 本規約の変更がユーザーの一般の利益に適合するとき。"),
                  Text("(2) 本規約の変更が本サービス利用契約の目的に反せず、かつ、変更の必要性、変更後の内容の相当性その他の変更に係る事情に照らして合理的なものであるとき。"),
                ],
              ),
              SizedBox(height: 8),
              Text("3. 当アプリはユーザーに対し、前項による本規約の変更にあたり、事前に、本規約を変更する旨及び変更後の本規約の内容並びにその効力発生時期を通知します。"),
              SizedBox(height: 16),
              Text("第十一条（個人情報の取扱い）", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("当アプリは，本サービスの利用によって取得する個人情報については，当アプリ「プライバシーポリシー」に従い適切に取り扱うものとします。"),
              SizedBox(height: 16),
              Text("第十二条（権利義務の譲渡の禁止）", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("ユーザーは，当アプリの書面による事前の承諾なく，利用契約上の地位または本規約に基づく権利もしくは義務を第三者に譲渡し，または担保に供することはできません。"),
              SizedBox(height: 16),
              Text("第十三条（準拠法・裁判管轄）", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("本規約の解釈にあたっては，日本法を準拠法とします。"),
              SizedBox(height: 16),
                  // Add more sections as per the given content in the same format.
                  CustomImageButton(screenWidth: screenWidth, buttonText: '同意する', onPressed: () {
                    setState(() {
                      nowPost = 'timeLine';
                      initBlockList();
                    });
                  })
                ],
              ),
            ),
          ),
          ),
          if (nowPost == 'rule')
          SizedBox(height: screenHeight * 0.1,)
          ],
        ),
      ),
    );
  }

  Future<void> fetchTopLikedPosts() async {
    topLikedPosts = [];
    try {
      final querySnapshot = await _firestore
          .collection('skillPosts')
          .orderBy('likes', descending: true)
          .limit(100)
          .get();

      List<PostWithLikes> topLikedPostsTemp = [];

      for (var document in querySnapshot.docs) {
        final data = document.data();
        final id = document.id;
        final userId = data['userId'] ?? '';
        final userName = data['userName'] ?? '';
        final skillName = data['skillName'] ?? '';
        final skillDetail = data['skillDetail'] ?? '';
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final likes = data['likes'] ?? 0;
        final skillTypePost = data['skillType'] ?? '強化系';

        final skillLikesDoc = await _firestore.collection('skillLikes').doc(id).get();
       final subData = skillLikesDoc.data();

        final likeCount = subData?['likeCount'] ?? 0;
        final usersWhoLiked = List<String>.from((subData?['usersWhoLiked'] as List).map((e) => e.toString()));

        topLikedPostsTemp.add(PostWithLikes(
          id: id,
          userId: userId as String,
          userName: userName as String,
          skillName: skillName as String,
          skillDetail: skillDetail as String,
          timestamp: timestamp,
          likes: likes as int,
          likeCount: likeCount as int,
          usersWhoLiked: usersWhoLiked,
          skillTypePost: skillTypePost  as String,
        ));
      }

      setState(() {
        topLikedPosts = topLikedPostsTemp;
      });

    } catch (e) {
      print('Error fetching top liked posts: $e');
      setState(() {
        topLikedPosts = [];
      });
    }

  }

  Future<void> fetchPostsLikedByUser(String userId, Function(List<PostWithLikes>?) completion) async {
    final db = FirebaseFirestore.instance;

    likePosts = [];

    try {
      // Fetch the liked post IDs from the user's document
      DocumentSnapshot userDocument = await db.collection("newUserData").doc(userId).get();

      if (!userDocument.exists || userDocument.data() == null) {
        print("No liked posts found");
        completion(null);
        return;
      }

      Map<String, dynamic>? userData = userDocument.data() as Map<String, dynamic>?;
      List<String> likedPosts = List<String>.from((userData?["likePosts"] as List).map((e) => e.toString()));

      List<PostWithLikes> postsWithLikes = [];
      List<Future> fetchFutures = [];

      for (String postId in likedPosts) {
        print("Fetching post with ID: $postId");

        fetchFutures.add(db.collection("skillPosts").doc(postId).get().then((postDocument) async {
          if (!postDocument.exists || postDocument.data() == null) {
            print("Post not found");
            return;
          }

          Map<String, dynamic>? postData = postDocument.data();
          String? userId = postData?["userId"] as String?;
          String? userName = postData?["userName"] as String?;
          String? skillName = postData?["skillName"] as String?;
          String? skillDetail = postData?["skillDetail"] as String?;
          Timestamp? timestamp = postData?["timestamp"] as Timestamp?;
          int likes = postData?["likes"] as int? ?? 0;
          String? skillTypePost = postData?["skillType"] as String?;

          if (userId == null ||
              userName == null ||
              skillName == null ||
              skillDetail == null ||
              timestamp == null ||
              skillTypePost == null) {
            print("Invalid post data");
            return;
          }

          // Fetch like details from skillLikes
          DocumentSnapshot likeDocument =
              await db.collection("skillLikes").doc(postId).get();

          Map<String, dynamic>? likeData = likeDocument.exists ? likeDocument.data() as Map<String, dynamic>? : null;
          int likeCount = likeData?["likeCount"] as int? ?? 0;
          List<String> usersWhoLiked = List<String>.from((likeData?["usersWhoLiked"] as List).map((e) => e.toString()));

          PostWithLikes postWithLikes = PostWithLikes(
            id: postId,
            userId: userId,
            userName: userName,
            skillName: skillName,
            skillDetail: skillDetail,
            timestamp: timestamp.toDate(),
            likes: likes,
            likeCount: likeCount,
            usersWhoLiked: usersWhoLiked,
            skillTypePost: skillTypePost,
          );

          postsWithLikes.add(postWithLikes);
        }));
      }

      await Future.wait(fetchFutures);
      completion(postsWithLikes);
    } catch (e) {
      print("Error fetching posts liked by user: $e");
      completion(null);
    }
  }

  Future<void> fetchPostsByUser(String userId, Function(List<PostWithLikes>?) completion) async {
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
      List<String> myPosts = List<String>.from((userData?["myPosts"] as List).map((e) => e.toString()));

      List<PostWithLikes> postsWithLikes = [];
      List<Future> fetchFutures = [];

      for (String postId in myPosts) {
        print("Fetching post with ID: $postId");

        fetchFutures.add(db.collection("skillPosts").doc(postId).get().then((postDocument) async {
          if (!postDocument.exists || postDocument.data() == null) {
            print("Post not found");
            return;
          }

          Map<String, dynamic>? postData = postDocument.data();
          String? postUserId = postData?["userId"] as String?;
          String? userName = postData?["userName"] as String?;
          String? skillName = postData?["skillName"] as String?;
          String? skillDetail = postData?["skillDetail"] as String?;
          Timestamp? timestamp = postData?["timestamp"] as Timestamp?;
          int likes = postData?["likes"] as int? ?? 0;
          String? skillTypePost = postData?["skillType"] as String?;

          if (postUserId == null ||
              userName == null ||
              skillName == null ||
              skillDetail == null ||
              timestamp == null ||
              skillTypePost == null) {
            print("Invalid post data");
            return;
          }

          // Fetch like details from skillLikes
          DocumentSnapshot likeDocument =
              await db.collection("skillLikes").doc(postId).get();

          Map<String, dynamic>? likeData = likeDocument.exists ? likeDocument.data() as Map<String, dynamic>? : null;
          int likeCount = likeData?["likeCount"] as int? ?? 0;
          List<String> usersWhoLiked = List<String>.from((likeData?["usersWhoLiked"] as List).map((e) => e.toString()));

          PostWithLikes postWithLikes = PostWithLikes(
            id: postId,
            userId: postUserId,
            userName: userName,
            skillName: skillName,
            skillDetail: skillDetail,
            timestamp: timestamp.toDate(),
            likes: likes,
            likeCount: likeCount,
            usersWhoLiked: usersWhoLiked,
            skillTypePost: skillTypePost,
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

  Future<void> fetchWeekPopularPosts(Function(List<PostWithLikes>) completion) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(Duration(days: 7));

    try {
      // Query Firestore for posts within the past week, ordered by likes
      QuerySnapshot querySnapshot = await db
          .collection("skillPosts")
          .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
          .orderBy("likes", descending: true)
          .limit(100)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No documents found");
        completion([]);
        return;
      }

      List<PostWithLikes> topLikedPostsTemp = [];
      List<Future> fetchFutures = [];

      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        String id = document.id;
        String userId = data["userId"] as String;
        String userName = data["userName"] as String;
        String skillName = data["skillName"] as String;
        String skillDetail = data["skillDetail"] as String;
        DateTime timestamp = (data["timestamp"] as Timestamp).toDate();
        int likes = data["likes"] as int;
        String skillTypePost = data["skillType"] as String;

        fetchFutures.add(db.collection("skillLikes").doc(id).get().then((subDocument) {
          if (!subDocument.exists) {
            print("No likes data for post ID: $id");
            return;
          }

          Map<String, dynamic>? subData = subDocument.data() as Map<String, dynamic>?;
          int likeCount = subData?["likeCount"] as int;
          List<String> usersWhoLiked = List<String>.from((subData?["usersWhoLiked"] as List).map((e) => e.toString()));

          PostWithLikes postWithLikes = PostWithLikes(
            id: id,
            userId: userId,
            userName: userName,
            skillName: skillName,
            skillDetail: skillDetail,
            timestamp: timestamp,
            likes: likes,
            likeCount: likeCount,
            usersWhoLiked: usersWhoLiked,
            skillTypePost: skillTypePost,
          );

          topLikedPostsTemp.add(postWithLikes);
        }));
      }

      // Wait for all like data to be fetched
      await Future.wait(fetchFutures);
      topLikedPostsTemp.sort((a, b) => b.likes.compareTo(a.likes)); // Sort by likes descending
      completion(topLikedPostsTemp);
    } catch (error) {
      print("Error fetching top liked posts: $error");
      completion([]);
    }
  }

  Future<void> fetchMonthPopularPosts(Function(List<PostWithLikes>) completion) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(Duration(days: 30)); // おおよその1か月前を計算

    try {
      // 過去1か月の投稿をいいね数でソートして取得
      QuerySnapshot querySnapshot = await db
          .collection("skillPosts")
          .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(oneMonthAgo))
          .orderBy("likes", descending: true)
          .limit(100)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No documents found");
        completion([]);
        return;
      }

      List<PostWithLikes> topLikedPostsTemp = [];
      List<Future> fetchFutures = [];

      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        String id = document.id;
        String userId = data["userId"] as String;
        String userName = data["userName"] as String;
        String skillName = data["skillName"] as String;
        String skillDetail = data["skillDetail"] as String;
        DateTime timestamp = (data["timestamp"] as Timestamp).toDate();
        int likes = data["likes"] as int;
        String skillTypePost = data["skillType"] as String;

        fetchFutures.add(db.collection("skillLikes").doc(id).get().then((subDocument) {
          if (!subDocument.exists) {
            print("No likes data for post ID: $id");
            return;
          }

          Map<String, dynamic>? subData = subDocument.data() as Map<String, dynamic>?;
          int likeCount = subData?["likeCount"] as int;
          List<String> usersWhoLiked = List<String>.from((subData?["usersWhoLiked"] as List).map((e) => e.toString()));

          PostWithLikes postWithLikes = PostWithLikes(
            id: id,
            userId: userId,
            userName: userName,
            skillName: skillName,
            skillDetail: skillDetail,
            timestamp: timestamp,
            likes: likes,
            likeCount: likeCount,
            usersWhoLiked: usersWhoLiked,
            skillTypePost: skillTypePost,
          );

          topLikedPostsTemp.add(postWithLikes);
        }));
      }

      // すべての非同期処理を完了するまで待機
      await Future.wait(fetchFutures);
      topLikedPostsTemp.sort((a, b) => b.likes.compareTo(a.likes)); // いいね数でソート
      completion(topLikedPostsTemp);
    } catch (error) {
      print("Error fetching top liked posts: $error");
      completion([]);
    }
  }

  Future<void> createPostWithLikes({
    required String userId,
    required String skillName,
    required String skillDetail,
    required String skillType,
    required String userName,
    required Function(bool) completion,
  }) async {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final postRef = db.collection("skillPosts").doc(); // 新規のpost用ドキュメント
    final likesRef = db.collection("skillLikes").doc(postRef.id); // `skillPosts`のIDを利用
    final usersRef = db.collection("newUserData").doc(auth.currentUser?.uid);

    final postData = {
      "userId": userId,
      "userName": userName,
      "skillName": skillName,
      "skillDetail": skillDetail,
      "timestamp": FieldValue.serverTimestamp(),
      "likes": 0,
      "skillType": skillType,
    };

    final likesData = {
      "likeCount": 0,
      "usersWhoLiked": [],
    };

    try {
      // バッチ書き込み
      WriteBatch batch = db.batch();
      batch.set(postRef, postData);
      batch.set(likesRef, likesData);
      await batch.commit();

      // ユーザーデータを更新
      DocumentSnapshot userSnapshot = await usersRef.get();
      if (userSnapshot.exists) {
        Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;
        List<dynamic> myPosts = userData?["myPosts"] as List<dynamic>;
        myPosts.add(postRef.id);

        await usersRef.set({"myPosts": myPosts}, SetOptions(merge: true));
      } else {
        // ユーザーデータが存在しない場合、新規作成
        await usersRef.set({"myPosts": [postRef.id]}, SetOptions(merge: true));
      }

      print("Documents added with ID: ${postRef.id}");
      completion(true);
    } catch (e) {
      print("Error adding documents: $e");
      completion(false);
    }
  }

  Future<void> fetchLatestPostsWithLikes({int limit = 20}) async {
  if (isLoading) return; // Prevent multiple simultaneous fetches
  timeLinePosts = [];
  setState(() {
    isLoading = true;
  });

  try {
    Query query = _firestore.collection('skillPosts')
        .orderBy('timestamp', descending: true) // 新しい順に並べる
        .limit(limit);

    if (timeLinePosts.isNotEmpty) {
      // 最初の投稿のタイムスタンプより新しいものを取得
      query = query.startAt([timeLinePosts.first.timestamp]);
    }

    // Fetch the posts
    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    List<PostWithLikes> latestPostsWithLikes = [];
      final List<Future> likeFutures = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        String userId = data['userId']  as String;
        String userName = data['userName']as String;
        String skillName = data['skillName'] as String;
        String skillDetail = data['skillDetail'] as String;
        Timestamp timestamp = data['timestamp'] as Timestamp;
        int likes = data['likes'] as int;
        String skillTypePost = data['skillType'] as String;
        String postId = doc.id;

        // Get the like information
        var likeFuture = _firestore.collection('skillLikes').doc(postId).get()
            .then((likeDoc) {
              if (likeDoc.exists) {
                var likeData = likeDoc.data() as Map<String, dynamic>;
                int likeCount = likeData['likeCount'] as int;
                List<String> usersWhoLiked = List<String>.from((likeData['usersWhoLiked'] as List).map((e) => e.toString()));


                var postWithLikes = PostWithLikes(
                  id: postId,
                  userId: userId,
                  userName: userName,
                  skillName: skillName,
                  skillDetail: skillDetail,
                  timestamp: timestamp.toDate(),
                  likes: likes,
                  likeCount: likeCount,
                  usersWhoLiked: usersWhoLiked,
                  skillTypePost: skillTypePost,
                );

                if (!timeLinePosts.any((post) => post.id == postId && post.timestamp == postWithLikes.timestamp)) {
                  latestPostsWithLikes.add(postWithLikes);
                }
              }
            });

        likeFutures.add(likeFuture);
      }

      // Wait for all like data to be fetched
      await Future.wait(likeFutures);

      // Update the posts with the fetched data
      setState(() {
        timeLinePosts.insertAll(0, latestPostsWithLikes); // 新しい投稿をリストの先頭に追加
        timeLinePosts.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 並べ替え
        isLoading = false;
      });

    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching latest posts: $error");
    }
  }

  Future<void> fetchOlderPostsWithLikes({int limit = 20}) async {
    if (isLoading) return;  // Prevent multiple simultaneous fetches
    setState(() {
      isLoading = true;
    });

    try {
      Query query = _firestore.collection('skillPosts')
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

      List<PostWithLikes> newPostsWithLikes = [];
      final List<Future> likeFutures = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        String userId = data['userId'] as String;
        String userName = data['userName'] as String;
        String skillName = data['skillName'] as String;
        String skillDetail = data['skillDetail'] as String;
        Timestamp timestamp = data['timestamp'] as Timestamp;
        int likes = data['likes'] as int;
        String skillTypePost = data['skillType'] as String;
        String postId = doc.id;

        // Get the like information
        var likeFuture = _firestore.collection('skillLikes').doc(postId).get()
            .then((likeDoc) {
              if (likeDoc.exists) {
                var likeData = likeDoc.data() as Map<String, dynamic>;
                int likeCount = likeData['likeCount'] as int;
                List<String> usersWhoLiked = List<String>.from((likeData['usersWhoLiked'] as List).map((e) => e.toString()));

                var postWithLikes = PostWithLikes(
                  id: postId,
                  userId: userId,
                  userName: userName,
                  skillName: skillName,
                  skillDetail: skillDetail,
                  timestamp: timestamp.toDate(),
                  likes: likes,
                  likeCount: likeCount,
                  usersWhoLiked: usersWhoLiked,
                  skillTypePost: skillTypePost,
                );

                if (!timeLinePosts.any((post) => post.id == postId && post.timestamp == postWithLikes.timestamp)) {
                  newPostsWithLikes.add(postWithLikes);
                }
              }
            });

        likeFutures.add(likeFuture);
      }

      // Wait for all like data to be fetched
      await Future.wait(likeFutures);

      // Update the posts with the fetched data
      setState(() {
        timeLinePosts.addAll(newPostsWithLikes); // 新しい投稿をリストの末尾に追加
        timeLinePosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  Future<void> deletePostWithLikes(String postId) async {
    try {
      final db = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      final userId = user.uid;
      final postRef = db.collection('skillPosts').doc(postId);
      final likesRef = db.collection('skillLikes').doc(postId);
      final usersRef = db.collection('userData').doc(userId);

      // バッチ書き込みで、複数の削除処理をまとめて実行
      WriteBatch batch = db.batch();

      batch.delete(postRef);
      batch.delete(likesRef);

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
        List<String> myPosts = List<String>.from((userData['myPosts'] as List).map((e) => e.toString()));

        // 投稿IDをユーザーの投稿リストから削除
        myPosts.remove(postId);

        // 更新された投稿IDリストをユーザー情報にセット
        await usersRef.set({
          'myPosts': myPosts,
        }, SetOptions(merge: true));

        print("User document updated");
      } else {
        print("User data is not in the expected format");
      }
    } catch (e) {
      print("Error deleting post: $e");
    }
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
                reportUser(userId); // ユーザーを通報する処理を実行
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

  Future<void> reportPost(String postId) async {
    try {
      // Firestoreのインスタンスを取得
      final db = FirebaseFirestore.instance;
      final reportRef = db.collection('tweetReport').doc(postId);

      // ドキュメントが存在するか確認
      final docSnapshot = await reportRef.get();

      if (docSnapshot.exists) {
        // ドキュメントが存在する場合、reportCountをインクリメント
        await reportRef.update({
          'reportCount': FieldValue.increment(1),
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

  Future<void> reportUser(String userId) async {
    try {
      // Firestoreのインスタンスを取得
      final db = FirebaseFirestore.instance;
      final reportRef = db.collection('userReport').doc(userId);

      // ドキュメントが存在するか確認
      final docSnapshot = await reportRef.get();

      if (docSnapshot.exists) {
        // ドキュメントが存在する場合、reportCountをインクリメント
        await reportRef.update({
          'reportCount': FieldValue.increment(1),
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
      print("Error reporting user: $e");
    }
  }

  Future<void> likePost(String postId, PostWithLikes postList) async {
    try {
      final db = FirebaseFirestore.instance;
      final postRef = db.collection('skillPosts').doc(postId);
      final likesRef = db.collection('skillLikes').doc(postId);
      final usersRef = db.collection('newUserData').doc(FirebaseAuth.instance.currentUser?.uid ?? '');
      print(FirebaseAuth.instance.currentUser?.uid);

      // トランザクションを使用して、複数のドキュメントを安全に更新
      await db.runTransaction((transaction) async {
        // skillLikesドキュメントを取得
        final likesSnapshot = await transaction.get(likesRef);
        if (!likesSnapshot.exists) {
          throw Exception("Likes document does not exist");
        }

        // userDataドキュメントを取得
        final userSnapshot = await transaction.get(usersRef);
        if (!userSnapshot.exists) {
          throw Exception("User document does not exist");
        }


        // `likePosts` フィールドの確認と初期化
        List<String> likePosts = List<String>.from(
          ((userSnapshot.data()?['likePosts']) as List).map((e) => e.toString()),
        );
        // skillLikesのデータを取得
        List<String> usersWhoLiked = List<String>.from((likesSnapshot.data()?['usersWhoLiked'] as List).map((e) => e.toString())) ?? [];
        var likeCount = likesSnapshot.data()?['likeCount'] ?? 0;
        // // 既に「いいね」している場合、処理を終了
        if (usersWhoLiked.contains(FirebaseAuth.instance.currentUser?.uid ?? '')) {
          print('いいね済み');
          return;
        }

        // // いいねを追加

        setState(() {
          usersWhoLiked.add(FirebaseAuth.instance.currentUser?.uid ?? '');
          likePosts.add(postId);
        });


        // 投稿の現在の「いいね」数を取得
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw Exception("Post document does not exist");
        }

        final currentLikes = postSnapshot.data()?['likes'] ?? 0;
        print('多分ここ');

        // トランザクションでデータを更新
        transaction.update(postRef, {'likes': currentLikes + 1});
        transaction.update(likesRef, {
          'likeCount': likeCount + 1,
          'usersWhoLiked': usersWhoLiked,
        });
        transaction.update(usersRef, {'likePosts': likePosts});
      });

      print("Transaction successfully committed!");
    } catch (e) {
      print("Error liking post: $e");
    }
  }

  void checkAndInitializeLikePosts() async {
    final db = FirebaseFirestore.instance;
    final usersRef = db.collection('newUserData').doc(FirebaseAuth.instance.currentUser?.uid ?? '');

    try {
      final userSnapshot = await usersRef.get();

      // ドキュメントが存在しない場合は何もしない
      if (!userSnapshot.exists) {
        print("User document does not exist");
        return;
      }

      // データを取得
      final userData = userSnapshot.data() as Map<String, dynamic>;

      // likePostsフィールドのデータを取得
      final likePostsData = userData['likePosts'];

      // likePostsが存在しないか、型がListでない場合、初期化
      if (likePostsData == null || likePostsData is! List) {
        await usersRef.update({'likePosts': []}); // Firestoreに空のリストをセット
        await usersRef.update({'myPosts': []}); // Firestoreに空のリストをセット
        print('likePosts field was initialized');
      }
    } catch (e) {
      print("Error checking or initializing likePosts: $e");
    }
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

class PostWithLikes {
  final String id;
  final String userId;
  final String userName;
  final String skillName;
  final String skillDetail;
  final DateTime timestamp;
  final int likes;
  final int likeCount;
  final List<String> usersWhoLiked;
  final String skillTypePost;

  PostWithLikes({
    required this.id,
    required this.userId,
    required this.userName,
    required this.skillName,
    required this.skillDetail,
    required this.timestamp,
    required this.likes,
    required this.likeCount,
    required this.usersWhoLiked,
    required this.skillTypePost,
  });

  // ハッシュコードと等価性をサポート
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostWithLikes &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PostWithLikes{id: $id, userId: $userId, userName: $userName, skillName: $skillName, skillDetail: $skillDetail, timestamp: $timestamp, likes: $likes, likeCount: $likeCount, usersWhoLiked: $usersWhoLiked, skillTypePost: $skillTypePost}';
  }
}
