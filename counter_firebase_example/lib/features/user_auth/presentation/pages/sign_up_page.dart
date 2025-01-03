import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';
import 'login_page.dart';
import '../widgets/form_container_widget.dart';
import '../../../../global/common/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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

    // Save doorbell ID to Firestore
    await FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
        .set({
      'doorbellId': doorbellId,
      'doorbellState': 0, // Initial state
      'isInDeadState': 0,
      'doorbellPassword': '123456789', // Initial password
    });

    // Save doorbell ID in user's Firestore document
    await FirebaseFirestore.instance.collection('users').doc(email).set({
      'email': email,
      'doorbellId': doorbellId,
    });

    setState(() {
      isSigningUp = false;
    });
    if (user != null) {
      showToast(message: "User is successfully created");
      Navigator.pushNamed(context, "/home",
          arguments: {'doorbellId': doorbellId});
    } else {
      showToast(message: "Some error happened");
    }
  }

  // void _signUp() async {
  //   setState(() {
  //     isSigningUp = true;
  //   });

  //   String doorbellId = _usernameController.text;
  //   String email = _emailController.text;
  //   String password = _passwordController.text;

  //   try {
  //     // Check if doorbell ID already exists
  //     DocumentSnapshot doorbellDoc = await FirebaseFirestore.instance
  //         .collection('doorbells')
  //         .doc(doorbellId)
  //         .get();

  //     if (doorbellDoc.exists) {
  //       setState(() {
  //         isSigningUp = false;
  //       });
  //       showToast(
  //           message: "Doorbell ID already exists. Please use a different ID.");
  //       return;
  //     }

  //     // Ensure the 'doorbells' collection exists by adding a dummy document if it doesn't exist
  //     CollectionReference doorbellsCollection =
  //         FirebaseFirestore.instance.collection('doorbells');
  //     DocumentSnapshot dummyDoc = await doorbellsCollection.doc('dummy').get();
  //     if (!dummyDoc.exists) {
  //       await doorbellsCollection
  //           .doc('dummy')
  //           .set({'dummyField': 'dummyValue'});
  //     }

  //     // Create user
  //     User? user = await _auth.signUpWithEmailAndPassword(email, password);

  //     if (user != null) {
  //       // Save doorbell ID to Firestore
  //       await FirebaseFirestore.instance
  //           .collection('doorbells')
  //           .doc(doorbellId)
  //           .set({
  //         'doorbellId': doorbellId,
  //         'doorbellState': 0, // Initial state
  //       });

  //       // Save doorbell ID in user's Firestore document
  //       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //         'email': email,
  //         'doorbellId': doorbellId,
  //       });

  //       showToast(message: "User is successfully created");
  //       Navigator.pushNamed(context, "/home");
  //     } else {
  //       showToast(message: "Some error happened");
  //     }
  //   } catch (e) {
  //     showToast(message: "An error occurred: $e");
  //   } finally {
  //     setState(() {
  //       isSigningUp = false;
  //     });
  //   }
  // }
}

// class doorBellModel {
//   final String? doorbellId;
//   final int? doorbellState;

//   doorBellModel({this.doorbellId, this.doorbellState});

//   static doorBellModel fromSnapshot(
//       DocumentSnapshot<Map<String, dynamic>> snapshot) {
//     return doorBellModel(
//       doorbellState: snapshot['doorbellState'],
//       doorbellId: snapshot['doorbellId'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       "doorbellState": doorbellState,
//       "doorbellId": doorbellId,
//     };
//   }
// }
