enum SmsQueueStatus {
  pending,
  sending,
  sent,
  failed,
}

class SmsQueueItem {
  final String id;
  final String message;
  final List<Map<String, String>> recipients; // List of {'name': ..., 'phoneNumber': ...}
  SmsQueueStatus status;
  final DateTime scheduledTime;
  DateTime? sentTime;
  String? errorMessage;

  SmsQueueItem({
    required this.id,
    required this.message,
    required this.recipients,
    this.status = SmsQueueStatus.pending,
    required this.scheduledTime,
    this.sentTime,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'recipients': recipients,
      'status': status.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'sentTime': sentTime?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory SmsQueueItem.fromJson(Map<String, dynamic> json) {
    return SmsQueueItem(
      id: json['id'] as String,
      message: json['message'] as String,
      recipients: (json['recipients'] as List)
          .map((item) => Map<String, String>.from(item as Map))
          .toList(),
      status: SmsQueueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SmsQueueStatus.pending,
      ),
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      sentTime: json['sentTime'] != null
          ? DateTime.parse(json['sentTime'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  SmsQueueItem copyWith({
    String? id,
    String? message,
    List<Map<String, String>>? recipients,
    SmsQueueStatus? status,
    DateTime? scheduledTime,
    DateTime? sentTime,
    String? errorMessage,
  }) {
    return SmsQueueItem(
      id: id ?? this.id,
      message: message ?? this.message,
      recipients: recipients ?? this.recipients,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      sentTime: sentTime ?? this.sentTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
