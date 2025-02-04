import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'dart:async';
import 'history_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/notification_service_page.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

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
  String imageURL = '';
  late Stream<DocumentSnapshot> doorbellStream;
  //Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  bool _isConnected = true;
  String constantImageUrl =
      "https://firebasestorage.googleapis.com/v0/b/my-smart-doorbell-f6458.firebasestorage.app/o/images%2Fdefault.png?alt=media&token=6d2d5783-c4a7-44bc-b338-ad6741dc9736";

  // @override
  // void initState() {
  //   super.initState();
  //   //_subscribeToDoorbellTopic();
  // }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    var results = await Connectivity().checkConnectivity();
    if (results.isNotEmpty) {
      _updateConnectionStatus(results.first); // Use the first result
    } else {
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isConnected = (result != ConnectivityResult.none);
    });

    if (!_isConnected) {
      _showNoConnectionMessage();
    }
  }

  void _showNoConnectionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No internet connection. Please check your network.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _initializeData() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    doorbellId = widget.doorbellId ?? args?['doorbellId'] ?? 'Unknown';
    print('Doorbell ID: $doorbellId');

    if (doorbellId != 'Unknown') {
      await _notificationService.subscribeToDoorbell(doorbellId);
      _initializeDoorbellStream();
    }
  }

  Future<void> _subscribeToDoorbellTopic() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    doorbellId = widget.doorbellId ?? args?['doorbellId'] ?? 'Unknown';

    if (doorbellId != 'Unknown') {
      await _notificationService.subscribeToDoorbell(doorbellId);
      _initializeDoorbellStream();
    }
  }

  @override
  void dispose() {
    if (doorbellId != 'Unknown') {
      _notificationService.unsubscribeFromDoorbell(doorbellId);
    }
    // _timer?.cancel();
    super.dispose();
  }

  // Get image url from firestore and display it in a dialog
  Future<String> _getImageUrl(String imageUrl) async {
    final ref = FirebaseStorage.instance.ref().child(imageUrl);
    var url = await ref.getDownloadURL();
    return url;
  }

  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: -10,
                top: -10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeData();
      _isInitialized = true;
    }
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    doorbellId = widget.doorbellId ?? args?['doorbellId'] ?? 'Unknown';
    print('Doorbell ID: $doorbellId');
    if (doorbellId != 'Unknown') {
      _initializeDoorbellStream();
    }
  }

  // void _initializeDoorbellStream() {
  //   doorbellStream = FirebaseFirestore.instance
  //       .collection('doorbells')
  //       .doc(doorbellId)
  //       .snapshots();

  //   doorbellStream.listen((snapshot) {
  //     if (snapshot.exists) {
  //       setState(() {
  //         doorbellState = snapshot['doorbellState'];
  //         isInDeadState = snapshot['isInDeadState'];
  //         imageURL = snapshot['imageURL'] ?? '';
  //       });

  //       if (doorbellState == 4 || doorbellState == 3 || doorbellState == 2) {
  //         Timer(Duration(seconds: 7), () {
  //           FirebaseFirestore.instance
  //               .collection('doorbells')
  //               .doc(doorbellId)
  //               .update({
  //             'doorbellState': 0,
  //             'message': '',
  //           });
  //         });
  //       }

  //       if (doorbellState == 1) {
  //         _startTimer();
  //       }
  //     }
  //   });
  // }

  // Add at class level:

