import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';
import 'login_page.dart';
import '../widgets/form_container_widget.dart';
import '../../../../global/common/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart'; // Import the HomePage class
import '../services/notification_service_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  bool isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("SignUp"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sign Up",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _usernameController,
                hintText: "doorbell unique ID",
                isPasswordField: false,
              ),
              SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              SizedBox(
                height: 30,
              ),
              GestureDetector(
                onTap: () {
                  _signUp();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: isSigningUp
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              "Sign Up",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                            (route) => false);
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String doorbellId = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    // Check if doorbell ID already exists
    DocumentSnapshot doorbellDoc = await FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
        .get();

    if (doorbellDoc.exists) {
      setState(() {
        isSigningUp = false;
      });
      showToast(
          message: "Doorbell ID already exists. Please use a different ID.");
      return;
    }

    User? user = await _auth.signUpWithEmailAndPassword(email, password);

    if (user != null) {
      // Save doorbell ID to Firestore
      await FirebaseFirestore.instance
          .collection('doorbells')
          .doc(doorbellId)
          .set({
        'doorbellId': doorbellId,
        'doorbellState': 0, // Initial state
        'isInDeadState': 0,
        'doorbellPassword': '1111', // Initial password
        'imageURL': '',
        'message': '',
      });

      // Save doorbell ID in user's Firestore document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'doorbellId': doorbellId,
      });

      await _notificationService.subscribeToDoorbell(doorbellId);

      // showToast(message: "User is successfully created");
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => HomePage(doorbellId: doorbellId),
      //   ),
      // );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Verify Your Email'),
            content: Text(
                'Please check your email and verify your account before logging in.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      );
    } else {
      showToast(message: "Error during signup");
    }

    setState(() {
      isSigningUp = false;
    });
  }
}
