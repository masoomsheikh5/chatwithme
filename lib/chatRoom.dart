// ignore_for_file: file_names, prefer_const_constructors_in_immutables

import 'dart:async';

import 'package:chatwithme/chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Chatroom extends StatefulWidget {
  Chatroom({Key? key}) : super(key: key);

  @override
  _ChatroomState createState() => _ChatroomState();
}

class _ChatroomState extends State<Chatroom> {
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
      body: Container(
        child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context, CupertinoPageRoute(builder: (context) => Chat()));
            },
            child: Text("data")),
      ),
    ));
  }
}
