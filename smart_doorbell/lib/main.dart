import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'features/user_auth/presentation/pages/login_page.dart';
import 'features/user_auth/presentation/pages/sign_up_page.dart';
import 'features/user_auth/presentation/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/user_auth/presentation/services/notification_service_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  final bool hasConnection = connectivityResult != ConnectivityResult.none;
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDlbuF5opwrVFIaXKX_X9LsFxCMwsdH2aA",
            authDomain: "my-smart-doorbell-f6458.firebaseapp.com",
            projectId: "my-smart-doorbell-f6458",
            storageBucket: "my-smart-doorbell-f6458.firebasestorage.app",
            messagingSenderId: "365528746672",
            appId: "1:365528746672:web:3a7c0dcd6bea69d18f4975"),
      );
      //FirebaseStorage.instance.setMaxUploadRetryTime(Duration(seconds: 30));
      // Ensure Firebase authentication persistence

      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } else {
      // await Firebase.initializeApp();
      if (hasConnection) {
        await Firebase.initializeApp();
      }
    }
    // Initialize notifications
    // final notificationService = NotificationService();
    // await notificationService.initialize();

    // Initialize notifications only if we have connection
    if (hasConnection) {
      final notificationService = NotificationService();
      await notificationService.initialize();
    }
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase - app will work in offline mode
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is signed in
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                String doorbellId = userSnapshot.data!['doorbellId'];
                print(doorbellId);
                return HomePage(doorbellId: doorbellId);
              } else {
                return LoginPage();
              }
            },
          );
        } else {
          // User is not signed in
          return LoginPage();
        }
      },
    );
  }
}
