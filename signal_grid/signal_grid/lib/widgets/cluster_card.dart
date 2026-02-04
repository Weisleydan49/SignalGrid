import 'package:flutter/material.dart';

/// A reusable card widget that displays cluster information
/// Shows title, description, status with color coding, and an icon
/// Supports tap interaction through optional onTap callback
class ClusterCard extends StatelessWidget {
  final String title;           // Main heading text
  final String description;     // Secondary descriptive text
  final String status;          // Status label (e.g., "Active", "Inactive")
  final IconData icon;          // Icon displayed on the left side
  final Color statusColor;      // Color for status chip and icon
  final VoidCallback? onTap;    // Optional callback when card is tapped

  const ClusterCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.statusColor,
    this.onTap,  // Optional - card can be non-interactive
  });

  @override
  Widget build(BuildContext context) {
    // Wrap entire card with GestureDetector to handle tap events
    return GestureDetector(
      onTap: onTap,  // Execute callback when card is tapped
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side icon with status color
              Icon(icon, size: 32, color: statusColor),
              const SizedBox(width: 12),

              // Right side content (title, description, status chip)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title text
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description text
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),

                    // Status chip aligned to the right
                    Align(
                      alignment: Alignment.centerRight,
                      child: Chip(
                        label: Text(status),
                        // Status chip background uses color with transparency
                        backgroundColor: statusColor.withOpacity(0.15),
                        labelStyle: TextStyle(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}