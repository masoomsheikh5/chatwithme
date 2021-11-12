import 'dart:convert';

import 'package:chatwithme/chatRoom.dart';
import 'package:chatwithme/login.dart';
import 'package:chatwithme/main.dart';
import 'package:chatwithme/model/emailModel.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../store/appState.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const BASE_URL = "https://identitytoolkit.googleapis.com/v1";
const API_KEY = "key=AIzaSyAbGlJ7LXKMVK_jFATgcjA5gd2mDe14dVA";

ThunkAction<AppState> loginUser(context, fcmToken, email, pass) {
  print(['loginUser api running', email, pass]);
  return (Store<AppState> store) async {
    var url = Uri.parse("$BASE_URL/accounts:signInWithPassword?$API_KEY");
    var body = {
      "email": "$email",
      "password": "$pass",
      "returnSecureToken": "true"
    };
    var response = await http.post(url, body: body);
    print(['loginUser api res', response.body]);
    if (response.statusCode == 200) {
      var newResponse = jsonDecode(response.body);
      // print(["newResponse",newResponse]);
      final FirebaseDatabase database = FirebaseDatabase();
      var fcmTtoken = {"fcmToken": "$fcmToken"};
      database
          .reference()
          .child('users')
          .child(newResponse['localId'])
          .child("fcmToken")
          .set(fcmTtoken);
      store.dispatch(storeUser(context, response.body));
      store.dispatch(EmailModel.fromJson(newResponse));
      Future.delayed(Duration(seconds: 1), () {
        // store.dispatch(fetchUserProfile(context));
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Chatroom()),
      );
      // print(['newResponse', newResponse['localid']]);
    } else {}
  };
}

ThunkAction<AppState> msgnoti(fcmToken, msgBody, msgTitle) {
  return (Store<AppState> store) async {
    var url = Uri.parse("https://fcm.googleapis.com/fcm/send");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization":
          "key=AAAAQYrUhXs:APA91bHhlJrixDqmWoTEZO0EE4QCHAzWO8qeu7vsWrnepW6d7KXf3NMXGh-JtXEkaC6RgeD0xJnOL44yNwivvtPqFBGrYN6wyPNixbvgmgT5NUK8tbg3vAyRA8Qf8rCm5fv8ClqJ81na"
    };
    final msg = jsonEncode({
      "to": fcmToken,
      "notification": {
        "title": msgTitle,
        "body": msgBody,
        "mutable_content": true,
        "sound": "Tri-tone"
      },
      // "data": {
      //   "url": "<url of media image>",
      //   "dl": "<deeplink action on tap of notification>"
      // }
    });
    var response = await http.post(url, body: msg, headers: headers);
    print(["message", response.body]);
  };
}

ThunkAction<AppState> ragisterUser(context, fcmToken, email, pass) {
  print(['loginUser api running', email, pass]);
  return (Store<AppState> store) async {
    var url = Uri.parse("$BASE_URL/accounts:signUp?$API_KEY");
    var body = {
      "email": "$email",
      "password": "$pass",
      "returnSecureToken": "true"
    };
    var response = await http.post(url, body: body);
    print(['loginUser api res', response.body]);
    print(['local id', response.body]);
    if (response.statusCode == 200) {
      var newResponse = jsonDecode(response.body);
      print(["newResponse", newResponse['localId']]);
      final FirebaseDatabase database = FirebaseDatabase();
      var fcmTtoken = {"fcmToken": "$fcmToken"};
      database
          .reference()
          .child('users')
          .child(newResponse['localId'])
          .child("userData")
          .set(newResponse);
      database
          .reference()
          .child('users')
          .child(newResponse['localId'])
          .child("fcmToken")
          .set(fcmTtoken);
      store.dispatch(storeUser(context, response.body));
      store.dispatch(EmailModel.fromJson(newResponse));
      Future.delayed(Duration(seconds: 1), () {
        // store.dispatch(fetchUserProfile(context));
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Chatroom()),
      );
    } else {}
  };
}

ThunkAction<AppState> storeUser(context, res) {
  print('storeUser api running');
  return (Store<AppState> store) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("userLoginToken", res);
  };
}

//logout
ThunkAction<AppState> logout(context) {
  print('logout api running');
  return (Store<AppState> store) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("userLoginToken");
    store.dispatch(AppState.initial());
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (BuildContext context) => Login()));
  };
}
