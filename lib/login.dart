import 'package:chatwithme/chatRoom.dart';
import 'package:chatwithme/main.dart';
import 'package:chatwithme/signup.dart';
import 'package:chatwithme/store/appState.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/cupertino.dart';
import '/store/actions.dart' as action;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController Pass = TextEditingController();

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      // appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: Container(
              padding: EdgeInsets.only(top: 10),
              height: 300,
              width: 300,
              // color: Colors.amber,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "LOGIN",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: email,
                            decoration: InputDecoration(
                              label: Text(
                                "Email or Phone",
                              ),
                              hintText: "Email or phone",
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            controller: Pass,
                            decoration: InputDecoration(
                              label: Text(
                                "Password",
                              ),
                              hintText: "Password",
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                 if (_formKey.currentState!.validate()) {
                                store.dispatch(action.loginUser(
                                context,
                                email.text.trim(),
                                 Pass.text.trim()));
                                 }
                              
                              },
                              
                              child:  Text(
                          "Sign In",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        )
                     
                
                              ),

                          TextButton(
                              onPressed: () {
                                   if (_formKey.currentState!.validate()) {
                                store.dispatch(action.ragisterUser(
                                context,
                                email.text.trim(),
                                 Pass.text.trim()));
                                 }
                                // Navigator.push(
                                //     context,
                                //     CupertinoPageRoute(
                                //         builder: (context) => Chatroom()));
                              },
                              child: Text("Sign up"))
                        ],
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
