import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final String doorbellId;

  const ProfilePage({super.key, required this.doorbellId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _passwordController = TextEditingController();
  String doorbellPassword = 'Unknown';
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchDoorbellPassword();
  }

  Future<void> _fetchDoorbellPassword() async {
    DocumentSnapshot doorbellDoc = await FirebaseFirestore.instance
        .collection('doorbells')
        .doc(widget.doorbellId)
        .get();

    if (doorbellDoc.exists) {
      setState(() {
        doorbellPassword = doorbellDoc['doorbellPassword'];
        _passwordController.text = doorbellPassword;
      });
    }
  }

  Future<void> _updateDoorbellPassword() async {
    await FirebaseFirestore.instance
        .collection('doorbells')
        .doc(widget.doorbellId)
        .update({'doorbellPassword': _passwordController.text});

    setState(() {
      doorbellPassword = _passwordController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password updated successfully')),
    );
  }

  Future<void> _resetIsInDeadState() async {
    await FirebaseFirestore.instance
        .collection('doorbells')
        .doc(widget.doorbellId)
        .update({'isInDeadState': 0});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('isInDeadState updated to 0')),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: Text("Profile Page"),
          ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Doorbell ID: ${widget.doorbellId}"),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Doorbell Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateDoorbellPassword,
              child: Text("Update Password"),
            ),
            SizedBox(height: 200),
            ElevatedButton(
              onPressed: _resetIsInDeadState,
              child: Text("Enable Doorbell Keypad"),
            ),
            SizedBox(height: 200),
            ElevatedButton(
              onPressed: _signOut,
              child: Text("Sign Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Background color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
