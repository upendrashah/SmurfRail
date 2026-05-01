import 'package:flutter/material.dart';

import '../models/seat_availability.dart';
import '../models/train.dart';

class TrainCard extends StatelessWidget {
  final Train train;
  final SeatAvailability? seats;
  final String destinationQuery;
  final String trainNoQuery;
  final VoidCallback onTap;

  const TrainCard({
    super.key,
    required this.train,
    required this.seats,
    required this.destinationQuery,
    required this.trainNoQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrainTitle(),
              const SizedBox(height: 6),
              _buildRouteText(),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('Dep: ${train.departure}')),
                  Expanded(child: Text('Arr: ${train.arrival}')),
                ],
              ),
              const Divider(height: 20),
              if (seats == null)
                const Text('No seat data available')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _seatChip('Sleeper', seats!.sleeper),
                    _seatChip('3AC', seats!.ac3),
                    _seatChip('2AC', seats!.ac2),
                    _seatChip('1AC', seats!.ac1),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seatChip(String label, int count) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: count < 10 ? Colors.red.shade100 : Colors.green.shade100,
    );
  }

  Widget _buildTrainTitle() {
    final query = trainNoQuery.trim();
    final baseStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: Colors.yellow.shade300,
      color: Colors.black,
    );

    if (query.isNotEmpty && train.trainNo == query) {
      return RichText(
        text: TextSpan(
          style: baseStyle.copyWith(color: Colors.black),
          children: [
            TextSpan(text: '${train.trainName} ('),
            TextSpan(text: train.trainNo, style: highlightStyle),
            const TextSpan(text: ')'),
          ],
        ),
      );
    }

    return Text('${train.trainName} (${train.trainNo})', style: baseStyle);
  }

  Widget _buildRouteText() {
    final query = destinationQuery.trim().toLowerCase();
    final routeText = '${train.source} -> ${train.destination}';

    if (query.isEmpty) {
      return Text(routeText);
    }

    final destinationLower = train.destination.toLowerCase();
    final idx = destinationLower.indexOf(query);
    if (idx < 0) {
      return Text(routeText);
    }

    final before = train.destination.substring(0, idx);
    final match = train.destination.substring(idx, idx + query.length);
    final after = train.destination.substring(idx + query.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87),
        children: [
          TextSpan(text: '${train.source} -> '),
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor: Colors.yellow.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
