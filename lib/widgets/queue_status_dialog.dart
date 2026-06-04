import 'package:flutter/material.dart';

class QueueProgress {
  final int sentCount;
  final int total;
  final String currentRecipientName;
  final bool isCompleted;
  final String? errorMessage;

  QueueProgress({
    required this.sentCount,
    required this.total,
    required this.currentRecipientName,
    required this.isCompleted,
    this.errorMessage,
  });

  double get percent => total == 0 ? 0.0 : sentCount / total;
}

class QueueStatusDialog extends StatelessWidget {
  final ValueNotifier<QueueProgress> progressNotifier;

  const QueueStatusDialog({
    super.key,
    required this.progressNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      child: ValueListenableBuilder<QueueProgress>(
        valueListenable: progressNotifier,
        builder: (context, progress, child) {
          final isDone = progress.isCompleted;
          final isFailed = progress.errorMessage != null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header with circular background
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDone
                        ? (isFailed ? Colors.red.shade50 : Colors.green.shade50)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(
                            isFailed ? Icons.error_outline : Icons.check_circle_outline,
                            color: isFailed ? Colors.red : Colors.green,
                            size: 40,
                          )
                        : CircularProgressIndicator(
                            value: progress.percent,
                            strokeWidth: 4,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  isDone
                      ? (isFailed ? 'Campaign Failed' : 'Campaign Completed!')
                      : 'Sending SMS Campaign...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Description/Status
                Text(
                  isDone
                      ? (isFailed
                          ? '${progress.errorMessage}'
                          : 'Successfully sent message to all ${progress.total} recipients.')
                      : 'Sending to: ${progress.currentRecipientName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Progress count text and bar
                if (!isDone) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${progress.sentCount}/${progress.total}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.percent,
                      minHeight: 8,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                if (isDone) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
