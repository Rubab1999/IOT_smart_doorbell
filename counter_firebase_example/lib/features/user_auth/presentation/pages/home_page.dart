import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../global/common/toast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final Map? arguments = ModalRoute.of(context)?.settings.arguments as Map?;
    String doorbellId = arguments != null && arguments.containsKey('doorbellId')
        ? arguments['doorbellId']
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Smart doorbell, Hi!"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Doorbell ID: $doorbellId"),
              // Add other widgets here
              // GestureDetector(
              //   onTap: () {
              //     // Handle tap
              //   },
              //   child: Container(
              //     width: double.infinity,
              //     height: 45,
              //     decoration: BoxDecoration(
              //       color: Colors.blue,
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //     child: Center(
              //       child: Text(
              //         "Tap me",
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
