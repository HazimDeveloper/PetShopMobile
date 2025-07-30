import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String category;
  final String date;
  final String? time;
  final List<String> pets;
  final String? priority;
  final List<String> tags;
  final String? content;
  final String? status;
  final String createdAt;
  final String? updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.time,
    required this.pets,
    this.priority,
    required this.tags,
    this.content,
    this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    List<String> petsList = [];
    List<String> tagsList = [];

    try {
      if (json['pets'] != null) {
        if (json['pets'] is String) {
          petsList = List<String>.from(jsonDecode(json['pets']));
        } else if (json['pets'] is List) {
          petsList = List<String>.from(json['pets']);
        }
      }
    } catch (e) {
      print('Error parsing pets: $e');
    }

    try {
      if (json['tags'] != null) {
        if (json['tags'] is String) {
          tagsList = List<String>.from(jsonDecode(json['tags']));
        } else if (json['tags'] is List) {
          tagsList = List<String>.from(json['tags']);
        }
      }
    } catch (e) {
      print('Error parsing tags: $e');
    }

    return Note(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled',
      category: json['category'] ?? 'General',
      date: json['date'] ?? '',
      time: json['time'],
      pets: petsList,
      priority: json['priority'],
      tags: tagsList,
      content: json['content'],
      status: json['status'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date,
      'time': time,
      'pets': jsonEncode(pets),
      'priority': priority,
      'tags': jsonEncode(tags),
      'content': content,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class NotesManagementPage extends StatefulWidget {
  const NotesManagementPage({super.key});

  @override
  _NotesManagementPageState createState() => _NotesManagementPageState();
}

class _NotesManagementPageState extends State<NotesManagementPage> {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedPriority = 'All';

  final List<String> _categories = [
    'All', 'General', 'Health', 'Feeding', 'Training', 'Grooming', 'Play', 'Vet Visit'
  ];

  final List<String> _priorities = [
    'All', 'low', 'medium', 'high'
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getCurrentUserNotes();
      
      if (result['status'] == 'success' && result['data'] != null) {
        List<dynamic> notesData = result['data'] is List 
            ? result['data'] 
            : result['data']['notes'] ?? [];
        
        List<Note> notes = notesData.map((json) => Note.fromJson(json)).toList();
        
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load notes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading notes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      final result = await ApiService.deleteNote(noteId);
      
      if (result['status'] == 'success') {
        setState(() {
          _notes.removeWhere((note) => note.id == noteId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Note> get _filteredNotes {
    return _notes.where((note) {
      bool matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          (note.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      bool matchesCategory = _selectedCategory == 'All' || note.category == _selectedCategory;
      
      bool matchesPriority = _selectedPriority == 'All' || note.priority == _selectedPriority;
      
      return matchesSearch && matchesCategory && matchesPriority;
    }).toList();
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
        return Colors.brown[400]!;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red[600]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'low':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes Management'),
        backgroundColor: Colors.brown[300],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNotes,
          ),
        ],
      ),
      backgroundColor: Colors.brown[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(
                      child: _buildNotesList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(),
        backgroundColor: Colors.brown[300],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 16, color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[300],
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search, color: Colors.brown[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Filters Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    if (_filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_outlined, size: 64, color: Colors.brown[300]),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedPriority != 'All'
                  ? 'No notes match your filters'
                  : 'No notes yet',
              style: TextStyle(fontSize: 18, color: Colors.brown[600]),
            ),
            if (_searchQuery.isEmpty && _selectedCategory == 'All' && _selectedPriority == 'All')
              TextButton(
                onPressed: () => _showAddNoteDialog(),
                child: Text('Add your first note'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                note.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (note.priority != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(note.priority),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note.priority!.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(note.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 16, color: Colors.brown[600]),
                SizedBox(width: 4),
                Text(
                  note.date,
                  style: TextStyle(color: Colors.brown[600]),
                ),
                if (note.time != null) ...[
                  SizedBox(width: 8),
                  Icon(Icons.access_time, size: 16, color: Colors.brown[600]),
                  SizedBox(width: 4),
                  Text(
                    note.time!,
                    style: TextStyle(color: Colors.brown[600]),
                  ),
                ],
              ],
            ),
            if (note.pets.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: note.pets.map((pet) {
                  return Chip(
                    label: Text(pet),
                    backgroundColor: Colors.brown[100],
                    labelStyle: TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            ],
            if (note.content != null && note.content!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                note.content!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.brown[600]),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red[600]),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditNoteDialog(note);
            } else if (value == 'delete') {
              _showDeleteConfirmation(note);
            }
          },
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    _showNoteDialog();
  }

  void _showEditNoteDialog(Note note) {
    _showNoteDialog(note: note);
  }

  void _showNoteDialog({Note? note}) {
    final isEditing = note != null;
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    final dateController = TextEditingController(text: note?.date ?? '');
    final timeController = TextEditingController(text: note?.time ?? '');
    
    String selectedCategory = note?.category ?? 'General';
    String selectedPriority = note?.priority ?? 'medium';
    List<String> selectedPets = List.from(note?.pets ?? []);
    List<String> selectedTags = List.from(note?.tags ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Note' : 'Add Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.where((c) => c != 'All').map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: _priorities.where((p) => p != 'All').map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) {
                  selectedPriority = value!;
                },
              ),
              SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || dateController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Title and date are required')),
                );
                return;
              }

              final userId = await SharedPreferences.getInstance().then((prefs) => prefs.getString('user_id') ?? '');
              
              if (isEditing) {
                final result = await ApiService.updateNote(
                  id: note.id,
                  title: titleController.text.trim(),
                  category: selectedCategory,
                  date: dateController.text.trim(),
                  time: timeController.text.trim().isEmpty ? null : timeController.text.trim(),
                  priority: selectedPriority,
                  content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                );

                if (result['status'] == 'success') {
                  Navigator.pop(context);
                  _loadNotes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note updated successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Failed to update note')),
                  );
                }
              } else {
                final result = await ApiService.addNote(
                  userId: userId,
                  title: titleController.text.trim(),
                  category: selectedCategory,
                  date: dateController.text.trim(),
                  time: timeController.text.trim().isEmpty ? null : timeController.text.trim(),
                  priority: selectedPriority,
                  content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                );

                if (result['status'] == 'success') {
                  Navigator.pop(context);
                  _loadNotes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note added successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Failed to add note')),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
} 