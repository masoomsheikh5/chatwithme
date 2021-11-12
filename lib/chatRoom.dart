// ignore_for_file: file_names, prefer_const_constructors_in_immutables

import 'dart:async';

import 'package:chatwithme/chat.dart';
import 'package:chatwithme/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'store/actions.dart';

class Chatroom extends StatefulWidget {
  Chatroom({Key? key}) : super(key: key);

  @override
  _ChatroomState createState() => _ChatroomState();
}

class _ChatroomState extends State<Chatroom> {
  final FirebaseDatabase database = FirebaseDatabase();
  late DatabaseReference _users;
  late StreamSubscription<Event> _userSubscription;
  List _userlist = [];

  @override
  void initState() {
    super.initState();
    _users = database.reference().child('users');
    if (!kIsWeb) {
      database.setPersistenceEnabled(true);
      database.setPersistenceCacheSizeBytes(10000000);
    }
    _userSubscription =
        _users.limitToLast(20).onChildAdded.listen((Event event) {
      _userlist.add(event.snapshot.value);
    });
    print(["list", _userlist]);
  }

  @override
  void dispose() {
    super.dispose();
    _userSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_work),
            label: "Channels",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_box,
            ),
            label: "Profile",
          ),
        ],
      ),
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              // ElevatedButton(
              // onPressed: () {
              //   store.dispatch(logout(context));
              // },
              // child: Text("logOut")),
              FirebaseAnimatedList(
                query: _users,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (BuildContext context, DataSnapshot snapshot,
                    Animation<double> animation, int index) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: snapshot.value['userData']['email'].toString() ==
                            store.state.emailModel!.email.toString()
                        ? SizedBox(
                            width: 0,
                            height: 0,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => Chat(
                                              chatId:
                                                  "${snapshot.value['userData']['localId']}",
                                              emailId:
                                                  '${snapshot.value['userData']['email']}'
                                                      .toString()
                                                      .replaceAll(
                                                          "@gmail.com", ""),
                                              fcmToken:
                                                  "${snapshot.value['fcmToken']['fcmToken']}",
                                            )));
                              },
                              child: Container(
                                color: Colors.amber[100],
                                child: Column(
                                  children: [
                                    ListTile(
                                        title: Text(
                                      '${snapshot.value['userData']['email']}',
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
