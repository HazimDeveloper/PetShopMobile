import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

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

  final List<String> _availablePets = [
    'Max', 'Buddy', 'Luna', 'Charlie', 'Bella', 'Rocky', 'Daisy', 'Cooper'
  ];

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _petController.dispose();
    super.dispose();
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
        if (mounted) {
          // Show confirmation popup
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Success"),
                content: Text("Note saved successfully! 🎉"),
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

              // Pets Section
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

                  if (_availablePets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Quick Add:',
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
                            child: Text(
                              pet,
                              style: TextStyle(
                                color: isSelected ? Colors.white : pastelBrown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
