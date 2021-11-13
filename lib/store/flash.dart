import 'dart:async';
import 'package:chatwithme/chatRoom.dart';
import 'package:chatwithme/login.dart';
import 'package:chatwithme/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/store/actions.dart' as action;
import 'package:flutter/material.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  @override
  VideoState createState() => VideoState();
}

class VideoState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  var _visible = true;
  AnimationController? animationController;
  Animation<double>? animation;

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? userDetais = prefs.getString("userLoginToken");
      if (userDetais != null) {
        print(["userLoginToken", userDetais]);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Chatroom()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Login()));
      }
    });
    animationController = new AnimationController(
        vsync: this, duration: new Duration(seconds: 1));
    animation = new CurvedAnimation(
        parent: animationController!, curve: Curves.easeOut);

    animation!.addListener(() => this.setState(() {}));
    animationController!.forward();

    setState(() {
      _visible = !_visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * 2,
            // decoration: BoxDecoration(
            //     image: DecorationImage(
            //         image: AssetImage("assets/bg.png"), fit: BoxFit.fitHeight)),
          ),
          Center(
            child: Hero(
              tag: "logo",
              child: new Image.asset(
                'assets/image/chat_with_me_logo.png',
                width: animation!.value * 250,
                height: animation!.value * 250,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
