import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Smart doorbell, Hi!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateStatus(int value) async {
    // Set the value to the specified value
    await _firestore.collection('actions').doc('status').set({
      'value': value,
    });

    // If the value is 1, wait for 5 seconds and then set it back to 0
    if (value == 1) {
      await Future.delayed(const Duration(seconds: 5));
      await _firestore.collection('actions').doc('status').set({
        'value': 0,
      });
    }

    if (value == 2) {
      await Future.delayed(const Duration(seconds: 5));
      await _firestore.collection('actions').doc('status').set({
        'value': 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('counters').doc('counter').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            int counter = snapshot.data!['value'] ?? 0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the doorbell ',
                ),
                Text(
                  '$counter',
                  // style: Theme.of(context).textTheme.headline4,
                ),
                const Text(
                  'times',
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateStatus(1),
                      child: const Text('Access'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => _updateStatus(2),
                      child: const Text('Deny'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
