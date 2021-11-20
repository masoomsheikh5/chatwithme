// ignore_for_file: file_names, prefer_const_constructors_in_immutables

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chatwithme/chat.dart';
import 'package:chatwithme/main.dart';
import 'package:chatwithme/profilepic.dart';
import 'package:chatwithme/username.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store/actions.dart';

class Chatroom extends StatefulWidget {
  Chatroom({Key? key}) : super(key: key);

  @override
  _ChatroomState createState() => _ChatroomState();
}

class _ChatroomState extends State<Chatroom> {
  late DatabaseReference _profilePicPush;
  File? _image;

  final picker = ImagePicker();
  bool _isCamera = false;
  String? _imageBase64;
  final FirebaseDatabase database = FirebaseDatabase();
  late DatabaseReference _users;
  late StreamSubscription<Event> _userSubscription;
  List _userlist = [];
  var userName;

  ////notification setup

  late final FirebaseMessaging _messaging;
  late int _totalNotifications;
  PushNotification? _notificationInfo;

  void registerNotification() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    _messaging.getToken().then((token) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("fcmToken", token.toString());
      print(["fcmToken", token]); // Print the Token in Console
    });

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
            'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');

        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );

        setState(() {
          _notificationInfo = notification;
          _totalNotifications++;
        });

        if (_notificationInfo != null) {
          // For displaying the notification as an overlay
          showSimpleNotification(
            Text(_notificationInfo!.title!),
            leading: NotificationBadge(totalNotifications: _totalNotifications),
            subtitle: Text(_notificationInfo!.body!),
            background: Colors.cyan.shade700,
            duration: Duration(seconds: 2),
          );
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
        dataTitle: initialMessage.data['title'],
        dataBody: initialMessage.data['body'],
      );

      setState(() {
        _notificationInfo = notification;
        _totalNotifications++;
      });
    }
  }

  var lkid = store.state.emailModel!.localId.toString();
  //  _sendPic() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? usernameId = prefs.getString('usernameId');
  //   _profilePicPush = database
  //       .reference()
  //       .child('users')
  //       .child(store.state.emailModel!.localId.toString())
  //       .child('userProfile');
  //   _profilePicPush.push().set(<Map>{b
  //     {
  //       "name": usernameId,
  //       "profilePic": _imageBase64,
  //     },
  //   });
  // }

  @override
  void initState() {
    _totalNotifications = 0;
    registerNotification();
    checkForInitialMessage();

    // For handling notification when the app is in background
    // but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        dataTitle: message.data['title'],
        dataBody: message.data['body'],
      );

      setState(() {
        _notificationInfo = notification;
        _totalNotifications++;
      });
    });

    super.initState();
    final FirebaseDatabase database = FirebaseDatabase();

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

  Future<void> _deleteCacheDir() async {
    Directory tempDir = await getTemporaryDirectory();

    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    print("_deleteCacheDir is runing");
  }

  Future<void> _deleteAppDir() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    if (appDocDir.existsSync()) {
      appDocDir.deleteSync(recursive: true);
    }
    print("_deleteAppDir is runing");
  }

  Future getImage() async {
    Navigator.pop(context);
    _isCamera
        ? await Permission.camera.request()
        : await Permission.photos.request();
    var status = _isCamera
        ? await Permission.camera.status
        : await Permission.photos.status;
    print(status);
    if (status.isGranted || status.isLimited) {
      final pickedFile = await picker.pickImage(
        source: _isCamera ? ImageSource.camera : ImageSource.gallery,
        // imageQuality: 50,
        // maxHeight: 200,
        // maxWidth: 200
      );
      List<int> imageBytes = await pickedFile!.readAsBytes();
      // print(imageBytes);
      String base64Image = base64Encode(imageBytes);
      // print(["baaassseee pohoto", base64Image]);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var usernameId = prefs.getString('usernameId');
      setState(() {
        _image = File(pickedFile.path);
        _imageBase64 = base64Image;
        var username = <String, String>{
          "name": usernameId.toString(),
          "profilePic": _imageBase64.toString(),
        };
        database
            .reference()
            .child('users')
            .child(store.state.emailModel!.localId.toString())
            .child('userProfile')
            .set(username);
      });
    }
  }

  _showBottomSheetModal() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: new Icon(Icons.photo),
                title: new Text('Gallery'),
                onTap: () {
                  setState(() {
                    _isCamera = false;
                  });
                  getImage();
                },
              ),
              ListTile(
                leading: new Icon(Icons.camera),
                title: new Text('Camera'),
                onTap: () {
                  setState(() {
                    _isCamera = true;
                  });
                  getImage();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xff31705e),
        selectedItemColor: Color(0xff96e0cb),
        unselectedItemColor: Colors.white,
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
            label: "Status",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
            ),
            label: "Search",
          ),
        ],
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Container(
            // height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            // color: Colors.amber,
            child: Column(
              children: [
                // Container(
                //   height: MediaQuery.of(context).size.height,
                //   width: MediaQuery.of(context).size.height,
                // ),
                FirebaseAnimatedList(
                    query: _users,
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, DataSnapshot snapshot,
                        Animation<double> animation, int index) {
                      var _pic = snapshot.value['userProfile']['profilePic']
                          .toString();
                      Uint8List bytes = Base64Codec().decode(_pic);
                      return Container(
                        child: snapshot.value['userData']['email'].toString() ==
                                store.state.emailModel!.email.toString()
                            ? Container(
                                height: 280,
                                width: MediaQuery.of(context).size.width,
                                color: Color(0xff31705e),
                                child: Container(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      selectPhoto(context, snapshot, bytes),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Container(
                                        child: Text(
                                            "${snapshot.value['userProfile']['name']}"),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: 0,
                                height: 0,
                              ),
                      );
                    }),

                // Divider(
                //   color: Colors.black,
                //   thickness: 18,
                // // ),
                // ElevatedButton(
                //     onPressed: () async {
                //       if (_imageBase64 != null) {
                //         // _profilePicPush = database
                //         //     .reference()
                //         //     .child('users')
                //         //     .child(store.state.emailModel!.localId.toString())
                //         //     .child('userProfile').s;
                //         SharedPreferences prefs =
                //             await SharedPreferences.getInstance();
                //         var usernameId = prefs.getString('usernameId');

                //         var username = <String, String>{
                //           "name": usernameId.toString(),
                //           "profilePic": _imageBase64.toString(),
                //         };
                //         database
                //             .reference()
                //             .child('users')
                //             .child(store.state.emailModel!.localId.toString())
                //             .child('userProfile')
                //             .set(username);
                //       }
                //       ;
                //     },
                //     child: Text("upload")),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.account_box,
                      size: 35,
                    ),
                    title: Text("Profile"),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text("Setting"),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.storage),
                    title: Text("Stroge"),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.group_add),
                    title: Text("New Group"),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text("Download setting"),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
                // Divider(
                //   color: Colors.black,
                // )
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        // shape: CircleBorder(side: BorderSide(width: 1.0)),
                        ),
                    onPressed: () async {
                      _deleteCacheDir();
                      _deleteAppDir();
                      store.dispatch(logout(context));
                    },
                    child: Text("logOut")),
              ],
            ),
          ),
        ),
        // child: ElevatedButton(
        //     style: ElevatedButton.styleFrom(
        //       shape: CircleBorder(side: BorderSide(width: 1.0)),
        //     ),
        //     onPressed: () async {
        //       _deleteCacheDir();
        //       _deleteAppDir();
        //       store.dispatch(logout(context));
        //     },
        //     child: Text("logOut")),
      ),
      appBar: AppBar(
        actions: [
          SizedBox(
            width: 30,
          )
        ],
        title: Center(
          child: Text(
            "Chat With Me",
            style: TextStyle(
                color: Color(0xffd3ede6),
                fontSize: 25,
                fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color(0xff31705e),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              FirebaseAnimatedList(
                query: _users,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (BuildContext context, DataSnapshot snapshot,
                    Animation<double> animation, int index) {
                  print(["profilePic", snapshot.value['userData']['email']]);
                  var _pic =
                      snapshot.value['userProfile']['profilePic'].toString();
                  Uint8List bytes = Base64Codec().decode(_pic);
                  String lastMsg = "";
                  String time = "";

                  var msg2 = snapshot.value["messages"];

                  if (msg2 != null) {
                    var msg = snapshot.value["messages"]
                        [store.state.emailModel!.localId.toString()];
                    // ["AlastMsg"];
                    print(["emailbbbbbbR", store.state.emailModel!.localId]);
                    if (msg != null) {
                      lastMsg =
                          '${snapshot.value["messages"][store.state.emailModel!.localId.toString()]["lastMsged"]["lastMsg"]}';
                      DateTime lastTime = DateTime.parse(snapshot
                          .value["messages"]
                              [store.state.emailModel!.localId.toString()]
                              ["lastMsged"]["time"]
                          .toString());
                      DateTime now = DateTime.now();
                      DateTime yesterday = now.subtract(Duration(days: 1));
                      DateTime justNow =
                          DateTime.now().subtract(Duration(minutes: 1));
                      if (!lastTime.difference(justNow).isNegative) {
                        time = "Just Now";
                      } else if (lastTime.day == now.day &&
                          lastTime.month == now.month &&
                          lastTime.year == now.year) {
                        time = "${DateFormat('hh:mm a').format(lastTime)}";
                      } else if (lastTime.day == yesterday.day &&
                          lastTime.month == yesterday.month &&
                          lastTime.year == yesterday.year) {
                        time = "Yesterday";
                      } else {
                        time = '${DateFormat('yMd').format(lastTime)}';
                      }
                    }
                  }

                  return SizeTransition(
                    sizeFactor: animation,
                    child: snapshot.value['userData']['email'].toString() ==
                            store.state.emailModel!.email.toString()
                        ? SizedBox(
                            width: 0,
                            height: 0,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: snapshot.value['fcmToken'] == null
                                ? InkWell(
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
                                                                "@gmail.com",
                                                                ""),
                                                    fcmToken: "1",
                                                    nameId:
                                                        '${snapshot.value['userProfile']['name']}',
                                                    chatPic: bytes,
                                                  )));
                                    },
                                    child: Container(
                                      // color: Colors.amber[100],
                                      child: Column(
                                        children: [
                                          ListTile(
                                              trailing: Container(
                                                child: Column(
                                                  children: [
                                                    Text(time),
                                                  ],
                                                ),
                                              ),
                                              subtitle: Text(lastMsg),
                                              leading: InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (context) =>
                                                              Profilepic(
                                                                profilePic:
                                                                    bytes,
                                                              )));
                                                },
                                                child: CircleAvatar(
                                                    radius: 30,
                                                    backgroundImage:
                                                        MemoryImage(bytes)),
                                              ),
                                              title: Text(
                                                '${snapshot.value['userProfile']['name']}',
                                              )),
                                          Divider(
                                            height: 1,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : InkWell(
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
                                                                "@gmail.com",
                                                                ""),
                                                    fcmToken:
                                                        "${snapshot.value['fcmToken']['fcmToken']}",
                                                    nameId:
                                                        '${snapshot.value['userProfile']['name']}',
                                                    chatPic: bytes,
                                                  )));
                                    },
                                    child: Container(
                                      // color: Colors.amber[100],
                                      child: Column(
                                        children: [
                                          ListTile(
                                              subtitle: Text(lastMsg),
                                              trailing: Container(
                                                child: Column(
                                                  children: [
                                                    Text(time),
                                                  ],
                                                ),
                                              ),
                                              leading: InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (context) =>
                                                              Profilepic(
                                                                profilePic:
                                                                    bytes,
                                                              )));
                                                },
                                                child: CircleAvatar(
                                                  radius: 30,

                                                  backgroundImage:
                                                      MemoryImage(bytes),
                                                  // child: Image.network(
                                                  //   "https://wallpapershome.com/images/pages/pic_h/21486.jpg",
                                                  //   fit: BoxFit.fill,
                                                  // ),
                                                ),
                                              ),
                                              title: Text(
                                                '${snapshot.value['userProfile']['name']}',
                                              )),
                                          Divider(
                                            height: 1,
                                            color: Colors.black,
                                          ),
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

  selectPhoto(BuildContext context, DataSnapshot snapshot, Uint8List bytes) {
    return Stack(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => Profilepic(
                          profilePic: bytes,
                        )));
          },
          child: Hero(
            tag: "click",
            child: CircleAvatar(
              backgroundImage: _image == null
                  ? MemoryImage(bytes) as ImageProvider
                  : FileImage(_image!),
              radius: 57,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 5,
          child: InkWell(
            onTap: () async {
              _showBottomSheetModal();
            },
            child: CircleAvatar(
              child: Icon(
                Icons.edit,
                size: 20,
              ),
              radius: 15,
            ),
          ),
        ),
      ],
    );
  }
}
