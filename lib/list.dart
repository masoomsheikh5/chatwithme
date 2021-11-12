import 'package:flutter/material.dart';

class Listing extends StatefulWidget {
  Listing({Key? key}) : super(key: key);

  @override
  _ListingState createState() => _ListingState();
}

class _ListingState extends State<Listing> {
  final TextEditingController _namecontroller = TextEditingController();
  final GlobalKey _formkey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(24)),
              TextFormField(
                controller: _namecontroller,
                decoration:
                    InputDecoration(label: Text("name"), hintText: 'abc'),
              )
            ],
          ),
        ),
      ),
    ));
  }
}
