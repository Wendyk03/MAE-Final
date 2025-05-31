import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_page.dart';
import 'screens/home_screen_na.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EventApp());
}

class EventApp extends StatefulWidget {
  const EventApp({Key? key}) : super(key: key);

  @override
  State<EventApp> createState() => _EventAppState();
}

class _EventAppState extends State<EventApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APU Event App',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const HomePage(),
      routes: {
        '/admin-sign-in':
            (context) => AdminHomeScreen(
              toggleTheme: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
              isDarkMode: isDarkMode,
              initialTabIndex: 0,
            ),
        '/sign-in': (context) => SigninScreen(),
        '/sign-up': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/admin-home':
            (context) => AdminHomeScreen(
              toggleTheme: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
              isDarkMode: isDarkMode,
              initialTabIndex: 0,
            ),
        '/home':
            (context) => HomeScreen(
              toggleTheme: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
              isDarkMode: isDarkMode,
            ),
        '/home-na':
            (context) => HomeScreenNA(
              toggleTheme: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
              isDarkMode: isDarkMode,
            ),
      },
    );
  }
}
