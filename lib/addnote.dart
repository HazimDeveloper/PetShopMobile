import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
// ADD THIS IMPORT FOR NOTIFICATIONS:
import 'notification_helper.dart';

class AddNotePage extends StatefulWidget {
  final DateTime? initialDate;

  const AddNotePage({super.key, this.initialDate});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _petController = TextEditingController();

  // Color theme
  final Color lightPastelBrown = Colors.brown[100]!;
  final Color pastelBrown = Colors.brown[300]!;
  final Color darkPastelBrown = Colors.brown[700]!;
  final Color shadowPastelBrown = Colors.brown[300]!.withOpacity(0.3);

  String _selectedCategory = 'General';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<String> _selectedPets = [];
  String _selectedPriority = 'medium';
  bool _isLoading = false;
  bool _enableNotification = true; // NEW: Toggle for notifications

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'icon': Icons.note, 'color': Colors.brown[400]!},
    {'name': 'Health', 'icon': Icons.medical_services, 'color': Colors.red[400]!},
    {'name': 'Feeding', 'icon': Icons.restaurant, 'color': Colors.green[400]!},
    {'name': 'Training', 'icon': Icons.school, 'color': Colors.blue[400]!},
    {'name': 'Grooming', 'icon': Icons.content_cut, 'color': Colors.orange[400]!},
    {'name': 'Play', 'icon': Icons.sports_esports, 'color': Colors.purple[400]!},
    {'name': 'Vet Visit', 'icon': Icons.local_hospital, 'color': Colors.teal[400]!},
  ];

  // UPDATED: Dynamic pet list instead of hardcoded
  List<String> _availablePets = [];
  bool _isPetsLoading = false;
  String? _petsError;

  final List<Map<String, dynamic>> _priorities = [
    {'name': 'low', 'label': 'Low', 'color': Colors.green, 'icon': Icons.keyboard_arrow_down},
    {'name': 'medium', 'label': 'Medium', 'color': Colors.orange, 'icon': Icons.remove},
    {'name': 'high', 'label': 'High', 'color': Colors.red, 'icon': Icons.keyboard_arrow_up},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    
    // NEW: Load user's pets when the page loads
    _loadUserPets();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _petController.dispose();
    super.dispose();
  }

  // NEW: Method to fetch user's pets from database
  Future<void> _loadUserPets() async {
    setState(() {
      _isPetsLoading = true;
      _petsError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      
      if (userId.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/project1msyamar/get_pets.php?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('🐾 Pets API Response: ${response.statusCode}');
      print('🐾 Pets API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> petsData = json.decode(response.body);
        
        List<String> petNames = [];
        for (var pet in petsData) {
          if (pet['petName'] != null && pet['petName'].toString().isNotEmpty) {
            petNames.add(pet['petName'].toString());
          }
        }

        setState(() {
          _availablePets = petNames;
          _isPetsLoading = false;
        });

        print('✅ Loaded ${petNames.length} pets: $petNames');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading pets: $e');
      setState(() {
        _petsError = 'Failed to load your pets: ${e.toString()}';
        _isPetsLoading = false;
        // Set empty list so user can still add custom pet names
        _availablePets = [];
      });
    }
  }

  // Method to select date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: pastelBrown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkPastelBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Method to select time
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: pastelBrown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkPastelBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addPet() {
    if (_petController.text.trim().isNotEmpty) {
      setState(() {
        _selectedPets.add(_petController.text.trim());
        _petController.clear();
      });
    }
  }

  void _removePet(String pet) {
    setState(() {
      _selectedPets.remove(pet);
    });
  }

  void _addPresetPet(String pet) {
    if (!_selectedPets.contains(pet)) {
      setState(() {
        _selectedPets.add(pet);
      });
    }
  }

  // UPDATED: Modified to include notification scheduling
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '1';

      final result = await ApiService.addNote(
        userId: userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate.toIso8601String().split('T')[0],
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        pets: _selectedPets,
        priority: _selectedPriority,
      );

      if (result['status'] == 'success') {
        // NEW: Schedule notification if enabled and note was saved successfully
        bool notificationScheduled = false;
        String notificationMessage = "Note saved successfully! 🎉";

        if (_enableNotification && result['data'] != null) {
          // Get note ID from response
          int? noteId;
          if (result['data']['note_id'] != null) {
            noteId = result['data']['note_id'];
          }

          if (noteId != null) {
            // Combine date and time for notification
            final reminderDateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

            // Only schedule if the reminder is in the future
            if (reminderDateTime.isAfter(DateTime.now())) {
              try {
                await NotificationHelper.scheduleNoteReminder(
                  noteId: noteId,
                  title: _titleController.text.trim(),
                  content: _contentController.text.trim(),
                  category: _selectedCategory,
                  reminderDateTime: reminderDateTime,
                  pets: _selectedPets,
                );
                
                notificationScheduled = true;
                notificationMessage = "Note saved and reminder set for ${_formatDateTime(reminderDateTime)}! 🔔";
              } catch (e) {
                print('Error scheduling notification: $e');
                notificationMessage = "Note saved successfully, but notification scheduling failed.";
              }
            }
          }
        }

        if (mounted) {
          // Show enhanced confirmation popup with notification info
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                    SizedBox(width: 8),
                    Text("Success"),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notificationMessage),
                    if (notificationScheduled) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active, color: Colors.blue.shade600, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You\'ll receive a phone notification at the scheduled time!',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pop(context); // Navigate back to the previous screen
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to save note');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // NEW: Helper method to format date time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today';
    } else if (noteDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
          'Add New Note',
          style: TextStyle(
            color: darkPastelBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(pastelBrown),
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: pastelBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _slideAnimation.value)),
            child: Opacity(
              opacity: _slideAnimation.value,
              child: child,
            ),
          );
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title Section
              _buildSectionCard(
                title: 'Note Details',
                icon: Icons.edit,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter note title...',
                      prefixIcon: Icon(Icons.title, color: pastelBrown),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: pastelBrown, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Content (Optional)',
                      hintText: 'Add more details...',
                      prefixIcon: Icon(Icons.description, color: pastelBrown),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: pastelBrown, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Category Section
              _buildSectionCard(
                title: 'Category',
                icon: Icons.category,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category['name'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? category['color'] : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: category['color'],
                              width: isSelected ? 0 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: category['color'].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'],
                                size: 18,
                                color: isSelected ? Colors.white : category['color'],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : category['color'],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Date & Time Section
              _buildSectionCard(
                title: 'Schedule',
                icon: Icons.schedule,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightPastelBrown.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: pastelBrown.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: pastelBrown),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _formatDate(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: darkPastelBrown,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightPastelBrown.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: pastelBrown.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: pastelBrown),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _selectedTime.format(context),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: darkPastelBrown,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // NEW: Notification Settings Section
              _buildSectionCard(
                title: 'Notification Settings',
                icon: Icons.notifications,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _enableNotification,
                        onChanged: (value) {
                          setState(() {
                            _enableNotification = value;
                          });
                        },
                        activeColor: pastelBrown,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Reminder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: darkPastelBrown,
                              ),
                            ),
                            Text(
                              _enableNotification 
                                ? 'You\'ll receive a phone notification at the scheduled time'
                                : 'No notification will be sent',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_enableNotification) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notifications work even when the app is closed. Make sure your device allows notifications from this app.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Priority Section
              _buildSectionCard(
                title: 'Priority',
                icon: Icons.flag,
                children: [
                  Row(
                    children: _priorities.map((priority) {
                      final isSelected = _selectedPriority == priority['name'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPriority = priority['name'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? priority['color'] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: priority['color'],
                                width: isSelected ? 0 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  priority['icon'],
                                  size: 18,
                                  color: isSelected ? Colors.white : priority['color'],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  priority['label'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : priority['color'],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // UPDATED: Pets Section with dynamic loading
              _buildSectionCard(
                title: 'Pets',
                icon: Icons.pets,
                children: [
                  // Add custom pet
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _petController,
                          decoration: InputDecoration(
                            hintText: 'Add pet name...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: pastelBrown, width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _addPet(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addPet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pastelBrown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),

                  // NEW: Show loading, error, or pet list
                  if (_isPetsLoading) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(pastelBrown),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading your pets...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ] else if (_petsError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unable to load your pets',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'You can still type pet names manually above.',
                                  style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _loadUserPets,
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_availablePets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Your Pets (tap to add):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: darkPastelBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availablePets.map((pet) {
                        final isSelected = _selectedPets.contains(pet);
                        return GestureDetector(
                          onTap: () => _addPresetPet(pet),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? pastelBrown : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: pastelBrown,
                                width: isSelected ? 0 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 16,
                                  color: isSelected ? Colors.white : pastelBrown,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  pet,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : pastelBrown,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else if (!_isPetsLoading && _petsError == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No pets found. Add some pets in the Pet Management section or type pet names manually above.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_selectedPets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Selected Pets:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: darkPastelBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedPets.map((pet) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: pastelBrown,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                pet,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removePet(pet),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowPastelBrown,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pastelBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: pastelBrown, size: 20),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}