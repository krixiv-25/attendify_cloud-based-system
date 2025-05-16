import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginScreen.dart';
import 'dart:async';

class TodayScreen extends StatefulWidget {
  final VoidCallback? onCheckInOutChanged;

  const TodayScreen({Key? key, this.onCheckInOutChanged}) : super(key: key);

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  String checkInTime = "--/--";
  String checkOutTime = "--/--";
  String currentTime = "";
  bool isCheckedOut = false;
  late Timer timer;
  final GlobalKey<SlideActionState> slideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCheckInData();
    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    });
  }

  Future<void> _loadCheckInData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checkInTime = prefs.getString('checkInTime') ?? "--/--";
      checkOutTime = prefs.getString('checkOutTime') ?? "--/--";
      isCheckedOut = prefs.getBool('isCheckedOut') ?? false;
    });
  }

  Future<void> _handleSlideAction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String now = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      if (checkInTime == "--/--") {
        checkInTime = now;
        prefs.setString('checkInTime', checkInTime);
      } else {
        checkOutTime = now;
        isCheckedOut = true;
        prefs.setString('checkOutTime', checkOutTime);
        prefs.setBool('isCheckedOut', true);
      }
    });

    // Notify parent or listener about change
    if (widget.onCheckInOutChanged != null) {
      widget.onCheckInOutChanged!();
    }

    await Future.delayed(const Duration(milliseconds: 600));
    slideKey.currentState?.reset();
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('checkInTime');
    await prefs.remove('checkOutTime');
    await prefs.remove('isCheckedOut');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Today"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Welcome 👋",
              style: TextStyle(
                fontSize: screenWidth / 14,
                fontWeight: FontWeight.bold,
                fontFamily: "NexaBold",
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              currentTime,
              style: TextStyle(
                fontSize: screenWidth / 10,
                fontFamily: "NexaBold",
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Check-In: $checkInTime",
                    style: TextStyle(
                      fontSize: screenWidth / 20,
                      fontFamily: "NexaBold",
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Check-Out: $checkOutTime",
                    style: TextStyle(
                      fontSize: screenWidth / 20,
                      fontFamily: "NexaBold",
                      color: Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            if (!isCheckedOut)
              SlideAction(
                key: slideKey,
                text: checkInTime == "--/--"
                    ? "Slide to Check In"
                    : "Slide to Check Out",
                textStyle: TextStyle(
                  fontSize: screenWidth / 22,
                  fontFamily: "NexaBold",
                  color: Colors.black,
                ),
                outerColor:
                checkInTime == "--/--" ? Colors.green : Colors.red,
                innerColor: Colors.white,
                sliderButtonIcon: Icon(
                  checkInTime == "--/--" ? Icons.login : Icons.logout,
                  color: Colors.black,
                ),
                onSubmit: _handleSlideAction,
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF087F23)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade900.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(4, 4),
                    ),
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.6),
                      blurRadius: 6,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    "Done for Today!",
                    style: TextStyle(
                      fontSize: screenWidth / 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: "NexaBold",
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
