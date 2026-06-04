import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import '../models/contact_model.dart';

class ContactService {
  // Check if we have permission to read contacts
  static Future<bool> checkPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  // Request permission to read contacts
  static Future<bool> requestPermission() async {
    // We can request via permission_handler or flutter_contacts
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Fetch contacts
  static Future<List<ContactModel>> getContacts({bool forceMock = false}) async {
    if (forceMock) {
      return _getMockContacts();
    }

    try {
      // First, check permission
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        hasPermission = await requestPermission();
      }

      if (!hasPermission) {
        print("Contacts permission denied, returning mock contacts.");
        return _getMockContacts();
      }

      // Fetch contacts with properties (phones, etc.)
      final List<Contact> deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final List<ContactModel> contacts = [];
      final random = Random();

      for (var c in deviceContacts) {
        // Skip contacts without display name or phone numbers
        if (c.displayName.trim().isEmpty || c.phones.isEmpty) continue;
        
        // Clean and get first phone number
        final String rawPhone = c.phones.first.number;
        final String cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]+'), '');

        if (cleanPhone.isEmpty) continue;

        contacts.add(
          ContactModel(
            id: c.id,
            displayName: c.displayName,
            phoneNumber: rawPhone, // keep original format for display
            isSelected: false,
            colorIndex: random.nextInt(6), // 6 gradient styles
          ),
        );
      }

      // If no contacts on device, return mock data
      if (contacts.isEmpty) {
        print("No contacts found on device, returning mock contacts.");
        return _getMockContacts();
      }

      // Sort alphabetically
      contacts.sort((a, b) => a.displayName.compareTo(b.displayName));
      return contacts;
    } catch (e) {
      print("Error fetching contacts: $e. Returning mock contacts.");
      return _getMockContacts();
    }
  }

  // Generate realistic mock contacts for testing
  static List<ContactModel> _getMockContacts() {
    final List<Map<String, String>> mockData = [
      {'name': 'Alex Rivera', 'phone': '+1 (555) 019-2834'},
      {'name': 'Beatriz Chen', 'phone': '+1 (555) 022-7711'},
      {'name': 'Charlie Davis', 'phone': '+1 (555) 045-8899'},
      {'name': 'Diana Prince', 'phone': '+1 (555) 076-1234'},
      {'name': 'Evan Wright', 'phone': '+1 (555) 098-5678'},
      {'name': 'Fiona Gallagher', 'phone': '+1 (555) 032-9012'},
      {'name': 'George Costanza', 'phone': '+1 (555) 054-3456'},
      {'name': 'Hannah Abbott', 'phone': '+1 (555) 087-6543'},
      {'name': 'Ian Malcolm', 'phone': '+1 (555) 012-7890'},
      {'name': 'Julia Roberts', 'phone': '+1 (555) 043-2109'},
      {'name': 'Kevin Bacon', 'phone': '+1 (555) 062-8347'},
      {'name': 'Laura Croft', 'phone': '+1 (555) 099-1122'},
      {'name': 'Marcus Aurelius', 'phone': '+1 (555) 077-3344'},
      {'name': 'Natalie Portman', 'phone': '+1 (555) 088-5566'},
      {'name': 'Oliver Twist', 'phone': '+1 (555) 022-9988'},
    ];

    final List<ContactModel> contacts = [];
    final random = Random(42); // Seeded random for consistent initials styling

    for (int i = 0; i < mockData.length; i++) {
      contacts.add(
        ContactModel(
          id: 'mock_$i',
          displayName: mockData[i]['name']!,
          phoneNumber: mockData[i]['phone']!,
          isSelected: false,
          colorIndex: random.nextInt(6),
        ),
      );
    }

    contacts.sort((a, b) => a.displayName.compareTo(b.displayName));
    return contacts;
  }
}
