import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _passwordController = TextEditingController();
  String doorbellId = 'Unknown';
  String doorbellPassword = 'Unknown';
  bool _isPasswordVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map? arguments = ModalRoute.of(context)?.settings.arguments as Map?;
    doorbellId = arguments != null && arguments.containsKey('doorbellId')
        ? arguments['doorbellId']
        : 'Unknown';
    _fetchDoorbellPassword();
  }

  Future<void> _fetchDoorbellPassword() async {
    DocumentSnapshot doorbellDoc = await FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
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
        .doc(doorbellId)
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
        .doc(doorbellId)
        .update({'isInDeadState': 0});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('isInDeadState updated to 0')),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Profile Page"),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Doorbell ID: $doorbellId"),
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
            SizedBox(height: 100),
            ElevatedButton(
              onPressed: _resetIsInDeadState,
              child: Text("Enable Doorbell Keypad"),
            ),
          ],
        ),
      ),
    );
  }
}
