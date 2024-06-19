import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heart Beat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'CustomFont',
      ),
      home: AppLaunchScreen(),
    );
  }
}

class AppLaunchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/heart.png'),
            const SizedBox(height: 20),
            const Text(
              'HEART BEAT',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Save your heart. Save your life',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppResultsScreen()),
                );
              },
              child: const Text('CHECK'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppResultsScreen extends StatefulWidget {
  @override
  _AppResultsScreenState createState() => _AppResultsScreenState();
}

class _AppResultsScreenState extends State<AppResultsScreen> {
  String result = "Fetching data...";

  @override
  void initState() {
    super.initState();
    fetchDataAndSendToModel();
  }

  Future<void> fetchDataAndSendToModel() async {
    try {
      // Fetch last 50 sensor data entries from Firebase Realtime Database
      DatabaseReference ref = FirebaseDatabase.instance.ref('ecgValue');
      DatabaseEvent event = await ref.orderByKey().limitToLast(50).once();

      List<double> sensorData = [];
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values = event.snapshot.value as Map;
        for (var value in values.values) {
          sensorData.add(double.tryParse(value['heart_rate'].toString()) ?? 0);
          sensorData.add(double.tryParse(value['pr_interval'].toString()) ?? 0);
          sensorData
              .add(double.tryParse(value['qrs_duration'].toString()) ?? 0);
          sensorData.add(double.tryParse(value['qt_interval'].toString()) ?? 0);
          sensorData.add(double.tryParse(value['st_segment'].toString()) ?? 0);
          sensorData.add(double.tryParse(value['t_wave'].toString()) ?? 0);
        }

        // Ensure we have exactly 50 samples
        if (sensorData.length > 50) {
          sensorData = sensorData.sublist(sensorData.length - 50);
        } else if (sensorData.length < 50) {
          throw Exception(
              'Not enough data: ${sensorData.length} samples found');
        }
      }

      // Debug: Print the data being sent to the model
      print("Data sent to model: $sensorData");

      // Send data to the model and get response
      String response = await sendDataToModel(sensorData);

      // Debug: Print the model response
      print("Model response: $response");

      // Update the state with the response
      setState(() {
        result = parseResponse(response);
      });
    } catch (e) {
      setState(() {
        result = "Error fetching data: $e";
      });
    }
  }

  String parseResponse(String response) {
    switch (response) {
      case 'Class1':
        return "NORMAL HEART RATE";
      case 'Class2':
        return "LBBB";
      case 'Class3':
        return "RBBB";
      case 'Class4':
        return "APB";
      case 'Class5':
        return "VPB";
      default:
        return "UNKNOWN";
    }
  }

  Future<String> sendDataToModel(List<double> data) async {
    final url = 'https://e560-156-221-36-232.ngrok-free.app/upload';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': data}),
      );

      // Debug: Print the response status and body
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body).toString();
      } else {
        throw Exception('Failed to load model response');
      }
    } catch (e) {
      throw Exception('Failed to send data to model: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Lottie.asset(
              'assets/beat.json',
              height: 300,
              width: double.infinity,
            ),
            const SizedBox(height: 20),
            const Text(
              'THE RESULT IS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result,
              style: TextStyle(
                fontSize: 24,
                color:
                    result == "NORMAL HEART RATE" ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: fetchDataAndSendToModel,
              child: const Text('CHECK AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
