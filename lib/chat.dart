import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class Chat extends StatefulWidget {
  Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late DatabaseReference _counterRef;
  late DatabaseReference _messagesRef;
  late StreamSubscription<Event> _counterSubscription;
  late StreamSubscription<Event> _messagesSubscription;
  String _kTestKey = 'Hello';
  String _kTestValue = 'world!';
  DatabaseError? _error;
  int _counter = 0;
  List _chats = [];
  bool _anchorToBottom = false;
  ScrollController _controller = ScrollController();

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Demonstrates configuring to the database using a file
    _counterRef = FirebaseDatabase.instance.reference().child('counter');
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = FirebaseDatabase();
    _messagesRef = database.reference().child('messages');
    database.reference().child('counter').get().then((DataSnapshot? snapshot) {
      print(
          'Connected to directly configured database and read ${snapshot!.value}');
    });

    database.setLoggingEnabled(true);

    if (!kIsWeb) {
      database.setPersistenceEnabled(true);
      database.setPersistenceCacheSizeBytes(10000000);
      _counterRef.keepSynced(true);
    }
    _counterSubscription = _counterRef.onValue.listen((Event event) {
      setState(() {
        _error = null;
        _counter = event.snapshot.value ?? 0;
      });
    }, onError: (Object o) {
      final DatabaseError error = o as DatabaseError;
      setState(() {
        _error = error;
      });
    });
    _messagesSubscription =
        _messagesRef.limitToLast(20).onChildAdded.listen((Event event) {
      print('Child added: ${event.snapshot.value}');
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
    _counterSubscription.cancel();
  }

  Future<void> _sendMSG() async {
    await _counterRef.set(ServerValue.increment(1));

    await _messagesRef.push().set(<String, Map>{
      "masoom": {
        "message": "${_textController.text.trim()}",
        "time": "${DateTime.now()}",
      },
    });
    _textController.clear();
    // FocusManager.instance.primaryFocus!.unfocus();
    takeToBottom();
  }

  Future<void> _incrementAsTransaction() async {
    // Increment counter in transaction.
    final TransactionResult transactionResult =
        await _counterRef.runTransaction((MutableData mutableData) {
      mutableData.value = (mutableData.value ?? 0) + 1;
      return mutableData;
    });

    if (transactionResult.committed) {
      await _messagesRef.push().set(<String, String>{
        _kTestKey: '$_kTestValue ${transactionResult.dataSnapshot?.value}'
      });
    } else {
      print('Transaction not committed.');
      if (transactionResult.error != null) {
        print(transactionResult.error!.message);
      }
    }
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
        backgroundColor: Color(0xff00bfa5),
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
                backgroundImage: NetworkImage(
                    "https://www.inpixio.com/wp-content/uploads/2019/11/4B-Edit-Colors-before.jpg"),
              ),
            ],
          ),
        ),
        title: Text("WhatsApp"),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FirebaseAnimatedList(
                      controller: _controller,
                      key: ValueKey<bool>(false),
                      // reverse: true,
                      shrinkWrap: true,
                      query: _messagesRef,
                      itemBuilder: (BuildContext context, DataSnapshot snapshot,
                          Animation<double> animation, int index) {
                        print(["snapshot.value['masoom']", snapshot.value]);
                        DateTime time = snapshot.value['aaryan'] == null
                            ? DateTime.now()
                            : DateTime.parse(
                                snapshot.value['masoom']['time'].toString());
                        String date = "${DateFormat('hh:mm a').format(time)}";
                        // DateTime time = snapshot.value['aaryan'] == null
                        //     ? DateTime.now()
                        //     : DateTime.parse(
                        //         snapshot.value['masoom']['time'].toString());
                        // String date = "${DateFormat('hh:mm a').format(time)}";
                        return SizeTransition(
                          sizeFactor: animation,
                          child: InkWell(
                            onLongPress: () =>
                                _messagesRef.child(snapshot.key!).remove(),
                            child: Column(
                                verticalDirection: VerticalDirection.up,
                                children: [
                                  !snapshot.value.containsKey("aaryan")
                                      ? Align(
                                          alignment: Alignment.topRight,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Card(
                                                child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 6),
                                                    margin: EdgeInsets.only(
                                                        right: 20),
                                                    child: Column(
                                                      // mainAxisAlignment:
                                                      //     MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          "${snapshot.value['masoom']['message']}",
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                        ),
                                                      ],
                                                    )),
                                              ),
                                              // Text(
                                              //   date,
                                              //   style: TextStyle(fontSize: 10),
                                              // )
                                            ],
                                          ),
                                        )
                                      : Align(
                                          alignment: Alignment.topLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Card(
                                                child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 6),
                                                    margin: EdgeInsets.only(
                                                        right: 20),
                                                    child: Column(
                                                      // mainAxisAlignment:
                                                      //     MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          "${snapshot.value['aaryan']['message']}",
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                        ),
                                                      ],
                                                    )),
                                              ),
                                              Text(
                                                snapshot.value['aaryan']
                                                    ['time'],
                                                style: TextStyle(fontSize: 10),
                                              )
                                            ],
                                          ),
                                          // Card(
                                          //   child: Container(
                                          //       padding: EdgeInsets.symmetric(
                                          //           horizontal: 20, vertical: 6),
                                          //       margin: EdgeInsets.only(
                                          //           right: 20, left: 20),
                                          //       // color: Colors.red,

                                          //       child: Text(
                                          //         "${snapshot.value['aarya']}",
                                          //         style: TextStyle(fontSize: 20),
                                          //       )),
                                          // )
                                        )
                                ]),
                          ),
                        );
                      },
                    ),
                  ],
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
              backgroundColor: Color(0xff00bfa5),
              radius: 25,
              child: IconButton(
                  onPressed: () {
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
            "masoom",
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
