import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screen/LoadingScreen.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NameInputScreen extends StatelessWidget {
  int skillNumber = 50;

  Future<dynamic> getFieldFromFirebase({
  required String collection,
  required String document,
  required String field,      // 読み取るフィールド名
  }) async {
    try {
      // Firebaseのドキュメント参照
      DocumentReference docRef =
          FirebaseFirestore.instance.collection(collection).doc(document);

      // ドキュメントを取得
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // フィールドの値を取得して返す
        return docSnapshot.get(field);
      } else {
        print("Document does not exist.");
        return null;
      }
    } catch (e) {
      print("Error reading field from Firebase: $e");
      return null;
    }
  }

  Future<void> updateFieldsInFirebase({
    required Map<String, dynamic> fieldsToUpdate, // 更新するフィールドとその値
    required String collection,
    required String document
  }) async {
    try {
      // Firebaseのドキュメント参照
      final DocumentReference docRef = FirebaseFirestore.instance.collection(collection).doc(document);

      // ドキュメントの存在を確認
      final DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // ドキュメントが存在する場合は更新
        await docRef.update(fieldsToUpdate);
        print("Fields updated successfully in Firebase.");
      } else {
        // ドキュメントが存在しない場合は作成しつつデータを設定
        await docRef.set(fieldsToUpdate);
        print("Document created and fields set successfully in Firebase.");
      }
    } catch (e) {
      print("Error updating fields in Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.7; // ボタンの幅
    final double buttonHeight = screenSize.height * 0.1;  // ボタンの高さ

    final TextEditingController _nameController = TextEditingController();
    void setMyInfo() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('myName', _nameController.text);
      await updateFieldsInFirebase(collection: 'newUserData', document: uid,
        fieldsToUpdate: {
          'name': _nameController.text,
          'id': prefs.getString('myFriendId'),
          'uid': uid,
          'rank': prefs.getString('myRank'),
          'rankCount': prefs.getInt('myRankCount'),
          'skillList': prefs.getStringList('myOwnSkillList'),
          'rockCount': prefs.getInt('myRockCount'),
          'scissorCount': prefs.getInt('myScissorCount'),
          'paperCount': prefs.getInt('myPaperCount'),
          'battleCount': prefs.getInt('myBattleCount'),
          'winCount': prefs.getInt('myWinCount'),
          'winStreak': prefs.getInt('myWinStreak'),
          'honestCount': prefs.getInt('myHonestCount'),
          'gachaPoint': prefs.getInt('myGachaPoint'),
          'level': prefs.getInt('myLevel'),
          'exp': prefs.getInt('myLevelExp'),
          'trophy': prefs.getInt('myTrophy'),
          'skillUseCount': List.filled(skillNumber, 0),
          'skillActiveCount': List.filled(skillNumber, 0),
        },
      );
    }

   void _checkNameAndId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = _nameController.text;
    String? id = prefs.getString('myFriendId');
    bool numberCheck = false;

    // 名前の長さをチェック
    if (name.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("名前は10文字以内にしてください"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    } else {
      numberCheck = true;
      print("Valid name: $name");
    }

    if (numberCheck) {
      try {
        String nameKey = name[0]; // 名前の頭文字
        String idKey = (id ?? '')[0]; // IDの頭文字

        // Firestore のドキュメント参照
        final DocumentReference nameDocRef =
            FirebaseFirestore.instance.collection('newUserNameID').doc('name');
        final DocumentReference idDocRef =
            FirebaseFirestore.instance.collection('newUserNameID').doc('id');

        // 名前チェック
        DocumentSnapshot nameDoc = await nameDocRef.get();
        List<String> nameList = [];

        if (nameDoc.exists) {
          Map<String, dynamic>? data = nameDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey(nameKey)) {
            nameList = List<String>.from((data[nameKey] as List).map((e) => e.toString()));
          }
        }

        // IDチェック
        DocumentSnapshot idDoc = await idDocRef.get();
        List<String> idList = [];

        if (idDoc.exists) {
          Map<String, dynamic>? data = idDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey(idKey)) {
            idList = List<String>.from((data[idKey] as List).map((e) => e.toString()));
          }
        }

        // 重複チェック
        bool nameExists = nameList.contains(name);
        bool idExists = idList.contains(id);

        if (nameExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('名前 "$name" は既に存在します。')),
          );
          return;
        }

        if (idExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ID "$id" は既に存在します。')),
          );
          return;
        }

        // 重複がない場合にデータを更新
        if (!nameExists && !idExists) {
          // 名前とIDをそれぞれのリストに追加
          nameList.add(name);
          idList.add(id!);

          // データを更新
          await nameDocRef.set(
            {nameKey: nameList},
            SetOptions(merge: true),
          );
          await idDocRef.set(
            {idKey: idList},
            SetOptions(merge: true),
          );

          setMyInfo();
          context.go('/tutorialBattle');
        }
      } catch (e) {
        print('エラー: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }




    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ElevatedButton(
          //   onPressed: () {
          //     context.go('/load');
          //   },
          //   child: Text("戻ってログイン状態を更新"),
          // ),
          // SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'バトルで使われる名前を決めてください',
              border: OutlineInputBorder(),
            ),
          ),
          Text('名前は10文字以内です。'),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _checkNameAndId,
            child: Text('登録'),
          ),
        ],
      ),
    );
  }
}