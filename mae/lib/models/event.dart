class Event {
  final String name;
  final String organizer;
  final String date;
  final String time;
  final String location;
  final double fee;
  final String status;
  final String imageUrl;
  final String? details;
  final String? rejectionReason;
  bool isRegistered;

  Event({
    required this.name,
    required this.organizer,
    required this.date,
    required this.time,
    required this.location,
    required this.fee,
    required this.status,
    this.imageUrl = '',
    this.details,
    this.rejectionReason,
    this.isRegistered = false,
  });
}
