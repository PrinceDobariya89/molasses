import 'package:flutter/material.dart';
import '../models/sms_queue_item.dart';

class HistoryList extends StatelessWidget {
  final List<SmsQueueItem> items;

  const HistoryList({
    super.key,
    required this.items,
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
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_toggle_off,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Sending History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent campaigns and background delivery reports will appear here once executed.',
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

    // Calculate metrics
    final totalCampaigns = items.length;
    final totalSentSms = items.fold<int>(0, (sum, item) => sum + item.recipients.length);
    final successfulCampaigns = items.where((e) => e.status == SmsQueueStatus.sent).length;
    final double successRate = totalCampaigns == 0
        ? 0
        : (successfulCampaigns / totalCampaigns) * 100;

    return CustomScrollView(
      slivers: [
        // Premium Metrics Dashboard Card
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade800, Colors.deepPurple.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Campaigns', totalCampaigns.toString()),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatColumn('Total SMS', totalSentSms.toString()),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatColumn('Success', '${successRate.toStringAsFixed(0)}%'),
              ],
            ),
          ),
        ),
        // History List Items
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              final isSuccess = item.status == SmsQueueStatus.sent;

              return Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
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
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSuccess ? Icons.check_circle : Icons.error_outline,
                                  size: 14,
                                  color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSuccess ? 'Sent' : 'Failed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item.sentTime != null
                                ? _formatDateTime(item.sentTime!)
                                : _formatDateTime(item.scheduledTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
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
                      // Message block
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
                      // Error details if failed
                      if (!isSuccess && item.errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning, size: 14, color: Colors.red.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            childCount: items.length,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
