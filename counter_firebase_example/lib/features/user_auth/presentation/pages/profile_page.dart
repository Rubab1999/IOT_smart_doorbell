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
        title: Text("Profile Settings"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              // Center(
              //   child: Column(
              //     children: [
              //       Icon(
              //         Icons.security,
              //         size: 80,
              //         color: Colors.blue,
              //       ),
              //       SizedBox(height: 16),
              //       Text(
              //         "Smart Doorbell Security",
              //         style: TextStyle(
              //           fontSize: 24,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              SizedBox(height: 20),

              // Doorbell ID Card
              // Replace the Doorbell ID Card and Password Card sections with:

// Doorbell Information Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Doorbell Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.doorbell, color: Colors.blue),
                        title: Text("Doorbell ID"),
                        subtitle: Text(
                          widget.doorbellId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Doorbell Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.blue,
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
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text("Update Password"),
                          onPressed: _updateDoorbellPassword,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 60),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Device Actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Divider(),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('doorbells')
                            .doc(widget.doorbellId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }

                          final isInDeadState =
                              snapshot.data!['isInDeadState'] ?? 0;

                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text("Doorbell Keypad reset"),
                              onPressed: isInDeadState == 1
                                  ? () {
                                      _resetIsInDeadState();
                                    }
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Keypad is already enabled'),
                                          backgroundColor: const Color.fromARGB(
                                              200, 0, 0, 0),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // Change button color based on state
                                backgroundColor: isInDeadState == 1
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Actions Card
              // Card(
              //   elevation: 4,
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           "Device Actions",
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.blue,
              //           ),
              //         ),
              //         Divider(),
              //         SizedBox(
              //           width: double.infinity,
              //           child: ElevatedButton.icon(
              //             icon: Icon(Icons.refresh),
              //             label: Text("Doorbell Keypad reset"),
              //             onPressed: _resetIsInDeadState,
              //             style: ElevatedButton.styleFrom(
              //               padding: EdgeInsets.symmetric(vertical: 12),
              //               shape: RoundedRectangleBorder(
              //                 borderRadius: BorderRadius.circular(8),
              //               ),
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              SizedBox(height: 90),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text("Sign Out"),
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
