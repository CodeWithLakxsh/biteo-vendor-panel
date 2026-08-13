import 'package:flutter/material.dart';

/// Formats an amount in paise (Indian currency subunits) as a whole-number
/// rupee string, e.g. `12345` -> `"₹ 123"`.
///
/// Mirrors the formatting previously inlined in menu/dashboard/order UI.
String formatRupeesFromPaise(num paise) {
  final rupees = paise.toDouble() / 100;
  return '₹ ${rupees.toStringAsFixed(0)}';
}

/// Returns the human-readable label (with emoji) for an order [status].
/// Unknown statuses are returned verbatim.
String orderStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return '🟠 Pending';
    case 'accepted':
      return '🟢 Accepted';
    case 'preparing':
      return '🔵 Preparing';
    case 'ready':
      return '🟣 Ready';
    case 'completed':
      return '⚫ Completed';
    case 'rejected':
      return '🔴 Rejected';
    default:
      return status;
  }
}

/// Returns the display [Color] for an order [status].
/// Unknown statuses fall back to black.
Color orderStatusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'accepted':
      return Colors.green;
    case 'preparing':
      return Colors.blue;
    case 'ready':
      return Colors.purple;
    case 'completed':
      return Colors.grey;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.black;
  }
}
