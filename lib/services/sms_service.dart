import 'dart:io';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import '../models/sms_queue_item.dart';

class SmsService {
  // Check if we have permission to send SMS
  static Future<bool> checkPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  // Request permission to send SMS
  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Send SMS immediately to a list of recipients (foreground task queue)
  static Future<SmsQueueItem> sendImmediate({
    required String message,
    required List<Map<String, String>> recipients,
    required void Function(int sentCount, int total, String currentName) onProgress,
  }) async {
    final String campaignId = 'campaign_${DateTime.now().millisecondsSinceEpoch}';
    final DateTime scheduledTime = DateTime.now();

    final SmsQueueItem campaign = SmsQueueItem(
      id: campaignId,
      message: message,
      recipients: recipients,
      status: SmsQueueStatus.sending,
      scheduledTime: scheduledTime,
    );

    bool overallSuccess = true;
    String? errorMessage;

    try {
      // 1. Check and request SMS permission
      bool hasPermission = await checkPermission();
      if (!hasPermission && Platform.isAndroid) {
        hasPermission = await requestPermission();
      }

      if (Platform.isAndroid && !hasPermission) {
        overallSuccess = false;
        errorMessage = 'SMS Permission denied.';
        campaign.status = SmsQueueStatus.failed;
        campaign.errorMessage = errorMessage;
        campaign.sentTime = DateTime.now();
        await StorageService.addHistory(campaign);
        return campaign;
      }

      // 2. Loop through recipients sequentially
      int completed = 0;
      final int total = recipients.length;

      for (final recipient in recipients) {
        final String name = recipient['name'] ?? 'Unknown';
        final String phone = recipient['phoneNumber'] ?? '';

        // Call progress callback
        onProgress(completed, total, name);

        if (phone.isEmpty) {
          completed++;
          continue;
        }

        if (Platform.isAndroid) {
          final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]+'), '');
          final String textToSend = recipient['customMessage'] ?? message;
          try {
            await Telephony.instance.sendSms(
              to: cleanPhone,
              message: textToSend,
            );
          } catch (e) {
            overallSuccess = false;
            errorMessage = 'Sending error: $e';
          }
        } else {
          // Simulation for iOS / Web / Desktop
          final String textToSend = recipient['customMessage'] ?? message;
          print('Simulating sending SMS to $name ($phone): $textToSend');
          // Hold for 1 second per contact to show progress in UI
          await Future.delayed(const Duration(milliseconds: 1000));
        }

        completed++;
        onProgress(completed, total, name);
      }

      // 3. Finalize campaign
      campaign.status = overallSuccess ? SmsQueueStatus.sent : SmsQueueStatus.failed;
      campaign.sentTime = DateTime.now();
      campaign.errorMessage = errorMessage;

      // 4. Save to history log
      await StorageService.addHistory(campaign);
      return campaign;
    } catch (e) {
      print('Error during immediate SMS queue: $e');
      campaign.status = SmsQueueStatus.failed;
      campaign.sentTime = DateTime.now();
      campaign.errorMessage = 'Fatal error: $e';
      await StorageService.addHistory(campaign);
      return campaign;
    }
  }
}
