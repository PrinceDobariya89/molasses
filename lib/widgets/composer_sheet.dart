import 'package:flutter/material.dart';
import '../models/contact_model.dart';

class ComposerSheet extends StatefulWidget {
  final List<ContactModel> selectedContacts;
  final Function(ContactModel) onRemoveContact;
  final Function(String message) onSendNow;
  final Function(String message, DateTime scheduledTime) onSchedule;

  const ComposerSheet({
    super.key,
    required this.selectedContacts,
    required this.onRemoveContact,
    required this.onSendNow,
    required this.onSchedule,
  });

  @override
  State<ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<ComposerSheet> {
  final TextEditingController _messageController = TextEditingController();
  DateTime? _scheduledDateTime;
  bool _isSchedulingMode = false;

  final List<String> _templates = [
    "Dear {name}, this is a reminder that your outstanding balance is {amount}. Please settle it at your earliest convenience.",
    "Hi {name}! Friendly check-in: your outstanding bill of {amount} is ready. Thank you!",
    "Hello {name}, your payment of {amount} is now overdue. Please contact billing.",
    "Hi {name}, hope you are doing well! Let me know when we can catch up.",
    "Urgent: Please call me back as soon as possible.",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Pick Date and Time for scheduling
  Future<void> _selectDateTime() async {
    final now = DateTime.now();

    // 1. Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? now.add(const Duration(minutes: 10)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(
                context,
              ).colorScheme.primary, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black87, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // 2. Pick Time
    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledDateTime ?? now.add(const Duration(minutes: 10)),
      ),
    );

    if (pickedTime == null) return;

    // Combine date & time
    setState(() {
      _scheduledDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _isSchedulingMode = true;
    });
  }

  // Format scheduled datetime for user display
  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = months[dt.month - 1];
    final String day = dt.day.toString().padLeft(2, '0');
    final String hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12)
        .toString()
        .padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month ${dt.year} at $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.selectedContacts;
    final int charCount = _messageController.text.length;
    final int smsParts = (charCount / 160).ceil();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Compose Message',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${contacts.length} Selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Recipients chips list
              SizedBox(
                height: 40,
                child: contacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No recipients selected',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final c = contacts[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(
                                '${c.displayName} (${c.formattedOutstandingAmount})',
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => widget.onRemoveContact(c),
                              backgroundColor: Colors.grey[100],
                              deleteIconColor: Colors.grey[600],
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              // Template guide panel
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.indigo.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Customize message per recipient:\nUse {name} for contact name and {amount} for outstanding balance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.indigo.shade900,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Message text area
              TextField(
                controller: _messageController,
                maxLines: 4,
                onChanged: (text) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Character count & SMS info
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$charCount chars • $smsParts SMS part(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick Templates Title
              const Text(
                'Quick Templates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              // Horizontal scroll of templates
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final temp = _templates[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _messageController.text = temp;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          temp.length > 25
                              ? '${temp.substring(0, 25)}...'
                              : temp,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Scheduling Options bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSchedulingMode
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSchedulingMode
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSchedulingMode ? Icons.alarm : Icons.schedule,
                      color: _isSchedulingMode
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSchedulingMode
                                ? 'Scheduled Message'
                                : 'Send Instantly',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isSchedulingMode
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black87,
                            ),
                          ),
                          if (_isSchedulingMode && _scheduledDateTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _formatDateTime(_scheduledDateTime!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isSchedulingMode)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSchedulingMode = false;
                            _scheduledDateTime = null;
                          });
                        },
                      ),
                    TextButton(
                      onPressed: _selectDateTime,
                      child: Text(
                        _isSchedulingMode ? 'Change' : 'Schedule',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      contacts.isEmpty || _messageController.text.trim().isEmpty
                      ? null
                      : () {
                          final msg = _messageController.text.trim();
                          if (_isSchedulingMode && _scheduledDateTime != null) {
                            widget.onSchedule(msg, _scheduledDateTime!);
                          } else {
                            widget.onSendNow(msg);
                          }
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSchedulingMode ? Icons.schedule_send : Icons.send,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSchedulingMode
                            ? 'Schedule Send'
                            : 'Send Messages Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
