import 'package:flutter/material.dart';
import 'dart:convert';

class Note {
  final String title;
  final String category;
  final DateTime date;
  final TimeOfDay time;
  final List<String> pets;

  Note({
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.pets,
  });

  // Helper method to convert Note to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'pets': jsonEncode(pets), // Make sure pets are encoded into a JSON string
    };
  }

  // Helper method to create Note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      date: json['date'] != null 
        ? DateTime.parse(json['date'].toString()) 
        : DateTime.now(),
      time: _parseTimeOfDay(json['time']),
      pets: json['pets'] != null 
        ? List<String>.from(json['pets']) 
        : [],
    );
  }

  static TimeOfDay _parseTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }

  // Helper method to get DateTime combining date and time
  DateTime get dateTime {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
