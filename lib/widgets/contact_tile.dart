import 'package:flutter/material.dart';
import '../models/contact_model.dart';

class ContactTile extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onTap;
  final VoidCallback onEditAmount;

  const ContactTile({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onEditAmount,
  });

  // Predefined harmonious gradients for contact avatars
  static const List<List<Color>> _avatarGradients = [
    [Color(0xFFFF5F6D), Color(0xFFFFC371)], // Sunset Gold
    [Color(0xFF2193b0), Color(0xFF6dd5ed)], // Blue Sky
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Deep Purple
    [Color(0xFF11998e), Color(0xFF38ef7d)], // Neon Green
    [Color(0xFFF7797D), Color(0xFFC6FFDD)], // Peach/Mint
    [Color(0xFFe65c00), Color(0xFFF9D423)], // Red Orange
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _avatarGradients[contact.colorIndex % _avatarGradients.length];

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: contact.isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: contact.isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Gradient Avatar with Initials
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Contact Name & Number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: contact.isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: contact.isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.phoneNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Outstanding Amount Badge
            GestureDetector(
              onTap: onEditAmount,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: contact.outstandingAmount > 0
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: contact.outstandingAmount > 0
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contact.formattedOutstandingAmount,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: contact.outstandingAmount > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 11,
                      color: contact.outstandingAmount > 0
                          ? Colors.red.shade400
                          : Colors.green.shade400,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Animated Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: contact.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: contact.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: contact.isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
