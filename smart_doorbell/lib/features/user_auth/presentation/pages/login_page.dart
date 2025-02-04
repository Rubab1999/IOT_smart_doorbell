import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up_page.dart';
import '../widgets/form_container_widget.dart';
import '../../../../global/common/toast.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';
import '../services/notification_service_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  static const String FIRST_LOGIN_KEY = 'first_login_';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Login"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _signIn,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigning
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/signUp',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    if (!mounted) return;

    setState(() {
      _isSigning = true;
    });

    try {
      String email = _emailController.text;
      String password = _passwordController.text;

      User? user = await _auth.signInWithEmailAndPassword(email, password);

      if (!mounted) return;

      setState(() {
        _isSigning = false;
      });

      if (user != null) {
        // Check if email is verified
        if (!user.emailVerified) {
          showToast(message: "Please verify your email before logging in");
          // Optionally offer to resend verification email
          await user.sendEmailVerification();
          return;
        }

        if (!mounted) return;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String doorbellId = userDoc['doorbellId'];
          //added code
          // Check if first login on this device for this user
          final prefs = await SharedPreferences.getInstance();
          bool isFirstLogin =
              !(prefs.getBool(FIRST_LOGIN_KEY + user.uid) ?? false);

          if (isFirstLogin) {
            if (!mounted) return;
            await _showWelcomeDialog();
            await prefs.setBool(FIRST_LOGIN_KEY + user.uid, true);
          }
          await _notificationService.subscribeToDoorbell(doorbellId);

          showToast(message: "User is successfully signed in");
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'doorbellId': doorbellId},
          );
        } else {
          showToast(message: "User document does not exist");
        }
      } else {
        showToast(message: "Some error occurred");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSigning = false;
      });
      showToast(message: "An error occurred: $e");
    }
  }

  Future<void> _showWelcomeDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.blue),
              SizedBox(width: 10),
              Text('Welcome!')
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Here\'s what you can do:'),
              SizedBox(height: 10),
              Text('• Get notified when someone rings the bell'),
              Text('• See who\'s at your door'),
              Text('• Accept or deny access'),
              Text('• View visitor history'),
              Text('• Manage doorbell settings'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Got it!'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
  // void _signIn() async {
  //   if (!mounted) return;

  //   setState(() {
  //     _isSigning = true;
  //   });

  //   try {
  //     String email = _emailController.text;
  //     String password = _passwordController.text;

  //     User? user = await _auth.signInWithEmailAndPassword(email, password);

  //     if (!mounted) return;

  //     if (user != null) {
  //       // Check email verification
  //       if (!user.emailVerified) {
  //         setState(() {
  //           _isSigning = false;
  //         });
  //         showToast(message: "Please verify your email before logging in");
  //         await user.sendEmailVerification();
  //         return;
  //       }

  //       if (!mounted) return;

  //       // Get user document
  //       DocumentSnapshot userDoc = await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(user.uid)
  //           .get();

  //       if (!mounted) return;

  //       if (userDoc.exists) {
  //         String doorbellId = userDoc['doorbellId'];

  //         // Subscribe to notifications
  //         try {
  //           await _notificationService.subscribeToDoorbell(doorbellId);
  //         } catch (e) {
  //           print("Notification subscription error: $e");
  //         }

  //         if (!mounted) return;

  //         showToast(message: "User is successfully signed in");
  //         Navigator.pushReplacementNamed(
  //           context,
  //           '/home',
  //           arguments: {'doorbellId': doorbellId},
  //         );
  //       } else {
  //         setState(() {
  //           _isSigning = false;
  //         });
  //         showToast(message: "User document does not exist");
  //       }
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _isSigning = false;
  //     });
  //     showToast(message: "An error occurred: $e");
  //   }
  // }
}
