import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:another_telephony/telephony.dart' hide NetworkType;
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import '../models/sms_queue_item.dart';

// Top-level callback dispatcher required by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print('Workmanager background task triggered: $taskName with data $inputData');
    
    if (inputData == null || !inputData.containsKey('id')) {
      print('Invalid background task input data.');
      return Future.value(false);
    }

    final String itemId = inputData['id'] as String;

    try {
      // 1. Fetch the scheduled message
      final scheduledItems = await StorageService.getScheduled();
      final index = scheduledItems.indexWhere((e) => e.id == itemId);
      
      if (index == -1) {
        print('Scheduled SMS item not found in database: $itemId');
        return Future.value(false);
      }

      final SmsQueueItem item = scheduledItems[index];

      // Update status to sending in database
      item.status = SmsQueueStatus.sending;
      await StorageService.saveScheduled(scheduledItems);

      bool overallSuccess = true;
      String? errorMessage;

      // 2. Send SMS to all recipients
      if (Platform.isAndroid) {
        // Double-check permission in background
        final smsPermissionStatus = await Permission.sms.status;
        if (!smsPermissionStatus.isGranted) {
          print('Background SMS execution failed: SMS Permission not granted.');
          overallSuccess = false;
          errorMessage = 'SMS permission not granted in background.';
        } else {
          for (final recipient in item.recipients) {
            final String? phone = recipient['phoneNumber'];
            if (phone == null || phone.isEmpty) continue;
            
            // Clean phone number for sending
            final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]+'), '');

            try {
              await Telephony.instance.sendSms(
                to: cleanPhone,
                message: item.message,
              );
            } catch (e) {
              overallSuccess = false;
              errorMessage = 'Sending error: $e';
              print('Error sending background SMS to $phone: $e');
            }
          }
        }
      } else {
        // Simulation for iOS / Web / Desktop during background execution
        print('Direct sending is simulated on this platform.');
        // Wait 1.5 seconds per recipient to simulate real network delay
        for (final _ in item.recipients) {
          await Future.delayed(const Duration(milliseconds: 1500));
        }
        overallSuccess = true;
      }

      // 3. Move the campaign from scheduled to history
      final finalStatus = overallSuccess ? SmsQueueStatus.sent : SmsQueueStatus.failed;
      await StorageService.moveToHistory(itemId, finalStatus, error: errorMessage);

      print('Background task completed successfully. Status: ${finalStatus.name}');
      return Future.value(true);
    } catch (e) {
      print('Fatal error in background task dispatcher: $e');
      // If we failed, move to history with failure status
      try {
        await StorageService.moveToHistory(itemId, SmsQueueStatus.failed, error: 'Fatal background error: $e');
      } catch (_) {}
      return Future.value(false);
    }
  });
}

class SchedulerService {
  // Initialize Workmanager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    print('Workmanager scheduler initialized.');
  }

  // Schedule an SMS campaign
  static Future<bool> scheduleSmsTask(SmsQueueItem item) async {
    try {
      // 1. Calculate initial delay
      final now = DateTime.now();
      Duration delay = item.scheduledTime.difference(now);
      
      // If delay is negative (past), make it trigger in 5 seconds
      if (delay.isNegative) {
        delay = const Duration(seconds: 5);
      }

      // 2. Add to scheduled storage first
      await StorageService.addScheduled(item);

      // 3. Register one-off task with Workmanager (Android/iOS background daemon)
      await Workmanager().registerOneOffTask(
        item.id, // Use item ID as uniqueName
        'sendScheduledSmsTask', // Task type identifier
        initialDelay: delay,
        inputData: <String, dynamic>{
          'id': item.id,
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      print('SMS campaign scheduled with ID: ${item.id}. Delay: ${delay.inMinutes} minutes (${delay.inSeconds} seconds)');
      return true;
    } catch (e) {
      print('Error scheduling SMS task: $e');
      return false;
    }
  }

  // Cancel a scheduled SMS campaign
  static Future<bool> cancelSmsTask(String taskId) async {
    try {
      // 1. Cancel in Workmanager
      await Workmanager().cancelByUniqueName(taskId);
      
      // 2. Remove from scheduled storage
      await StorageService.removeScheduled(taskId);
      
      print('SMS campaign canceled: $taskId');
      return true;
    } catch (e) {
      print('Error canceling scheduled SMS task: $e');
      return false;
    }
  }
}
