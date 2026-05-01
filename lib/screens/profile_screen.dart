import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  final String email;

  const ProfileScreen({
    super.key,
    required this.email,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await DatabaseHelper.instance.getUserByEmail(widget.email);
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('User profile not found'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Account Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Name: ${_user!['name']}'),
                          const SizedBox(height: 8),
                          Text('Email: ${_user!['email']}'),
                          const SizedBox(height: 8),
                          Text('User ID: ${_user!['id']}'),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
