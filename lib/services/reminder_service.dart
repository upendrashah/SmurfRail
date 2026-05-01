import 'dart:async';

import '../database/database_helper.dart';
import '../models/seat_availability.dart';
import 'notification_service.dart';

class SeatThresholdReminder {
  final String trainNo;
  final String date;
  final int threshold;

  SeatThresholdReminder({
    required this.trainNo,
    required this.date,
    required this.threshold,
  });
}

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final List<SeatThresholdReminder> _thresholdReminders = [];
  Timer? _pollingTimer;

  void startSeatPollingSimulation() {
    _pollingTimer?.cancel();

    // Every 30 minutes: simulate seat changes and check alerts.
    _pollingTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      await DatabaseHelper.instance.decreaseSeatsSlightlyForSimulation();
      await _checkThresholdReminders();
    });
  }

  void addThresholdReminder({
    required String trainNo,
    required String date,
    required int threshold,
  }) {
    _thresholdReminders.add(
      SeatThresholdReminder(
        trainNo: trainNo,
        date: date,
        threshold: threshold,
      ),
    );
  }

  Future<void> triggerTimeReminderAfter({
    required Duration duration,
    required String trainName,
    required String trainNo,
  }) async {
    Timer(duration, () async {
      await NotificationService.instance.showSimpleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Train Reminder',
        body: 'Reminder for $trainName ($trainNo)',
      );
    });
  }

  Future<void> _checkThresholdReminders() async {
    for (final reminder in _thresholdReminders) {
      final SeatAvailability? seats = await DatabaseHelper.instance
          .getSeatAvailability(reminder.trainNo, reminder.date);

      if (seats == null) continue;

      final minSeat = [seats.sleeper, seats.ac3, seats.ac2, seats.ac1]
          .reduce((a, b) => a < b ? a : b);

      if (minSeat < reminder.threshold) {
        await NotificationService.instance.showSimpleNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Seat Alert: ${reminder.trainNo}',
          body: 'Seats dropped below ${reminder.threshold}. Lowest now: $minSeat',
        );
      }
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
