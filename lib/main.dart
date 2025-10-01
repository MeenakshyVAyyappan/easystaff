import 'package:flutter/material.dart';
import 'package:eazystaff/services/auth_service.dart';
import 'package:eazystaff/login.dart';
import 'package:eazystaff/home.dart'; // contains HomeScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.hydrate(); // load cached user if any
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final start = AuthService.currentUser == null ? '/login' : '/home';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: start,
      routes: {
        '/login': (context) => const LoginPage(),
        '/home':  (context) => const HomeScreen(),
      },
    );
  }
}
