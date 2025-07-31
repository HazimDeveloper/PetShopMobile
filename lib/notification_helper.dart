import 'package:fyp/notification_service.dart';


class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  static Future<void> scheduleNoteReminder({
    required int noteId,
    required String title,
    required String content,
    required String category,
    required DateTime reminderDateTime,
    required List<String> pets,
  }) async {
    if (!reminderDateTime.isAfter(DateTime.now())) {
      return; // Don't schedule past notifications
    }

    String petsText = pets.isNotEmpty ? 'for ${pets.join(', ')}' : '';
    String body = '$category reminder $petsText';
    if (content.isNotEmpty && content.length > 10) {
      body += ': ${content.substring(0, 50)}${content.length > 50 ? '...' : ''}';
    }

    await _notificationService.scheduleTaskReminder(
      id: noteId,
      title: '🐾 $title',
      body: body,
      scheduledDate: reminderDateTime,
      payload: 'note_$noteId',
    );

    print('✅ Notification scheduled for: $reminderDateTime');
  }

  static Future<void> cancelNoteReminder(int noteId) async {
    await _notificationService.cancelNotification(noteId);
    print('❌ Notification cancelled for note: $noteId');
  }

  static Future<void> setupDailyReminders() async {
    // You can customize these or remove if not needed
    await _notificationService.scheduleTaskReminder(
      id: 99999,
      title: '🍽️ Daily Pet Care',
      body: 'Check if your pets need feeding or attention',
      scheduledDate: DateTime.now().add(Duration(days: 1)),
    );
  }
}