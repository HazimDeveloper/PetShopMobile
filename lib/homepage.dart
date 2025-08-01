import 'package:flutter/material.dart';
import 'package:fyp/profile.dart';
import 'package:fyp/profile_management.dart';
import 'package:fyp/test_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'addnote.dart';
import 'eventpage.dart';
import 'funfactpage.dart';
import 'love.dart';
import 'date_notes_view.dart';
import 'note_model.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final Color lightPastelBrown = Colors.brown[100]!;
  final Color pastelBrown = Colors.brown[300]!;
  final Color darkPastelBrown = Colors.brown[700]!;
  final Color shadowPastelBrown = Colors.brown[300]!.withOpacity(0.3);

  final List<Note> _notes = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  Timer? _tipTimer;

  List<List<Color>> brownThemes = [
    [Colors.brown[300]!, Colors.brown[100]!],
    [Colors.brown[400]!, Colors.brown[50]!],
    [Colors.brown[200]!, Colors.brown[100]!],
  ];

  late List<Color> currentTheme;

  int _tipIndex = 0;
  final List<String> _dailyTips = [
    "Give your pet a fun new toy this week! 🧸",
    "Remember to schedule your pet's vet check-up. 🩺",
    "Keep fresh water available all day for your furry friend. 💧",
    "Try teaching your pet a new trick today! 🐾",
    "Spend quality time walking your pet for better bonding. 🚶‍♂️",
  ];

  final String apiBaseUrl = 'http://10.0.2.2/project1msyamar/getnotes.php';

  @override
  void initState() {
    super.initState();

    currentTheme = brownThemes[Random().nextInt(brownThemes.length)];

    _loadNotes();
    _checkFirstLaunch();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _showDailyQuote();
    });

    _startDailyTipCycle();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _startDailyTipCycle() {
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      safeSetState(() {
        _tipIndex = (_tipIndex + 1) % _dailyTips.length;
      });
    });
  }

  Future<void> _loadNotes() async {
    try {
      final result = await ApiService.getCurrentUserNotes();
      
      if (result['status'] == 'success' && result['data'] != null) {
        List<dynamic> notesData = result['data'] is List 
            ? result['data'] 
            : result['data']['notes'] ?? [];
        
        List<Note> loadedNotes = notesData.map((item) {
          try {
            return Note.fromJson(item);
          } catch (e) {
            print('Error parsing note: $e');
            return Note(
              title: item['title'] ?? 'Untitled',
              category: item['category'] ?? 'General',
              date: DateTime.now(),
              time: const TimeOfDay(hour: 0, minute: 0),
              pets: [],
            );
          }
        }).toList();

        setState(() {
          _notes.clear();
          _notes.addAll(loadedNotes);
        });
      } else {
        print('API Error: ${result['message'] ?? 'Unknown error'}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load notes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching notes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load notes. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? firstLaunch = prefs.getBool('firstLaunch');
    if (firstLaunch == null || firstLaunch == true) {
      await prefs.setBool('firstLaunch', false);
      if (!mounted) return;
      _showFirstTimeTip();
    }
  }

  void _showDailyQuote() {
    if (!mounted) return;
    showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: '',
      context: context,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: _buildStyledPopup(
            title: "🌟 Daily Quote",
            message: "✨ \"Small steps every day lead to big changes!\" ✨",
          ),
        );
      },
    );
  }

  void _showFirstTimeTip() {
    if (!mounted) return;
    showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: '',
      context: context,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: _buildStyledPopup(
            title: "👋 Welcome!",
            message: "Tap 'Add New Note' to start jotting down your day! 📒",
          ),
        );
      },
    );
  }

  void _checkMilestone() {
    if (!mounted) return;
    int count = _notes.length;
    if ([5, 10, 20].contains(count)) {
      showGeneralDialog(
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, anim1, anim2, child) {
          return ScaleTransition(scale: anim1, child: child);
        },
        pageBuilder: (context, anim1, anim2) {
          return Center(
            child: _buildStyledPopup(
              title: "🎉 Achievement",
              message: "You've written $count notes! You're on fire! 🔥",
            ),
          );
        },
      );
    }
  }

  Widget _buildStyledPopup({required String title, required String message}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: currentTheme,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 5),
            Text(title,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: darkPastelBrown)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: darkPastelBrown)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pastelBrown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () {
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("OK 🧸", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String getGreeting() {
    return 'Good Morning, ${widget.username}';
  }

  void _navigateToAddNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNotePage()),
    );
    _loadNotes();  // Reload the notes after adding a new one
  }

  List<Note> get _filteredNotes {
    return _notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             note.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // NEW: Edit note functionality
  void _editNote(Note note, int index) {
    _showEditNoteDialog(note, index);
  }

  void _showEditNoteDialog(Note note, int index) {
    final titleController = TextEditingController(text: note.title);
    final categoryController = TextEditingController(text: note.category);
    String selectedCategory = note.category;
    DateTime selectedDate = note.date;
    TimeOfDay selectedTime = note.time;
    List<String> selectedPets = List.from(note.pets);

    final categories = [
      'General', 'Health', 'Feeding', 'Training', 'Grooming', 'Play', 'Vet Visit'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.edit, color: pastelBrown),
              SizedBox(width: 8),
              Text('Edit Note', style: TextStyle(color: darkPastelBrown)),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title field
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title, color: pastelBrown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelBrown, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category, color: pastelBrown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: pastelBrown, width: 2),
                      ),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Date and Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(Duration(days: 365)),
                              lastDate: DateTime.now().add(Duration(days: 365)),
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
                            if (pickedDate != null) {
                              setDialogState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: pastelBrown, size: 20),
                                SizedBox(width: 8),
                                Text(_formatDate(selectedDate)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
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
                            if (pickedTime != null) {
                              setDialogState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: pastelBrown, size: 20),
                                SizedBox(width: 8),
                                Text(selectedTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Pets display (simplified for edit dialog)
                  if (selectedPets.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pets: ${selectedPets.join(', ')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Title cannot be empty')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _updateNote(note, titleController.text.trim(), selectedCategory, selectedDate, selectedTime, selectedPets);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: pastelBrown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNote(Note originalNote, String title, String category, DateTime date, TimeOfDay time, List<String> pets) async {
    try {
      // Find the original note in the list to get its ID (assuming it has an ID field)
      // For now, we'll use a simple approach by finding the matching note
      int noteIndex = _notes.indexWhere((n) => 
        n.title == originalNote.title && 
        n.date == originalNote.date && 
        n.time == originalNote.time
      );

      if (noteIndex == -1) {
        throw Exception('Note not found');
      }

      // Using a simple HTTP request to update the note
      // You might need to add an ID field to your Note model to make this more robust
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      final response = await http.post(
        Uri.parse('http://10.0.2.2/project1msyamar/notes.php?action=edit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': noteIndex + 1, // This is a workaround - you should have proper IDs
          'title': title,
          'category': category,
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'pets': jsonEncode(pets),
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          // Update the local note
          setState(() {
            _notes[noteIndex] = Note(
              title: title,
              category: category,
              date: date,
              time: time,
              pets: pets,
            );
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note updated successfully! 📝'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          throw Exception(result['message'] ?? 'Failed to update note');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update note: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // NEW: Delete note functionality
  void _deleteNote(Note note, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Delete Note', style: TextStyle(color: Colors.red[700])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this note?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${note.category} • ${_formatDate(note.date)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteNote(note, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteNote(Note note, int index) async {
    try {
      // Using a simple HTTP request to delete the note
      final response = await http.post(
        Uri.parse('http://10.0.2.2/project1msyamar/notes.php?action=delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': index + 1, // This is a workaround - you should have proper IDs
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          // Remove from local list
          setState(() {
            _notes.removeAt(index);
            _checkMilestone();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note deleted successfully! 🗑️'),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: () {
                  // You could implement undo functionality here
                  setState(() {
                    _notes.insert(index, note);
                  });
                },
              ),
            ),
          );
        } else {
          throw Exception(result['message'] ?? 'Failed to delete note');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete note: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget buildNoteCard(Note note, int filteredIndex) {
    final actualIndex = _notes.indexWhere((n) => 
      n.title == note.title && 
      n.date == note.date && 
      n.time == note.time
    );

    Color categoryColor = _getCategoryColor(note.category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DateNotesView(selectedDate: note.date),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 60,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    note.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: darkPastelBrown,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    note.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  "${_formatDate(note.date)} • ${note.time.format(context)}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (note.pets.isNotEmpty) ...[ 
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.pets, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      note.pets.join(', '),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // NEW: Edit and Delete buttons
                      Column(
                        children: [
                          InkWell(
                            onTap: () => _editNote(note, actualIndex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          InkWell(
                            onTap: () => _deleteNote(note, actualIndex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.red[400]!;
      case 'feeding':
        return Colors.green[400]!;
      case 'training':
        return Colors.blue[400]!;
      case 'grooming':
        return Colors.orange[400]!;
      case 'play':
        return Colors.purple[400]!;
      case 'vet visit':
        return Colors.teal[400]!;
      default:
        return pastelBrown;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today';
    } else if (noteDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "                           Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkPastelBrown,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _quickActionButton(Icons.note_add, "Add Note", pastelBrown, _navigateToAddNote),
              _quickActionButton(Icons.event_available, "Events", Colors.blue[400]!, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EventPage()));
              }),
              _quickActionButton(Icons.lightbulb_outline, "Fun Facts", Colors.orange[400]!, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserFunFactPage()));
              }),
              _quickActionButton(Icons.chat_bubble_outline, "AI Chat", Colors.purple[400]!, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LovePage()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    IconData icon, String label, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80, // Smaller width for 4 buttons
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowPastelBrown,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkPastelBrown,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatsSection() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Expanded(child: _buildStatCard("Total Notes", _notes.length.toString(), Icons.note, pastelBrown)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("This Week", _getWeeklyNotes().toString(), Icons.event, Colors.blue[400]!)), // Changed here
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Categories", _getUniqueCategories().toString(), Icons.category, Colors.orange[400]!)),
      ],
    ),
  );
}

Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: shadowPastelBrown,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkPastelBrown,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget _buildNotesHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "Your Notes",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkPastelBrown,
        ),
      ),
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.filter_list, color: pastelBrown),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: Icon(Icons.sort, color: pastelBrown),
            onPressed: _showSortOptions,
          ),
        ],
      ),
    ],
  );
}

Widget _buildDailyTipCard() {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 6,
    shadowColor: shadowPastelBrown,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.white, lightPastelBrown.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pastelBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb_outline, color: pastelBrown, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daily Tip",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkPastelBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dailyTips[_tipIndex],
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: darkPastelBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

int _getWeeklyNotes() {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  return _notes.where((note) => note.date.isAfter(weekStart.subtract(const Duration(days: 1)))).length;
}

int _getUniqueCategories() {
  return _notes.map((note) => note.category).toSet().length;
}

void _showBottomSheetMenu() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          color: lightPastelBrown,
        ),
        child: Wrap(
          children: [
            _buildMenuItem(Icons.person, "Profile Settings", () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileManagementPage()))),
            _buildMenuItem(Icons.pets, "Manage Pets", () => Navigator.push(context, MaterialPageRoute(builder: (_) => PetPage()))),
            _buildMenuItem(Icons.logout, "Logout", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()))),
          ],
        ),
      );
    },
  );
}

