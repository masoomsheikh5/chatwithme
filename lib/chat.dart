import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/store/actions.dart' as action;
import 'main.dart';

class Chat extends StatefulWidget {
  final String? chatId;
  final String? emailId;
  final String? fcmToken;
  final String? nameId;
  final Uint8List chatPic;
  Chat(
      {Key? key,
      required this.fcmToken,
      required this.nameId,
      required this.chatId,
      required this.chatPic,
      required this.emailId})
      : super(key: key);
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late DatabaseReference _messagesRef;
  late DatabaseReference _lastMessagesRef;
  late DatabaseReference _messagesRef2;
  late DatabaseReference _lastMessagesRef2;
  late StreamSubscription<Event> _messagesSubscription;
  String mainTime = "";
  String dayTime = "";
  List _chats = [];

  bool _anchorToBottom = false;
  ScrollController _controller = ScrollController();

  final TextEditingController _textController = TextEditingController();
  String lkId =
      store.state.emailModel!.email.toString().replaceAll("@gmail.com", "");
  // String? _pic = widget.chatPic;

  @override
  void initState() {
    super.initState();
    print(["ChaterId", widget.emailId]);
    print(["Myid", lkId]);
    _messagesRef = database
        .reference()
        .child('users')
        .child(store.state.emailModel!.localId.toString())
        .child('messages')
        .child(widget.chatId.toString())
        .child('messages');
    //last msg mine
    _lastMessagesRef = database
        .reference()
        .child('users')
        .child(store.state.emailModel!.localId.toString())
        .child('messages')
        .child(widget.chatId.toString())
        .child('lastMsged');
    _messagesRef2 = database
        .reference()
        .child('users')
        .child(widget.chatId.toString())
        .child('messages')
        .child(store.state.emailModel!.localId.toString())
        .child('messages');
    //last msg other
    _lastMessagesRef2 = database
        .reference()
        .child('users')
        .child(widget.chatId.toString())
        .child('messages')
        .child(store.state.emailModel!.localId.toString())
        .child('lastMsged');
    database.setLoggingEnabled(true);

    if (!kIsWeb) {
      database.setPersistenceEnabled(true);
      database.setPersistenceCacheSizeBytes(10000000);
    }

    _messagesSubscription =
        _messagesRef.limitToLast(20).onChildAdded.listen((Event event) {
      print('Child added hello: ${event.snapshot.value}');
      // setState(() {
      _chats.add(event.snapshot.value);
      // });
      setState(() {
        takeToBottom();
      });
    }, onError: (Object o) {
      final DatabaseError error = o as DatabaseError;
      print('Error: ${error.code} ${error.message}');
    });
  }

