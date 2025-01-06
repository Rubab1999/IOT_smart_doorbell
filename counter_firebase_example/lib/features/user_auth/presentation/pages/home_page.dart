import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  final String? doorbellId;

  const HomePage({super.key, this.doorbellId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String doorbellId = 'Unknown';
  int doorbellState = 0;
  int isInDeadState = 0;
  late Stream<DocumentSnapshot> doorbellStream;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Extract doorbellId from arguments if not passed directly
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    doorbellId = widget.doorbellId ?? args?['doorbellId'] ?? 'Unknown';
    print('Doorbell ID: $doorbellId');
    if (doorbellId != 'Unknown') {
      _initializeDoorbellStream();
    }
  }

  void _initializeDoorbellStream() {
    doorbellStream = FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
        .snapshots();
    doorbellStream.listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          doorbellState = snapshot['doorbellState'];
          isInDeadState = snapshot['isInDeadState'];
        });
        if (doorbellState == 1) {
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 15), () {
      if (doorbellState == 1) {
        _updateDoorbellState(4); // Automatic Deny
      }
    });
  }

  void _updateDoorbellState(int newState) {
    FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
        .update({'doorbellState': newState});
    if (newState == 2 || newState == 3 || newState == 4) {
      Timer(Duration(seconds: 6), () {
        FirebaseFirestore.instance
            .collection('doorbells')
            .doc(doorbellId)
            .update({'doorbellState': 0});
      });
    }
  }

  void _onAccept() {
    _updateDoorbellState(2); // Accept
  }

  void _onDeny() {
    _updateDoorbellState(3); // Manual Deny
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Smart doorbell"),
      ),
      body: _selectedIndex == 0
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doorbells')
                  .doc(doorbellId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.data!.exists) {
                  return Center(
                      child: Text("Doorbell ID: $doorbellId does not exist."));
                }

                int doorbellState = snapshot.data!['doorbellState'];
                int isInDeadState = snapshot.data!['isInDeadState'];

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (doorbellState == 1) ...[
                      Text("Bell is ringing!"),
                      SizedBox(height: 20),
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Image.asset(
                            'assets/images/cat_ringing_doorbell.jpg'),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _onAccept,
                            child: Text("Accept"),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _onDeny,
                            child: Text("Deny"),
                          ),
                        ],
                      ),
                    ] else if (doorbellState == 2) ...[
                      Center(child: Text("Access sent!")),
                    ] else if (doorbellState == 3) ...[
                      Center(child: Text("Deny sent!")),
                    ] else if (doorbellState == 4) ...[
                      Center(child: Text("Automatic deny sent!")),
                    ] else ...[
                      Center(child: Text("Doorbell ID: $doorbellId")),
                    ],
                    if (isInDeadState == 1) ...[
                      Spacer(),
                      Container(
                        color: Colors.red,
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "Doorbell keypad locked, press the reset button",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            )
          : ProfilePage(doorbellId: doorbellId),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
