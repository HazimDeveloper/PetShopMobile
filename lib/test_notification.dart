import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';
import 'notification_helper.dart';

class TestNotificationPage extends StatefulWidget {
  const TestNotificationPage({super.key});

  @override
  State<TestNotificationPage> createState() => _TestNotificationPageState();
}

class _TestNotificationPageState extends State<TestNotificationPage> {
  final NotificationService _notificationService = NotificationService();
  
  // Color theme matching your app
  final Color lightPastelBrown = Colors.brown[100]!;
  final Color pastelBrown = Colors.brown[300]!;
  final Color darkPastelBrown = Colors.brown[700]!;
  final Color shadowPastelBrown = Colors.brown[300]!.withOpacity(0.3);

  bool _notificationsEnabled = false;
  String _permissionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
      _permissionStatus = status.toString();
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationsEnabled = status.isGranted;
      _permissionStatus = status.toString();
    });
    
    if (status.isGranted) {
      _showSnackBar('✅ Notification permission granted!', Colors.green);
    } else {
      _showSnackBar('❌ Notification permission denied', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Test immediate notification
  Future<void> _testImmediateNotification() async {
    try {
      await _notificationService.scheduleTaskReminder(
        id: 999,
        title: '🔔 Test Notification',
        body: 'This is an immediate test notification!',
        scheduledDate: DateTime.now().add(Duration(seconds: 2)),
        payload: 'test_immediate',
      );
      _showSnackBar('⏰ Immediate notification scheduled for 2 seconds', Colors.blue);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  // Test scheduled notification (5 minutes)
  Future<void> _testScheduledNotification() async {
    try {
      final scheduledTime = DateTime.now().add(Duration(minutes: 5));
      await _notificationService.scheduleTaskReminder(
        id: 998,
        title: '⏰ Scheduled Test',
        body: 'This notification was scheduled 5 minutes ago!',
        scheduledDate: scheduledTime,
        payload: 'test_scheduled',
      );
      _showSnackBar('📅 Notification scheduled for 5 minutes from now', Colors.orange);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  // Test pet care reminder
  Future<void> _testPetCareReminder() async {
    try {
      await NotificationHelper.scheduleNoteReminder(
        noteId: 997,
        title: 'Feed Fluffy',
        content: 'Don\'t forget to give Fluffy her evening meal',
        category: 'Feeding',
        reminderDateTime: DateTime.now().add(Duration(seconds: 10)),
        pets: ['Fluffy', 'Buddy'],
      );
      _showSnackBar('🐾 Pet care reminder scheduled for 10 seconds', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  // Test vet appointment reminder
  Future<void> _testVetAppointment() async {
    try {
      await NotificationHelper.scheduleNoteReminder(
        noteId: 996,
        title: 'Vet Appointment',
        content: 'Charlie has a checkup appointment at 2 PM today',
        category: 'Health',
        reminderDateTime: DateTime.now().add(Duration(seconds: 15)),
        pets: ['Charlie'],
      );
      _showSnackBar('🏥 Vet appointment reminder scheduled for 15 seconds', Colors.purple);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  // Test multiple notifications
  Future<void> _testMultipleNotifications() async {
    try {
      // Schedule 3 notifications with different delays
      for (int i = 1; i <= 3; i++) {
        await _notificationService.scheduleTaskReminder(
          id: 990 + i,
          title: '📱 Multiple Test $i/3',
          body: 'This is test notification number $i',
          scheduledDate: DateTime.now().add(Duration(seconds: i * 5)),
          payload: 'test_multiple_$i',
        );
      }
      _showSnackBar('🔄 3 notifications scheduled (5s, 10s, 15s)', Colors.teal);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  // Cancel all test notifications
  Future<void> _cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      _showSnackBar('🗑️ All notifications cancelled', Colors.grey);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  // Test daily reminders setup
  Future<void> _testDailyReminders() async {
    try {
      await NotificationHelper.setupDailyReminders();
      _showSnackBar('📅 Daily reminders setup complete', Colors.indigo);
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBrown,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkPastelBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Test Notifications',
          style: TextStyle(
            color: darkPastelBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Status Card
            _buildStatusCard(),
            SizedBox(height: 20),
            
            // Quick Tests Section
            _buildSectionCard(
              title: 'Quick Tests',
              icon: Icons.flash_on,
              children: [
                _buildTestButton(
                  title: 'Immediate Notification',
                  subtitle: 'Shows in 2 seconds',
                  icon: Icons.notifications_active,
                  color: Colors.blue,
                  onPressed: _testImmediateNotification,
                ),
                _buildTestButton(
                  title: 'Scheduled Notification',
                  subtitle: 'Shows in 5 minutes',
                  icon: Icons.schedule,
                  color: Colors.orange,
                  onPressed: _testScheduledNotification,
                ),
                _buildTestButton(
                  title: 'Multiple Notifications',
                  subtitle: 'Shows 3 notifications (5s, 10s, 15s)',
                  icon: Icons.notifications_none,
                  color: Colors.teal,
                  onPressed: _testMultipleNotifications,
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Pet Care Tests Section
            _buildSectionCard(
              title: 'Pet Care Reminders',
              icon: Icons.pets,
              children: [
                _buildTestButton(
                  title: 'Feeding Reminder',
                  subtitle: 'Pet feeding notification (10s)',
                  icon: Icons.restaurant,
                  color: Colors.green,
                  onPressed: _testPetCareReminder,
                ),
                _buildTestButton(
                  title: 'Vet Appointment',
                  subtitle: 'Health checkup reminder (15s)',
                  icon: Icons.local_hospital,
                  color: Colors.purple,
                  onPressed: _testVetAppointment,
                ),
                _buildTestButton(
                  title: 'Daily Reminders',
                  subtitle: 'Setup daily pet care reminders',
                  icon: Icons.today,
                  color: Colors.indigo,
                  onPressed: _testDailyReminders,
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Control Section
            _buildSectionCard(
              title: 'Controls',
              icon: Icons.settings,
              children: [
                _buildTestButton(
                  title: 'Cancel All Notifications',
                  subtitle: 'Clear all pending notifications',
                  icon: Icons.clear_all,
                  color: Colors.grey,
                  onPressed: _cancelAllNotifications,
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Instructions Card
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowPastelBrown,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _notificationsEnabled ? Icons.check_circle : Icons.error,
                color: _notificationsEnabled ? Colors.green : Colors.red,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Notification Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPastelBrown,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Permission: $_permissionStatus',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Enabled: ${_notificationsEnabled ? "Yes" : "No"}',
            style: TextStyle(
              fontSize: 14,
              color: _notificationsEnabled ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!_notificationsEnabled) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requestNotificationPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pastelBrown,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Request Permission',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowPastelBrown,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pastelBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: pastelBrown, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPastelBrown,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _notificationsEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _notificationsEnabled 
                ? color.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _notificationsEnabled 
                  ? color.withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _notificationsEnabled 
                      ? color.withOpacity(0.2) 
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: _notificationsEnabled ? color : Colors.grey,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _notificationsEnabled 
                            ? darkPastelBrown 
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _notificationsEnabled 
                            ? Colors.grey[600] 
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_notificationsEnabled)
                Icon(Icons.lock, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                'Testing Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Make sure notification permission is granted\n'
            '• Test notifications will appear even when app is closed\n'
            '• Tap on notifications to test interaction\n'
            '• Check notification settings in device settings if needed\n'
            '• Cancel all notifications before leaving this page',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}