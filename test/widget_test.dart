// Pure-logic unit tests for Biteo Vendor Panel helpers.
//
// These tests are deliberately Firebase-free: the formatters in
// lib/utils/formatters.dart are the shared pure logic used across the
// order and menu screens, and can be verified without any platform
// services (Firestore, messaging, plugins).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biteo_vendor_panel/utils/formatters.dart';

void main() {
  group('formatRupeesFromPaise', () {
    test('formats zero paise', () {
      expect(formatRupeesFromPaise(0), '₹ 0');
    });

    test('formats whole rupee amounts', () {
      expect(formatRupeesFromPaise(12345), '₹ 123');
    });

    test('rounds sub-rupee fractions', () {
      expect(formatRupeesFromPaise(999), '₹ 10');
      expect(formatRupeesFromPaise(1499), '₹ 15');
    });

    test('handles large amounts', () {
      expect(formatRupeesFromPaise(999999), '₹ 10000');
    });
  });

  group('orderStatusLabel', () {
    test('maps known statuses to emoji labels', () {
      expect(orderStatusLabel('pending'), '🟠 Pending');
      expect(orderStatusLabel('accepted'), '🟢 Accepted');
      expect(orderStatusLabel('preparing'), '🔵 Preparing');
      expect(orderStatusLabel('ready'), '🟣 Ready');
      expect(orderStatusLabel('completed'), '⚫ Completed');
      expect(orderStatusLabel('rejected'), '🔴 Rejected');
    });

    test('passes unknown statuses through verbatim', () {
      expect(orderStatusLabel('in_transit'), 'in_transit');
      expect(orderStatusLabel(''), '');
    });
  });

  group('orderStatusColor', () {
    test('maps known statuses to colors', () {
      expect(orderStatusColor('pending'), Colors.orange);
      expect(orderStatusColor('accepted'), Colors.green);
      expect(orderStatusColor('preparing'), Colors.blue);
      expect(orderStatusColor('ready'), Colors.purple);
      expect(orderStatusColor('completed'), Colors.grey);
      expect(orderStatusColor('rejected'), Colors.red);
    });

    test('falls back to black for unknown statuses', () {
      expect(orderStatusColor('unknown'), Colors.black);
    });
  });
}
