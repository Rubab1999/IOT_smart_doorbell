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
      title: 'smart_doorbell',
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

  void _updateAccess(String docId) async {
    // Set the value to 1
    await _firestore.collection('actions').doc(docId).set({
      'value': 1,
    });

    // Wait for 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    // Set the value back to 0
    await _firestore.collection('actions').doc(docId).set({
      'value': 0,
    });
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
                      onPressed: () => _updateAccess('access'),
                      child: const Text('Access'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => _updateAccess('deny'),
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
