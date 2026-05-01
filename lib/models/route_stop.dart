// ─────────────────────────────────────────────
//  RouteStop model – one station in train route
// ─────────────────────────────────────────────
class RouteStop {
  final int? id;
  final String trainNo;
  final String stationName;
  final String arrival;
  final String departure;
  final int stopNumber;

  RouteStop({
    this.id,
    required this.trainNo,
    required this.stationName,
    required this.arrival,
    required this.departure,
    required this.stopNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'train_no': trainNo,
      'station_name': stationName,
      'arrival': arrival,
      'departure': departure,
      'stop_number': stopNumber,
    };
  }

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      id: map['id'],
      trainNo: map['train_no'],
      stationName: map['station_name'],
      arrival: map['arrival'],
      departure: map['departure'],
      stopNumber: map['stop_number'],
    );
  }
}
