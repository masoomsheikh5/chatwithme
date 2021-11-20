import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';

class Profilepic extends StatefulWidget {
  final Uint8List profilePic;

  Profilepic({
    Key? key,
    required this.profilePic,
  }) : super(key: key);

  @override
  _ProfilepicState createState() => _ProfilepicState();
}

class _ProfilepicState extends State<Profilepic> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Hero(
        tag: "click",
        child: Center(
          child: Container(
            height: 500,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: MemoryImage(widget.profilePic),
                    fit: BoxFit.contain)),
          ),
        ),
      ),
    ));
  }
}
