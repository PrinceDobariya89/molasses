import 'package:flutter/material.dart';
import 'models/contact_model.dart';
import 'models/sms_queue_item.dart';
import 'services/contact_service.dart';
import 'services/storage_service.dart';
import 'services/scheduler_service.dart';
import 'services/sms_service.dart';
import 'widgets/contact_tile.dart';
import 'widgets/composer_sheet.dart';
import 'widgets/queue_status_dialog.dart';
import 'widgets/scheduled_list.dart';
import 'widgets/history_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Background Scheduler
  await SchedulerService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Sender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo.shade700,
          secondary: Colors.deepPurpleAccent,
          surface: Colors.grey.shade50,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data lists
  List<ContactModel> _contacts = [];
  List<ContactModel> _filteredContacts = [];
  List<SmsQueueItem> _scheduledItems = [];
  List<SmsQueueItem> _historyItems = [];
  
  bool _isLoadingContacts = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add tab listener to refresh data when switching tabs
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadStoredData();
    });

    _loadContacts();
    _loadStoredData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load contacts list
  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      final list = await ContactService.getContacts();
      setState(() {
        _contacts = list;
        _filteredContacts = list;
      });
      _filterContacts(_searchController.text);
    } catch (e) {
      print('Error loading contacts: $e');
    } finally {
      setState(() {
        _isLoadingContacts = false;
      });
    }
  }

  // Load scheduled & history logs
  Future<void> _loadStoredData() async {
    final scheduled = await StorageService.getScheduled();
    final history = await StorageService.getHistory();
    setState(() {
      // Sort scheduled items by target time ascending
      scheduled.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      _scheduledItems = scheduled;
      _historyItems = history;
    });
  }

  // Filter contacts by search query
  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((c) {
        return c.displayName.toLowerCase().contains(lowercaseQuery) ||
            c.phoneNumber.contains(lowercaseQuery);
      }).toList();
    });
  }

  // Toggle selection on a contact
  void _toggleContactSelection(int index) {
    setState(() {
      final contact = _filteredContacts[index];
      contact.isSelected = !contact.isSelected;
    });
  }

  // Toggle Select All / Deselect All
  void _toggleSelectAll(bool selectAll) {
    setState(() {
      for (var c in _filteredContacts) {
        c.isSelected = selectAll;
      }
    });
  }

  // Total selected count
  int get _selectedCount => _contacts.where((c) => c.isSelected).length;

  // Selected contacts
  List<ContactModel> get _selectedContacts => _contacts.where((c) => c.isSelected).toList();

  // Send message immediately
  Future<void> _sendNow(String message) async {
    final List<Map<String, String>> recipients = _selectedContacts
        .map((c) => {'name': c.displayName, 'phoneNumber': c.phoneNumber})
        .toList();

    // 1. Create Progress Tracker
    final progressNotifier = ValueNotifier<QueueProgress>(
      QueueProgress(
        sentCount: 0,
        total: recipients.length,
        currentRecipientName: recipients.isNotEmpty ? recipients[0]['name']! : '',
        isCompleted: false,
      ),
    );

    // 2. Open dialog reporting sending progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QueueStatusDialog(progressNotifier: progressNotifier),
    );

    // 3. Trigger immediate send
    final campaign = await SmsService.sendImmediate(
      message: message,
      recipients: recipients,
      onProgress: (sentCount, total, currentName) {
        progressNotifier.value = QueueProgress(
          sentCount: sentCount,
          total: total,
          currentRecipientName: currentName,
          isCompleted: sentCount == total,
        );
      },
    );

    // 4. Update dialog final status
    progressNotifier.value = QueueProgress(
      sentCount: recipients.length,
      total: recipients.length,
      currentRecipientName: '',
      isCompleted: true,
      errorMessage: campaign.status == SmsQueueStatus.failed ? campaign.errorMessage : null,
    );

    // 5. Clean selection & reload
    _toggleSelectAll(false);
    _loadStoredData();
  }

  // Schedule message for background execution
  Future<void> _scheduleSms(String message, DateTime scheduledTime) async {
    final List<Map<String, String>> recipients = _selectedContacts
        .map((c) => {'name': c.displayName, 'phoneNumber': c.phoneNumber})
        .toList();

    final String campaignId = 'campaign_${DateTime.now().millisecondsSinceEpoch}';

    final SmsQueueItem item = SmsQueueItem(
      id: campaignId,
      message: message,
      recipients: recipients,
      status: SmsQueueStatus.pending,
      scheduledTime: scheduledTime,
    );

    // Register WorkManager background task
    final success = await SchedulerService.scheduleSmsTask(item);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.alarm_on, color: Colors.white),
              const SizedBox(width: 8),
              Text('Scheduled campaign successfully for ${_formatDateTime(scheduledTime)}!'),
            ],
          ),
          backgroundColor: Colors.indigo.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Reset selection and load state
      _toggleSelectAll(false);
      _loadStoredData();
      _tabController.animateTo(1); // switch to Scheduled tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to schedule campaign.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Cancel a scheduled campaign
  Future<void> _cancelScheduled(String taskId) async {
    final success = await SchedulerService.cancelSmsTask(taskId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled campaign canceled.'),
          backgroundColor: Colors.black87,
        ),
      );
      _loadStoredData();
    }
  }

  // Trigger compose Bottom Sheet modal
  void _openComposerSheet() {
    if (_selectedCount == 0) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ComposerSheet(
              selectedContacts: _selectedContacts,
              onRemoveContact: (c) {
                setState(() {
                  c.isSelected = false;
                });
                // Triggers modal UI update
                setModalState(() {});
              },
              onSendNow: _sendNow,
              onSchedule: _scheduleSms,
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final String month = months[dt.month - 1];
    final String day = dt.day.toString().padLeft(2, '0');
    final String hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final selectAll = _filteredContacts.isNotEmpty &&
        _filteredContacts.every((c) => c.isSelected);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(132),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade800, Colors.deepPurple.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sms, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'SMS Broadcast',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          _loadContacts();
                          _loadStoredData();
                        },
                      ),
                    ],
                  ),
                ),
                // Tab Navigation
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.cyanAccent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3.5,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 16),
                          const SizedBox(width: 6),
                          const Text('Contacts'),
                          if (_selectedCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.cyanAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _selectedCount.toString(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alarm, size: 16),
                          SizedBox(width: 6),
                          Text('Scheduled'),
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 16),
                          SizedBox(width: 6),
                          Text('History'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: CONTACTS LIST
          Column(
            children: [
              // Search & Select All controls
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterContacts,
                          decoration: InputDecoration(
                            hintText: 'Search contacts by name or phone...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Select All Toggle TextButton
                    TextButton.icon(
                      onPressed: () => _toggleSelectAll(!selectAll),
                      icon: Icon(
                        selectAll ? Icons.deselect : Icons.select_all,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        selectAll ? 'Deselect' : 'Select All',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main Contacts list
              Expanded(
                child: _isLoadingContacts
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredContacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No matching contacts found'
                                      : 'No contacts loaded',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredContacts.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              return ContactTile(
                                contact: contact,
                                onTap: () => _toggleContactSelection(index),
                              );
                            },
                          ),
              ),
            ],
          ),
          
          // TAB 2: SCHEDULED LIST
          ScheduledList(
            items: _scheduledItems,
            onCancel: _cancelScheduled,
          ),
          
          // TAB 3: HISTORY LOGS
          HistoryList(
            items: _historyItems,
          ),
        ],
      ),
      // Compose floating action button
      floatingActionButton: AnimatedScale(
        scale: _selectedCount > 0 && _tabController.index == 0 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: FloatingActionButton.extended(
          onPressed: _openComposerSheet,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.message),
          label: Text(
            'Compose SMS ($_selectedCount)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}