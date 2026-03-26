import 'package:flutter/material.dart';

class AppColors {
  // Role colors
  static const Color admin = Color(0xFF8B5CF6);      // Violet
  static const Color manager = Color(0xFFF59E0B);    // Amber
  static const Color staff = Color(0xFF10B981);      // Emerald
  static const Color customer = Color(0xFF3B82F6);   // Blue

  // Dark theme backgrounds
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardAlt = Color(0xFF334155);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Order status
  static Color orderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return warning;
      case 'processing': return info;
      case 'shipped': return const Color(0xFF8B5CF6);
      case 'delivered':
      case 'completed': return success;
      case 'cancelled': return error;
      default: return const Color(0xFF64748B);
    }
  }

  // Build request status
  static Color buildRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return warning;
      case 'assigned': return info;
      case 'in_progress': return const Color(0xFF8B5CF6);
      case 'completed': return success;
      case 'cancelled': return const Color(0xFF64748B);
      case 'rejected': return error;
      default: return const Color(0xFF64748B);
    }
  }

  // Role color
  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return admin;
      case 'shop manager': return manager;
      case 'staff': return staff;
      default: return customer;
    }
  }
}
