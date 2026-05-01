// ─────────────────────────────────────────────
//  SeatAvailability model – seats for one train/date
// ─────────────────────────────────────────────
class SeatAvailability {
  final int? id;
  final String trainNo;
  final String date; // "yyyy-MM-dd"
  final int sleeper;
  final int ac3;
  final int ac2;
  final int ac1;

  SeatAvailability({
    this.id,
    required this.trainNo,
    required this.date,
    required this.sleeper,
    required this.ac3,
    required this.ac2,
    required this.ac1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'train_no': trainNo,
      'date': date,
      'sleeper': sleeper,
      'ac3': ac3,
      'ac2': ac2,
      'ac1': ac1,
    };
  }

  factory SeatAvailability.fromMap(Map<String, dynamic> map) {
    return SeatAvailability(
      id: map['id'],
      trainNo: map['train_no'],
      date: map['date'],
      sleeper: map['sleeper'],
      ac3: map['ac3'],
      ac2: map['ac2'],
      ac1: map['ac1'],
    );
  }
}
