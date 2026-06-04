import 'package:flutter/material.dart';
import '../models/sms_queue_item.dart';

class ScheduledList extends StatelessWidget {
  final List<SmsQueueItem> items;
  final Function(String taskId) onCancel;

  const ScheduledList({
    super.key,
    required this.items,
    required this.onCancel,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final String month = months[dt.month - 1];
    final String day = dt.day.toString().padLeft(2, '0');
    final String hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month ${dt.year} at $hour:$minute $ampm';
  }

  String _getRecipientsSummary(List<Map<String, String>> recipients) {
    if (recipients.isEmpty) return 'No recipients';
    final names = recipients.map((r) => r['name'] ?? 'Unknown').toList();
    if (names.length <= 2) {
      return names.join(', ');
    }
    return '${names.sublist(0, 2).join(', ')} + ${names.length - 2} more';
  }

  String _getRemainingTime(DateTime scheduledTime) {
    final difference = scheduledTime.difference(DateTime.now());
    if (difference.isNegative) {
      return 'Sending momentarily...';
    }
    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day(s) ${difference.inHours % 24} hr(s)';
    }
    if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour(s) ${difference.inMinutes % 60} min(s)';
    }
    if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute(s)';
    }
    return 'in ${difference.inSeconds} second(s)';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alarm_on,
                  color: Colors.indigo,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Scheduled Messages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Plan ahead! Select contacts and schedule messages to be sent even when the app is closed.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Status & Time Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty, size: 14, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Scheduled',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _getRemainingTime(item.scheduledTime),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Recipients summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getRecipientsSummary(item.recipients),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Message block with nice styling
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Footer details & actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled for',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(item.scheduledTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => onCancel(item.id),
                      icon: const Icon(Icons.cancel, size: 14),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
