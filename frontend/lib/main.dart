import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/patient_register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/patient_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.data == true) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService.getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final userData = userSnapshot.data;
              if (userData != null && userData['role'] == 'patient') {
                return FutureBuilder<bool>(
                  future: PatientService().hasPatientDetails(userData['email'] ?? ''),
                  builder: (context, detailsSnapshot) {
                    if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (detailsSnapshot.data == true) {
                      return const DashboardScreen();
                    } else {
                      return PatientRegisterScreen(userData: userData);
                    }
                  },
                );
              }
              
              return const DashboardScreen();
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}