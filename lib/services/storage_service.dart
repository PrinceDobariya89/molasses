import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sms_queue_item.dart';

class StorageService {
  static const String _scheduledKey = 'scheduled_sms';
  static const String _historyKey = 'history_sms';

  // Fetch scheduled items from storage
  static Future<List<SmsQueueItem>> getScheduled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_scheduledKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List decoded = json.decode(jsonStr);
      return decoded.map((e) => SmsQueueItem.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching scheduled SMS: $e');
      return [];
    }
  }

  // Save scheduled items list to storage
  static Future<void> saveScheduled(List<SmsQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_scheduledKey, encoded);
  }

  // Add a single item to scheduled list
  static Future<void> addScheduled(SmsQueueItem item) async {
    final list = await getScheduled();
    list.removeWhere((e) => e.id == item.id);
    list.add(item);
    await saveScheduled(list);
  }

  // Remove a single item by id from scheduled list
  static Future<void> removeScheduled(String id) async {
    final list = await getScheduled();
    list.removeWhere((e) => e.id == id);
    await saveScheduled(list);
  }

  // Fetch history items from storage
  static Future<List<SmsQueueItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_historyKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List decoded = json.decode(jsonStr);
      // Sort by scheduled time descending (newest first)
      final items = decoded.map((e) => SmsQueueItem.fromJson(e)).toList();
      items.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return items;
    } catch (e) {
      print('Error fetching SMS history: $e');
      return [];
    }
  }

  // Save history items list to storage
  static Future<void> saveHistory(List<SmsQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }

  // Add a single item to history list
  static Future<void> addHistory(SmsQueueItem item) async {
    final list = await getHistory();
    list.add(item);
    await saveHistory(list);
  }

  // Move an item from scheduled to history (e.g. after execution)
  static Future<void> moveToHistory(String id, SmsQueueStatus status, {String? error}) async {
    final scheduled = await getScheduled();
    final index = scheduled.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = scheduled.removeAt(index);
      item.status = status;
      item.sentTime = DateTime.now();
      item.errorMessage = error;
      
      await saveScheduled(scheduled);
      await addHistory(item);
    }
  }
}
