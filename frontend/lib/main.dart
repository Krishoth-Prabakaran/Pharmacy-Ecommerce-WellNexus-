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

/// AuthWrapper handles the initial routing based on:
/// 1. User login status (token exists)
/// 2. User role (patient, doctor, pharmacist)
/// 3. For patients: checks if they've completed their profile
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        // Show loading indicator while checking login status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // User is logged in - check their data and role
        if (snapshot.data == true) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService.getUserData(),
            builder: (context, userSnapshot) {
              // Show loading while fetching user data
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final userData = userSnapshot.data;
              
              // Handle PATIENT role - check if they have completed profile
              if (userData != null && userData['role'] == 'patient') {
                final userId = userData['user_id']; // Get user_id from stored data
                
                return FutureBuilder<bool>(
                  // FIXED: Pass userId instead of email to match backend
                  future: PatientService().hasPatientDetails(userId),
                  builder: (context, detailsSnapshot) {
                    // Show loading while checking patient details
                    if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    // If patient has details, go to dashboard, otherwise show registration form
                    if (detailsSnapshot.data == true) {
                      return const DashboardScreen();
                    } else {
                      return PatientRegisterScreen(userData: userData);
                    }
                  },
                );
              }
              
              // For other roles (doctor, pharmacist) go directly to dashboard
              return const DashboardScreen();
            },
          );
        }
        
        // User not logged in - show login screen
        return const LoginScreen();
      },
    );
  }
}