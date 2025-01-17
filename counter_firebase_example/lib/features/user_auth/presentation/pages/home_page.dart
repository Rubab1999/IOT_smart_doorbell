import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'dart:async';
import 'history_page.dart';

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
  Timer? _timer;

  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
          imageURL = snapshot['imageURL'] ?? '';
        });
        if (doorbellState == 1) {
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 30), () {
      if (doorbellState == 1) {
        _updateDoorbellState(4);
      }
    });
  }

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
      final existingDocs = await FirebaseFirestore.instance
          .collection('doorbells')
          .doc(doorbellId)
          .collection('perm_history')
          .where('imageURL', isEqualTo: imageURL)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image already saved in history')),
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
        SnackBar(content: Text('Image saved to history')),
      );
    } catch (e) {
      print('Error saving to permanent history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image')),
      );
    }
  }

  void _updateDoorbellState(int newState) {
    FirebaseFirestore.instance
        .collection('doorbells')
        .doc(doorbellId)
        .update({'doorbellState': newState});

    if ((newState == 2 || newState == 3 || newState == 4) &&
        imageURL.isNotEmpty) {
      _saveToTodayHistory(imageURL);
    }

    if (newState == 2 || newState == 3 || newState == 4) {
      Timer(Duration(seconds: 7), () {
        FirebaseFirestore.instance
            .collection('doorbells')
            .doc(doorbellId)
            .update({'doorbellState': 0});
      });
    }
  }

  void _onAccept() {
    _updateDoorbellState(2);
  }

  void _onDeny() {
    _updateDoorbellState(3);
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
          child: StreamBuilder<DocumentSnapshot>(
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
                              child: imageURL.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () =>
                                          _showEnlargedImage(context, imageURL),
                                      child: Image.network(
                                        imageURL,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
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
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _onAccept,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, color: Colors.white),
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
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _onDeny,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.close, color: Colors.white),
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
          child: StreamBuilder<QuerySnapshot>(
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
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? GestureDetector(
                                onTap: () =>
                                    _showEnlargedImage(context, imageUrl),
                                child: Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
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
                          onPressed: () => _saveToPermHistory(imageUrl, date),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
        title: Text("Smart doorbell"),
      ),
      body: currentPage,
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
