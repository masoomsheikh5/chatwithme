import 'dart:async';

import 'package:chatwithme/chatRoom.dart';
import 'package:chatwithme/login.dart';
import 'package:chatwithme/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/store/actions.dart' as action;
import 'package:flutter/material.dart';

class FlashScereen extends StatefulWidget {
  FlashScereen({Key? key}) : super(key: key);

  @override
  _FlashScereenState createState() => _FlashScereenState();
}

class _FlashScereenState extends State<FlashScereen> {
  ////notification setup

  // late final FirebaseMessaging _messaging;
  // late int _totalNotifications;
  // PushNotification? _notificationInfo;

  // void registerNotification() async {
  //   await Firebase.initializeApp();
  //   _messaging = FirebaseMessaging.instance;

  //   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  //   NotificationSettings settings = await _messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     provisional: false,
  //     sound: true,
  //   );
  //   _messaging.getToken().then((token) async {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     prefs.setString("fcmToken", token.toString());
  //     print(["fcmToken", token]); // Print the Token in Console
  //   });

  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     print('User granted permission');

  //     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //       print(
  //           'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');

  //       // Parse the message received
  //       PushNotification notification = PushNotification(
  //         title: message.notification?.title,
  //         body: message.notification?.body,
  //         dataTitle: message.data['title'],
  //         dataBody: message.data['body'],
  //       );

  //       setState(() {
  //         _notificationInfo = notification;
  //         _totalNotifications++;
  //       });

  //       if (_notificationInfo != null) {
  //         // For displaying the notification as an overlay
  //         showSimpleNotification(
  //           Text(_notificationInfo!.title!),
  //           leading: NotificationBadge(totalNotifications: _totalNotifications),
  //           subtitle: Text(_notificationInfo!.body!),
  //           background: Colors.cyan.shade700,
  //           duration: Duration(seconds: 2),
  //         );
  //       }
  //     });
  //   } else {
  //     print('User declined or has not accepted permission');
  //   }
  // }

  // // For handling notification when the app is in terminated state
  // checkForInitialMessage() async {
  //   await Firebase.initializeApp();
  //   RemoteMessage? initialMessage =
  //       await FirebaseMessaging.instance.getInitialMessage();

  //   if (initialMessage != null) {
  //     PushNotification notification = PushNotification(
  //       title: initialMessage.notification?.title,
  //       body: initialMessage.notification?.body,
  //       dataTitle: initialMessage.data['title'],
  //       dataBody: initialMessage.data['body'],
  //     );

  //     setState(() {
  //       _notificationInfo = notification;
  //       _totalNotifications++;
  //     });
  //   }
  // }

  @override
  void initState() {
    Timer(Duration(seconds: 3), () {
      if (store.state.emailModel != null) {
        print(["store.state.emailModel", store.state.emailModel]);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Chatroom()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Login()));
      }
    });
    // _totalNotifications = 0;
    // registerNotification();
    // checkForInitialMessage();

    // For handling notification when the app is in background
    // but not terminated
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   PushNotification notification = PushNotification(
    //     title: message.notification?.title,
    //     body: message.notification?.body,
    //     dataTitle: message.data['title'],
    //     dataBody: message.data['body'],
    //   );

    //   setState(() {
    //     _notificationInfo = notification;
    //     _totalNotifications++;
    //   });
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image(image: AssetImage("assets/image/chat_with_me_logo.png")),
      ),
    );
  }
}
