import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      // appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(top: 70, left: 30, right: 30),

          // color: Colors.amber,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Welcome",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: username,
                        decoration: InputDecoration(
                          label: Text(
                            "username",
                          ),
                          hintText: "Email ",
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: email,
                        decoration: InputDecoration(
                          label: Text(
                            "Phone",
                          ),
                          hintText: "Email or phone",
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: phone,
                        decoration: InputDecoration(
                          label: Text(
                            "Email",
                          ),
                          hintText: "Email or phone",
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        // controller: email,
                        decoration: InputDecoration(
                          label: Text(
                            "Password",
                          ),
                          hintText: "Email or phone",
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: pass,
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
                      ElevatedButton(onPressed: () {}, child: Text("Submit")),
                    ],
                  ))
            ],
          ),
        ),
      ),
    ));
  }
}
