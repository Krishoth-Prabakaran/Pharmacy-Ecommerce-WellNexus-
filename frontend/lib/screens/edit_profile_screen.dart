import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final dynamic currentProfile;
  final VoidCallback? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    this.userData,
    this.currentProfile,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: const Center(
        child: Text('Edit Profile Screen'),
      ),
    );
  }
}