  @override
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
  }

  Future<void> _sendMSG() async {
    await _lastMessagesRef.set(<String, String>{
      "lastMsg": "${_textController.text.trim()}",
      "time": "${DateTime.now()}",
    });
    await _lastMessagesRef2.set(<String, String>{
      "lastMsg": "${_textController.text.trim()}",
      "time": "${DateTime.now()}",
    });

    await _messagesRef.push().set(<String, Map>{
      lkId: {
        "message": "${_textController.text.trim()}",
        "time": "${DateTime.now()}",
      },
    });
    await _messagesRef2.push().set(<String, Map>{
      lkId: {
        "message": "${_textController.text.trim()}",
        "time": "${DateTime.now()}",
      },
    });

    _textController.clear();
    // FocusManager.instance.primaryFocus!.unfocus();
    takeToBottom();
  }

  takeToBottom() {
    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      print("calling ${_controller.position.maxScrollExtent}");

      await _controller.animateTo(
        _controller.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Uint8List bytes = Base64Codec().decode(widget.chatPic);
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          Icon(Icons.video_call),
          SizedBox(
            width: 10,
          ),
          Icon(Icons.phone),
          SizedBox(
            width: 10,
          ),
          Icon(Icons.more_vert)
        ],
        backgroundColor: Color(0xff31705e),
        leadingWidth: 70,
        leading: Container(
          child: Row(
            children: [
              InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  )),
              CircleAvatar(
                backgroundImage: MemoryImage(widget.chatPic),
              ),
            ],
          ),
        ),
        title: Text(widget.nameId.toString()),
        // centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/background.jpg"), fit: BoxFit.fill)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 8 / 10,
                // padding: const EdgeInsets.only(bottom: 30, top: 20),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FirebaseAnimatedList(
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        controller: _controller,
                        key: ValueKey<bool>(false),
                        // reverse: true,
                        shrinkWrap: true,
                        query: _messagesRef,
                        itemBuilder: (BuildContext context,
                            DataSnapshot snapshot,
                            Animation<double> animation,
                            int index) {
                          // print(["snapshot.value['aaryan']", snapshot.value]);
                          DateTime time = snapshot.value[lkId] == null
                              ? DateTime.parse(snapshot.value[widget.emailId]
                                      ['time']
                                  .toString())
                              : DateTime.parse(
                                  snapshot.value[lkId]['time'].toString());
                          String date = "${DateFormat('hh:mm a').format(time)}";

                          ///timeday
                          DateTime now = DateTime.now();
                          DateTime yesterday = now.subtract(Duration(days: 1));
                          DateTime justNow =
                              DateTime.now().subtract(Duration(minutes: 1));

                          String time2;

                          if (time.day == now.day &&
                              time.month == now.month &&
                              time.year == now.year) {
                            time2 = "Today";
                            // "${DateFormat('hh:mm a').format(time)}";
                          } else if (time.day == yesterday.day &&
                              time.month == yesterday.month &&
                              time.year == yesterday.year) {
                            time2 = "Yesterday";
                          } else {
                            time2 = '${DateFormat('yMd').format(time)}';
                          }

                          if (mainTime != time2) {
                            mainTime = time2;
                            dayTime = time2;
                          } else if (mainTime == time2) {
                            dayTime = "";
                          }

                          return SizeTransition(
                            sizeFactor: animation,
                            child: InkWell(
                              onLongPress: () =>
                                  _messagesRef.child(snapshot.key!).remove(),
                              child: Column(
                                  verticalDirection: VerticalDirection.up,
                                  children: [
                                    !snapshot.value.containsKey(
                                            widget.emailId.toString())
                                        ? Column(
                                            children: [
                                              dayTime == ""
                                                  ? SizedBox()
                                                  : Card(
                                                      child: Container(
                                                      margin:
                                                          EdgeInsets.all(10),
                                                      child: Text(
                                                        dayTime,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    )),
                                              // Row(
                                              //   mainAxisAlignment:MainAxisAlignment.center,

                                              // ),
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Card(
                                                      color: Color(0xffdcf8c6),
                                                      child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 6),
                                                          margin:
                                                              EdgeInsets.only(
                                                                  right: 20),
                                                          child: Column(
                                                            // mainAxisAlignment:
                                                            //     MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                "${snapshot.value[lkId]['message']}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                            ],
                                                          )),
                                                    ),
                                                    Text(
                                                      date,
                                                      style: TextStyle(
                                                          fontSize: 10),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              dayTime == ""
                                                  ? SizedBox()
                                                  : Card(
                                                      child: Container(
                                                      margin: EdgeInsets.all(8),
                                                      child: Text(
                                                        dayTime,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    )),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Card(
                                                      child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 6),
                                                          margin:
                                                              EdgeInsets.only(
                                                                  right: 20),
                                                          child: Column(
                                                            // mainAxisAlignment:
                                                            //     MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                "${snapshot.value[widget.emailId]['message']}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                            ],
                                                          )),
                                                    ),
                                                    Text(
                                                      date,
                                                      style: TextStyle(
                                                          fontSize: 10),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                  ]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              sushuisa(context),
            ],
          ),
        ),
      ),
    ));
  }

  sushuisa(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8 / 10,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30))),
            width: MediaQuery.of(context).size.width * 8 / 10,
            child: TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                // fillColor: Colors.white,
                focusColor: Colors.white,

                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                hintText: "write message",
              ),
              validator: (e) {
                if (e!.isEmpty) {
                  return "";
                }
              },
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 2 / 10,
            child: CircleAvatar(
              backgroundColor: Color(0xff31705e),
              radius: 25,
              child: IconButton(
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    String? usernameId = prefs.getString('usernameId');
                    store.dispatch(action.msgnoti(
                        widget.fcmToken, usernameId, _textController.text));
                    _sendMSG();
                  },
                  icon: Icon(
                    Icons.send,
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar() {
    return Container(
      color: Color(0xff00bfa5),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.7 / 10,
      child: Row(
        children: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.chevron_left,
                color: Colors.white,
              )),
          CircleAvatar(
            backgroundImage: NetworkImage(
                "https://www.inpixio.com/wp-content/uploads/2019/11/4B-Edit-Colors-before.jpg"),
          ),
          SizedBox(
            width: 30,
          ),
          Text(
            lkId,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(
            width: 60,
          ),
          Icon(
            Icons.video_call,
            size: 35,
            color: Colors.white,
          ),
          SizedBox(
            width: 10,
          ),
          Icon(
            Icons.phone,
            size: 28,
            color: Colors.white,
          ),
          SizedBox(
            width: 10,
          ),
          Icon(
            Icons.more_vert,
            size: 28,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
