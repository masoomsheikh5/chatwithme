import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          height: 400,
          width: 350,
          // color: Colors.grey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.amber,
              ),
              TextFormField(
                decoration: InputDecoration(
                  label: Text("enter your user name "),
                ),
              )
            ],
          ),
        ),
      ),
    ));
  }
}
