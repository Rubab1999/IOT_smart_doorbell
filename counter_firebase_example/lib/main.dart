import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'features/app/splash_screen/splash_screen.dart';
import 'features/user_auth/presentation/pages/login_page.dart';
import 'features/user_auth/presentation/pages/sign_up_page.dart';
import 'features/user_auth/presentation/pages/home_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyDlbuF5opwrVFIaXKX_X9LsFxCMwsdH2aA",
          authDomain: "my-smart-doorbell-f6458.firebaseapp.com",
          projectId: "my-smart-doorbell-f6458",
          storageBucket: "my-smart-doorbell-f6458.firebasestorage.app",
          messagingSenderId: "365528746672",
          appId: "1:365528746672:web:3a7c0dcd6bea69d18f4975"
          // Your web Firebase config options
          ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      routes: {
        '/': (context) => SplashScreen(
              // Here, you can decide whether to show the LoginPage or HomePage based on user authentication
              child: LoginPage(),
            ),
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
