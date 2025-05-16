import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  final Color primary = const Color(0xffeef444c);

  // Store selected date as year + month, not just month string
  DateTime _selectedMonth = DateTime.now();

  // Mutable attendance data list
  List<Map<String, dynamic>> attendanceData = [
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'checkIn': '09:00 AM',
      'checkOut': '05:00 PM',
    },
    {
      'date': DateTime.now(),
      'checkIn': '09:15 AM',
      'checkOut': '05:30 PM',
    },
  ];

  // Method to update or add attendance record
  void updateAttendance(DateTime date, String checkIn, String checkOut) {
    setState(() {
      int index = attendanceData.indexWhere((rec) =>
      rec['date'].year == date.year &&
          rec['date'].month == date.month &&
          rec['date'].day == date.day);

      if (index != -1) {
        attendanceData[index]['checkIn'] = checkIn;
        attendanceData[index]['checkOut'] = checkOut;
      } else {
        attendanceData.add({
          'date': date,
          'checkIn': checkIn,
          'checkOut': checkOut,
        });
      }
    });
  }

  Future<void> _refreshData() async {
    // Simulate data fetch or reload here
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // If you want to reload real data, do it here.
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    String monthYearLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    // Filter attendance data for the selected month and year
    List<Map<String, dynamic>> filteredData = attendanceData
        .where((rec) =>
    rec['date'].year == _selectedMonth.year &&
        rec['date'].month == _selectedMonth.month)
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 32),
                child: Text(
                  "My Attendance",
                  style: TextStyle(
                    fontFamily: "NexaBold",
                    fontSize: screenWidth / 18,
                  ),
                ),
              ),
              Stack(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 32),
                    child: Text(
                      monthYearLabel,
                      style: TextStyle(
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 18,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.only(top: 32),
                    child: GestureDetector(
                      onTap: () async {
                        final month = await showMonthYearPicker(
                          context: context,
                          initialDate: _selectedMonth,
                          firstDate: DateTime(2022),
                          lastDate: DateTime(2099),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: primary,
                                  secondary: primary,
                                  onSecondary: Colors.white,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: primary,
                                  ),
                                ),
                                textTheme: const TextTheme(
                                  headlineMedium: TextStyle(
                                    fontFamily: "NexaBold",
                                  ),
                                  labelLarge: TextStyle(
                                    fontFamily: "NexaBold",
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (month != null) {
                          setState(() {
                            _selectedMonth = month;
                          });
                        }
                      },
                      child: Text(
                        "Pick a Month",
                        style: TextStyle(
                          fontFamily: "NexaBold",
                          fontSize: screenWidth / 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: screenHeight / 1.45,
                child: filteredData.isEmpty
                    ? Center(
                  child: Text(
                    "No attendance records for this month",
                    style: TextStyle(
                      fontFamily: "NexaRegular",
                      fontSize: screenWidth / 22,
                      color: Colors.black54,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final record = filteredData[index];
                    return Container(
                      margin: EdgeInsets.only(
                          top: index > 0 ? 12 : 0, left: 6, right: 6),
                      height: 150,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(2, 2),
                          ),
                        ],
                        borderRadius:
                        BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(20)),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('EE\ndd').format(record['date']),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "NexaBold",
                                    fontSize: screenWidth / 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Check In",
                                  style: TextStyle(
                                    fontFamily: "NexaRegular",
                                    fontSize: screenWidth / 20,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  record['checkIn'],
                                  style: TextStyle(
                                    fontFamily: "NexaBold",
                                    fontSize: screenWidth / 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Check Out",
                                  style: TextStyle(
                                    fontFamily: "NexaRegular",
                                    fontSize: screenWidth / 20,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  record['checkOut'],
                                  style: TextStyle(
                                    fontFamily: "NexaBold",
                                    fontSize: screenWidth / 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
