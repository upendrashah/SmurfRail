import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import 'login.dart';
import 'profile_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _destinationController = TextEditingController();
  final _trainNoController = TextEditingController();
  final List<String> _destinationSuggestions = [];
  List<String> _lastSearched = [];

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLastSearched();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _trainNoController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSearched() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('last_searched_trains') ?? [];
    if (!mounted) return;
    setState(() {
      _lastSearched = items;
    });
  }

  Future<void> _saveLastSearch({
    required String destination,
    required String trainNo,
  }) async {
    final value = trainNo.isNotEmpty ? 'Train No: $trainNo' : 'Destination: $destination';

    final updated = <String>[value, ..._lastSearched.where((v) => v != value)];
    if (updated.length > 5) {
      updated.removeRange(5, updated.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('last_searched_trains', updated);

    if (!mounted) return;
    setState(() {
      _lastSearched = updated;
    });
  }

  Future<void> _onDestinationChanged(String value) async {
    // If user is using train number exact search, skip suggestions.
    if (_trainNoController.text.trim().isNotEmpty) {
      setState(() {
        _destinationSuggestions.clear();
      });
      return;
    }

    final suggestions = await DatabaseHelper.instance
        .getDestinationSuggestions(value);
    if (!mounted) return;

    setState(() {
      _destinationSuggestions
        ..clear()
        ..addAll(suggestions);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_email');
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(email: widget.userEmail),
      ),
    );
  }

  void _search() {
    final destination = _destinationController.text.trim();
    final trainNo = _trainNoController.text.trim();

    if (destination.isEmpty && trainNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter destination or train number')),
      );
      return;
    }

    _saveLastSearch(destination: destination, trainNo: trainNo);

    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          destinationQuery: destination,
          date: date,
          trainNo: trainNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Train Search (${widget.userEmail})'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _destinationController,
                      onChanged: _onDestinationChanged,
                      decoration: const InputDecoration(
                        labelText: 'Destination (Autocomplete)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_destinationSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ListView.builder(
                          itemCount: _destinationSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _destinationSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(suggestion),
                              onTap: () {
                                setState(() {
                                  _destinationController.text = suggestion;
                                  _destinationSuggestions.clear();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _trainNoController,
                      onChanged: (_) => _onDestinationChanged(
                        _destinationController.text,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Train Number (Exact Search)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Journey Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _search,
                        icon: const Icon(Icons.search),
                        label: const Text('Search Trains'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_lastSearched.isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Searched',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _lastSearched
                            .map((item) => Chip(label: Text(item)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
