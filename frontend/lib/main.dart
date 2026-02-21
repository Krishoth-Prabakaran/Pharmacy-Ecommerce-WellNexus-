import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp()); // Added const here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Added const constructor with key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WellNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(), // Added const
        '/register': (context) => const RegisterScreen(), // Added const
        '/dashboard': (context) => const DashboardScreen(), // Added const
      },
    );
  }
}

// Dashboard Screen with const constructor
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key}); // Added const constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'), // Added const
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Added const
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<String?>(
          future: AuthService.getUserRole(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon( // Added const
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                  const SizedBox(height: 20), // Added const
                  const Text( // Added const
                    'Welcome to WellNexus!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10), // Added const
                  Text(
                    'Logged in as: ${snapshot.data}',
                    style: const TextStyle( // Added const
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            }
            return const CircularProgressIndicator(); // Added const
          },
        ),
      ),
    );
  }
}