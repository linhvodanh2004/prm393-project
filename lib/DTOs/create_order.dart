class CreateOrder {
  final String userId;
  final String employeeId;
  final DateTime timeUsed;
  final String roomId;
  final bool isDone;
  final DateTime createAt;
  final bool isDeleted;

  CreateOrder({
    required this.userId,
    required this.employeeId,
    required this.timeUsed,
    required this.roomId,
    this.isDone = false,
    DateTime? createAt,
    this.isDeleted = false,
  }) : createAt = createAt ?? DateTime.now();

  String validate() {
    if (userId.trim().isEmpty) {
      return 'User ID is required';
    }
    if (employeeId.trim().isEmpty) {
      return 'Employee ID is required';
    }
    if (roomId.trim().isEmpty) {
      return 'Room ID is required';
    }
    if (timeUsed.isBefore(DateTime.now())) {
      return 'Time used must be in the future';
    }
    return ''; // No errors
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'employeeId': employeeId,
      'timeUsed': timeUsed,
      'roomId': roomId,
      'isDone': isDone,
      'createAt': createAt,
      'isDeleted': isDeleted,
    };
  }

  CreateOrder copyWith({
    String? userId,
    String? employeeId,
    DateTime? timeUsed,
    String? roomId,
    bool? isDone,
    DateTime? createAt,
    bool? isDeleted,
  }) {
    return CreateOrder(
      userId: userId ?? this.userId,
      employeeId: employeeId ?? this.employeeId,
      timeUsed: timeUsed ?? this.timeUsed,
      roomId: roomId ?? this.roomId,
      isDone: isDone ?? this.isDone,
      createAt: createAt ?? this.createAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
