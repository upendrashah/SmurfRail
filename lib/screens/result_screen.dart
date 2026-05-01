import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/seat_availability.dart';
import '../models/train.dart';
import '../widgets/train_card.dart';
import 'detail_screen.dart';

class ResultScreen extends StatefulWidget {
  final String destinationQuery;
  final String date;
  final String? trainNo;

  const ResultScreen({
    super.key,
    required this.destinationQuery,
    required this.date,
    this.trainNo,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  List<Train> _trains = [];
  final Map<String, SeatAvailability?> _seatMap = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
    });

    final trains = await DatabaseHelper.instance.searchTrainsSmart(
      destination: widget.destinationQuery,
      trainNo: widget.trainNo,
    );

    final seatMap = <String, SeatAvailability?>{};
    for (final train in trains) {
      final seats = await DatabaseHelper.instance
          .getSeatAvailability(train.trainNo, widget.date);
      seatMap[train.trainNo] = seats;
    }

    if (!mounted) return;

    setState(() {
      _trains = trains;
      _seatMap
        ..clear()
        ..addAll(seatMap);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Results'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trains.isEmpty
              ? const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _trains.length,
                  itemBuilder: (context, index) {
                    final train = _trains[index];
                    final seats = _seatMap[train.trainNo];

                    return TrainCard(
                      train: train,
                      seats: seats,
                      destinationQuery: widget.destinationQuery,
                      trainNoQuery: widget.trainNo ?? '',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              train: train,
                              date: widget.date,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
