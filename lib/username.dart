// import 'package:chatwithme/main.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chatwithme/chatRoom.dart';
import 'package:chatwithme/main.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserName extends StatefulWidget {
  UserName({Key? key}) : super(key: key);

  @override
  _UserNameState createState() => _UserNameState();
}

class _UserNameState extends State<UserName> {
  DatabaseReference? _messagesRef;
  final _formKey = GlobalKey<FormState>();
  var defaultPic =
      "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";
  TextEditingController _namecontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    Uint8List bytes = Base64Codec().decode(defaultPic);

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                ),
                Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _namecontroller,
                          validator: (value) {
                            if (value!.trim().isEmpty) {
                              return "please enter user name";
                            }
                          },
                          autofocus: true,
                          decoration: InputDecoration(
                              label: Text("USERNAME"),
                              hintText: 'Create Your User Name '),
                        ),
                        ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pushReplacement(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => Chatroom()));
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setString(
                                    "usernameId", _namecontroller.text);
                                String? usernameId =
                                    prefs.getString('usernameId');
                                print(["name", usernameId]);
                                final FirebaseDatabase database =
                                    FirebaseDatabase();
                                var username = <String, String>{
                                  "name": _namecontroller.text,
                                  "profilePic": defaultPic,
                                };
                                database
                                    .reference()
                                    .child('users')
                                    .child(store.state.emailModel!.localId
                                        .toString())
                                    .child('userProfile')
                                    .set(username);
                              }
                            },
                            child: Text("submit"))
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
