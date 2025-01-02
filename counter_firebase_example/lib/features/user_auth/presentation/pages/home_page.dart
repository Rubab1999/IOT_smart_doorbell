import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String doorbellId = 'Unknown';
  int doorbellState = 0;
  late Stream<DocumentSnapshot> doorbellStream;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map? arguments = ModalRoute.of(context)?.settings.arguments as Map?;
    doorbellId = arguments != null && arguments.containsKey('doorbellId')
        ? arguments['doorbellId']
        : 'Unknown';
    doorbellStream = FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
        .snapshots();
    doorbellStream.listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          doorbellState = snapshot['doorbellState'];
        });
        if (doorbellState == 1) {
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 60), () {
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
          ? HomeContent(
              doorbellId: doorbellId,
              onAccept: _onAccept,
              onDeny: _onDeny,
            )
          : ProfilePage(),
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

class HomeContent extends StatelessWidget {
  final String doorbellId;
  final VoidCallback onAccept;
  final VoidCallback onDeny;

  HomeContent({
    required this.doorbellId,
    required this.onAccept,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
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

        if (doorbellState == 1) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Bell is ringing!"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onAccept,
                      child: Text("Accept"),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: onDeny,
                      child: Text("Deny"),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (doorbellState == 2) {
          return Center(child: Text("Answer sent!"));
        } else if (doorbellState == 3) {
          return Center(child: Text("Deny sent!"));
        } else if (doorbellState == 4) {
          return Center(child: Text("Automatic deny sent!"));
        } else {
          return Center(child: Text("Doorbell ID: $doorbellId"));
        }
      },
    );
  }
}
