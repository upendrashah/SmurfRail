// ─────────────────────────────────────────────
//  Train model – represents one train entry
// ─────────────────────────────────────────────
class Train {
  final int? id;
  final String trainNo;
  final String trainName;
  final String source;
  final String destination;
  final String departure; // "HH:MM"
  final String arrival;   // "HH:MM"

  Train({
    this.id,
    required this.trainNo,
    required this.trainName,
    required this.source,
    required this.destination,
    required this.departure,
    required this.arrival,
  });

  // Convert a Train object → Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'train_no': trainNo,
      'train_name': trainName,
      'source': source,
      'destination': destination,
      'departure': departure,
      'arrival': arrival,
    };
  }

  // Convert a SQLite Map → Train object
  factory Train.fromMap(Map<String, dynamic> map) {
    return Train(
      id: map['id'],
      trainNo: map['train_no'],
      trainName: map['train_name'],
      source: map['source'],
      destination: map['destination'],
      departure: map['departure'],
      arrival: map['arrival'],
    );
  }
}