void _showFilterOptions() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filter Notes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkPastelBrown,
              ),
            ),
            const SizedBox(height: 16),
            _filterOption("All Notes", () => _applyFilter(null)),
            _filterOption("Today", () => _applyFilter("today")),
            _filterOption("This Week", () => _applyFilter("week")),
            _filterOption("Health", () => _applyFilter("Health")),
            _filterOption("Feeding", () => _applyFilter("Feeding")),
            _filterOption("Training", () => _applyFilter("Training")),
          ],
        ),
      );
    },
  );
}

Widget _filterOption(String title, VoidCallback onTap) {
  return ListTile(
    title: Text(title),
    onTap: () {
      Navigator.pop(context);
      onTap();
    },
  );
}

void _applyFilter(String? filter) {
  setState(() {
    if (filter == null) {
      _searchQuery = '';
    } else if (filter == "today") {
      _searchQuery = '';
    } else if (filter == "week") {
      _searchQuery = '';
    } else {
      _searchQuery = filter;
    }
  });
}

void _showSortOptions() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sort Notes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkPastelBrown,
              ),
            ),
            const SizedBox(height: 16),
            _filterOption("Newest First", () => _applySorting("newest")),
            _filterOption("Oldest First", () => _applySorting("oldest")),
            _filterOption("By Category", () => _applySorting("category")),
            _filterOption("By Title", () => _applySorting("title")),
          ],
        ),
      );
    },
  );
}

void _applySorting(String sortType) {
  setState(() {
    // Sorting logic goes here
  });
}


Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon, color: darkPastelBrown),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    onTap: () {
      Navigator.pop(context);
      onTap();
    },
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: lightPastelBrown,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: darkPastelBrown),
        onPressed: _showBottomSheetMenu,
      ),
      title: Text(
        getGreeting(),
        style: TextStyle(color: pastelBrown, fontSize: 24),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PetPage()), // Replace with your actual ProfilePage
            );
          },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 27,
              backgroundImage: const AssetImage('images/pet_avatar.png'),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    ),
    body: FadeTransition(
      opacity: _fadeIn,
      child: RefreshIndicator(
        onRefresh: () async => _loadNotes(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            const SizedBox(height: 16),
            const SizedBox(height: 12),
            _buildQuickActions(),
            _buildStatsSection(),
            _buildDailyTipCard(),
            const SizedBox(height: 20),
            _buildNotesHeader(),
            const SizedBox(height: 10),
            _filteredNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text("No notes found. Try adding or searching notes.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: darkPastelBrown, fontSize: 18)),
                    ),
                  )
                : Column(children: List.generate(_filteredNotes.length, (i) => buildNoteCard(_filteredNotes[i], i))),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}
}