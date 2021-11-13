// ignore_for_file: file_names, prefer_const_constructors_in_immutables

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatwithme/chat.dart';
import 'package:chatwithme/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _image;
  final picker = ImagePicker();
  bool _isCamera = false;
  String? _imageBase64;
  final FirebaseDatabase database = FirebaseDatabase();
  late DatabaseReference _users;
  late StreamSubscription<Event> _userSubscription;
  List _userlist = [];

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
          imageQuality: 50,
          maxHeight: 200,
          maxWidth: 200);
      List<int> imageBytes = await pickedFile!.readAsBytes();
      print(imageBytes);
      String base64Image = base64Encode(imageBytes);
      print(base64Image);
      setState(() {
        _image = File(pickedFile.path);
        _imageBase64 = base64Image;
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
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          // color: Colors.amber,
          child: Column(
            children: [
              Container(
                height: 280,
                width: MediaQuery.of(context).size.width,
                color: Color(0xff31705e),
                child: Container(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      selectPhoto(context),
                      // CircleAvatar(
                      //   radius: 80,
                      //   backgroundColor: Colors.amber,
                      // ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        child: Text("data"),
                      ),
                    ],
                  ),
                ),
              ),
              // Divider(
              //   color: Colors.black,
              //   thickness: 18,
              // ),
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
            ],
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
                                                  )));
                                    },
                                    child: Container(
                                      // color: Colors.amber[100],
                                      child: Column(
                                        children: [
                                          ListTile(
                                              leading: CircleAvatar(
                                                radius: 30,

                                                backgroundImage: NetworkImage(
                                                  "https://wallpapershome.com/images/pages/pic_h/21486.jpg",
                                                ),
                                                // child: Image.network(
                                                //   "https://wallpapershome.com/images/pages/pic_h/21486.jpg",
                                                //   fit: BoxFit.fill,
                                                // ),
                                              ),
                                              title: Text(
                                                '${snapshot.value['userData']['email']}',
                                              )),
                                          Divider(
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
                                                  )));
                                    },
                                    child: Container(
                                      // color: Colors.amber[100],
                                      child: Column(
                                        children: [
                                          ListTile(
                                              leading: CircleAvatar(
                                                radius: 30,

                                                backgroundImage: NetworkImage(
                                                  "https://wallpapershome.com/images/pages/pic_h/21486.jpg",
                                                ),
                                                // child: Image.network(
                                                //   "https://wallpapershome.com/images/pages/pic_h/21486.jpg",
                                                //   fit: BoxFit.fill,
                                                // ),
                                              ),
                                              title: Text(
                                                '${snapshot.value['userData']['email']}',
                                              )),
                                          Divider(
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

  selectPhoto(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: () {
            _showBottomSheetModal();
          },
          child: CircleAvatar(
            backgroundImage: _image == null
                ? AssetImage("assets/icons/avatar.png") as ImageProvider
                : FileImage(_image!),
            radius: 57,
          ),
        ),
        Positioned(
          bottom: 20,
          right: 5,
          child: CircleAvatar(
            child: Icon(
              Icons.edit,
              size: 20,
            ),
            radius: 15,
          ),
        ),
      ],
    );
  }
}
