import 'package:flutter/material.dart';
import 'package:adwaita/adwaita.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jig/auth.dart';

void main() {
  runApp(const JigApp());
}

class JigApp extends StatelessWidget {
  const JigApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Jig', theme: AdwaitaThemeData.dark(), home: const AuthPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? accessToken;
  String? instance;

  void loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      accessToken = prefs.getString("accessToken");
      instance = prefs.getString("instance");
    });

    if (accessToken == null) {
      //Navigator.of(context).push();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Jig")), body: Center());
  }
}
