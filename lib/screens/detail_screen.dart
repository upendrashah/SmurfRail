import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/route_stop.dart';
import '../models/seat_availability.dart';
import '../models/train.dart';
import '../services/reminder_service.dart';

class DetailScreen extends StatefulWidget {
  final Train train;
  final String date;

  const DetailScreen({
    super.key,
    required this.train,
    required this.date,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isLoading = true;
  List<RouteStop> _route = [];
  SeatAvailability? _seats;

  final _thresholdController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final route = await DatabaseHelper.instance.getRouteByTrainNo(widget.train.trainNo);
    final seats = await DatabaseHelper.instance
        .getSeatAvailability(widget.train.trainNo, widget.date);

    if (!mounted) return;
    setState(() {
      _route = route;
      _seats = seats;
      _isLoading = false;
    });
  }

  void _setQuickReminder(Duration duration, String label) {
    ReminderService.instance.triggerTimeReminderAfter(
      duration: duration,
      trainName: widget.train.trainName,
      trainNo: widget.train.trainNo,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $label')),
    );
  }

  void _setThresholdReminder() {
    final threshold = int.tryParse(_thresholdController.text.trim());
    if (threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid threshold number')),
      );
      return;
    }

    ReminderService.instance.addThresholdReminder(
      trainNo: widget.train.trainNo,
      date: widget.date,
      threshold: threshold,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Seat threshold alert set: <$threshold')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.train.trainName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.train.trainName} (${widget.train.trainNo})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${widget.train.source} -> ${widget.train.destination}'),
                          Text('Departure: ${widget.train.departure} | Arrival: ${widget.train.arrival}'),
                          Text('Date: ${widget.date}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Seat Availability',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _seats == null
                          ? const Text('No seat information available')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sleeper: ${_seats!.sleeper}'),
                                Text('3AC: ${_seats!.ac3}'),
                                Text('2AC: ${_seats!.ac2}'),
                                Text('1AC: ${_seats!.ac1}'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Full Route',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.separated(
                      itemCount: _route.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final stop = _route[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text('${stop.stopNumber}'),
                          ),
                          title: Text(stop.stationName),
                          subtitle: Text('Arr: ${stop.arrival}  |  Dep: ${stop.departure}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Set Reminder',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton(
                                onPressed: () => _setQuickReminder(
                                  const Duration(hours: 1),
                                  '1 hour',
                                ),
                                child: const Text('After 1 Hour'),
                              ),
                              ElevatedButton(
                                onPressed: () => _setQuickReminder(
                                  const Duration(hours: 2),
                                  '2 hours',
                                ),
                                child: const Text('After 2 Hours'),
                              ),
                              ElevatedButton(
                                onPressed: () => _setQuickReminder(
                                  const Duration(days: 1),
                                  '1 day',
                                ),
                                child: const Text('After 1 Day'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _thresholdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Alert if seats below threshold',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _setThresholdReminder,
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('Set Seat Threshold Alert'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