// Updated method:
  void _initializeDoorbellStream() {
    doorbellStream = FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
        .snapshots();

    doorbellStream.listen((snapshot) {
      if (snapshot.exists) {
        // Get new state before setState
        final int newDoorbellState = snapshot['doorbellState'];

        // Check if doorbell just got rang
        // if (newDoorbellState == 1 && doorbellState != 1) {
        //   _notificationService.showNotification(
        //       'Doorbell Alert!', 'Someone is at your door!');
        // }

        setState(() {
          doorbellState = newDoorbellState;
          isInDeadState = snapshot['isInDeadState'];
          imageURL = snapshot['imageURL'] ?? '';
        });

        // if (doorbellState == 1) {
        //   _startTimer();
        // }
        //keep this for now
        // if (doorbellState == 4 || doorbellState == 3 || doorbellState == 2) {
        //   Timer(Duration(seconds: 7), () {
        //     FirebaseFirestore.instance
        //         .collection('doorbells')
        //         .doc(doorbellId)
        //         .update({
        //       'doorbellState': 0,
        //       'message': '',
        //     });
        //   });
        // }
      }
    });
  }

  // void _startTimer() {
  //   _timer?.cancel();
  //   _timer = Timer(Duration(seconds: 60), () {
  //     if (doorbellState == 1) {
  //       _updateDoorbellState(
  //           4, ''); // here can add message when auto .. maybe a new feauture...
  //     }
  //   });
  // }

  void _saveToTodayHistory(String imageURL) async {
    try {
      print('Starting save to history with doorbellId: $doorbellId');
      print('Image URL being saved: $imageURL');

      final docRef = FirebaseFirestore.instance
          .collection('doorbells')
          .doc(doorbellId)
          .collection('today_history')
          .doc();

      final data = {
        'date': FieldValue.serverTimestamp(),
        'imageURL': imageURL,
      };

      await docRef.set(data);
      print('Document created with ID: ${docRef.id}');
    } catch (e) {
      print('Error in _saveToTodayHistory: $e');
    }
  }

  // void _saveToPermHistory(String imageURL, DateTime date) async {
  //   try {
  //     await FirebaseFirestore.instance
  //         .collection('doorbells')
  //         .doc(doorbellId)
  //         .collection('perm_history')
  //         .add({
  //       'date': date,
  //       'imageURL': imageURL,
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Image saved to history')),
  //     );
  //   } catch (e) {
  //     print('Error saving to permanent history: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to save image')),
  //     );
  //   }
  // }

  void _saveToPermHistory(String imageURL, DateTime date) async {
    try {
      // Check if image already exists in perm_history for this date
      // final existingDocs = await FirebaseFirestore.instance
      //     .collection('doorbells')
      //     .doc(doorbellId)
      //     .collection('perm_history')
      //     .where('imageURL', isEqualTo: imageURL)
      //     .get();

      // Check if image already exists in perm_history for this date
      final existingDocs = await FirebaseFirestore.instance
          .collection('doorbells')
          .doc(doorbellId)
          .collection('perm_history')
          .where('imageURL', isEqualTo: imageURL)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .get();

      if (existingDocs.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visitor info already saved in history')),
        );
        return;
      }

      // Save with original date and time
      await FirebaseFirestore.instance
          .collection('doorbells')
          .doc(doorbellId)
          .collection('perm_history')
          .add({
        'date': date, // Using original date when bell rang
        'imageURL': imageURL,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visitor info saved to history')),
      );
    } catch (e) {
      print('Error saving to permanent history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save visitor info')),
      );
    }
  }

  void _updateDoorbellState(int newState, String message) {
    FirebaseFirestore.instance.collection('doorbells').doc(doorbellId).update({
      'doorbellState': newState,
      'message': message,
    });
    if ((newState == 2 || newState == 3 || newState == 4)) {
      _saveToTodayHistory(constantImageUrl);
    }
    //no need for this now, as firebase is handling it (becuase state should change to 0 after x seconds even when app is closed)
    // if (newState == 2 || newState == 3 || newState == 4) {
    //   Timer(Duration(seconds: 7), () {
    //     FirebaseFirestore.instance
    //         .collection('doorbells')
    //         .doc(doorbellId)
    //         .update({
    //       'doorbellState': 0,
    //       'message': '',
    //     });
    //   });
    // }
  }

  // Replace _showMessageDialog with:
  Future<String?> _showMessageDialog(BuildContext context) {
    String message = '';
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a message'),
          content: TextField(
            onChanged: (value) => message = value,
            decoration: InputDecoration(
              hintText: 'Enter your message here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                  context, ''), // Return empty string for no message
              child: Text('No Message'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, message),
              child: Text('Send Message'),
            ),
          ],
        );
      },
    );
  }

  // Replace _onAccept and _onDeny with:
  void _onAccept() async {
    final message = await _showMessageDialog(context);
    if (message != null) {
      _updateDoorbellState(2, message);
    }
  }

  void _onDeny() async {
    final message = await _showMessageDialog(context);
    if (message != null) {
      _updateDoorbellState(3, message);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        Expanded(
          child: _isConnected
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
                          child:
                              Text("Doorbell ID: $doorbellId does not exist."));
                    }

                    int doorbellState = snapshot.data!['doorbellState'];
                    int isInDeadState = snapshot.data!['isInDeadState'];
                    String imageURL = snapshot.data!['imageURL'] ?? '';

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Replace the doorbellState == 1 block in _buildHomePage():
                        if (doorbellState == 1) ...[
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  size: 40,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Someone is at your door!",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: !_isConnected
                                        ? Image.asset(
                                            // '../../../../../assets/images/default.png',
                                            'default.png',
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                          )
                                        : imageURL.isNotEmpty
                                            ? GestureDetector(
                                                onTap: () => _showEnlargedImage(
                                                    context, imageURL),
                                                child: Image.network(
                                                  imageURL,
                                                  width: 150,
                                                  height: 150,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                      // '../../../../../assets/images/default.png',
                                                      'default.png',
                                                      width: 150,
                                                      height: 150,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                ),
                                              )
                                            : SizedBox(
                                                width: 150,
                                                height: 150,
                                                child: Placeholder(),
                                              ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: _onAccept,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check,
                                              color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            "Accept",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: _onDeny,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.close,
                                              color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            "Deny",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else if (doorbellState == 2) ...[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Access Granted!",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "The door is now unlocked",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ] else if (doorbellState == 3) ...[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.block_outlined,
                                size: 80,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Access Denied",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "The door remains locked",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ] else if (doorbellState == 4) ...[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_off_outlined,
                                size: 80,
                                color: Colors.orange,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Auto-Denied",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "No response within time limit",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                "The door remains locked",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.doorbell_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No one at the door",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "You will be notified when someone rings the bell",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                        // if (isInDeadState == 1) ...[
                        //   Spacer(),
                        //   Container(
                        //     color: Colors.red,
                        //     padding: EdgeInsets.all(16.0),
                        //     child: Center(
                        //       child: Text(
                        //         "Doorbell keypad locked, press the reset button",
                        //         style: TextStyle(color: Colors.white),
                        //       ),
                        //     ),
                        //   ),
                        // ],
                      ],
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please check your network settings',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Today's Visitors:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: _isConnected
              ? StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doorbells')
                      .doc(doorbellId)
                      .collection('today_history')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No visitors today'));
                    }

                    return Scrollbar(
                      thickness: 6.0, // Scrollbar width
                      radius: Radius.circular(3.0), // Rounded corners
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          DateTime date;
                          try {
                            var timestamp = doc['date'];
                            date = timestamp != null
                                ? (timestamp as Timestamp).toDate()
                                : DateTime.now();
                          } catch (e) {
                            date = DateTime.now();
                            print('Error parsing date: $e');
                          }
                          String imageUrl = doc['imageURL'];

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: !_isConnected
                                  ? Image.asset(
                                      // '../../../../../assets/images/default.png',
                                      'default.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : imageUrl.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () => _showEnlargedImage(
                                              context, imageUrl),
                                          child: Image.network(
                                            imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                // '../../../../../assets/images/default.png',
                                                'default.png',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(Icons.person),
                              title: Text(
                                'Visitor at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                              ),
                              subtitle: Text(
                                '${date.day}/${date.month}/${date.year}',
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.save),
                                onPressed: () =>
                                    _saveToPermHistory(constantImageUrl, date),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please check your network settings',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_selectedIndex) {
      case 0:
        currentPage = _buildHomePage();
        break;
      case 1:
        currentPage = HistoryPage(doorbellId: doorbellId);
        break;
      case 2:
        currentPage = ProfilePage(doorbellId: doorbellId);
        break;
      default:
        currentPage = Container();
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Smart doorbell, Hi! "),
      ),
      body: Stack(
        children: [
          currentPage,
          if (!_isConnected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "No internet connection",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isInDeadState == 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.red.withOpacity(0.5),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Doorbell keypad locked, press the reset button",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      //currentPage,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
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
