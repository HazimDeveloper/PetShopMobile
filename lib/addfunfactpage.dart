import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Fun Facts',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const AddFunFactPage(),
    );
  }
}

class AddFunFactPage extends StatefulWidget {
  const AddFunFactPage({super.key});

  @override
  _AddFunFactPageState createState() => _AddFunFactPageState();
}

class _AddFunFactPageState extends State<AddFunFactPage> {
  final List<FunFact> _funFacts = [];
  final Uri url = Uri.parse('http://10.0.2.2/project1msyamar/funfect.php');
  
  final Color backgroundColor = const Color(0xFFF8F1E7);
  final Color cardColor = const Color(0xFFF5EFE6);
  final Color borderColor = const Color(0xFFB89A82);
  final Color textColor = const Color(0xFF8B5E3C);
  final Color highlightColor = const Color(0xFFB89A82);
  final Color buttonColor = const Color(0xFFB89A82);

  @override
  void initState() {
    super.initState();
    _fetchFunFacts();
  }

  Future<void> _fetchFunFacts() async {
    try {
      final response = await http.get(Uri.parse('${url.toString()}?action=list'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _funFacts.clear();
          for (var item in data) {
            _funFacts.add(FunFact(
              id: int.tryParse(item['id'].toString()) ?? 0,
              icon: item['icon'] ?? '',
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              imagePath: item['image_path'], // Server relative path
            ));
          }
        });
      } else {
        print('Failed to load fun facts: ${response.statusCode}');
        _showErrorSnackBar('Failed to load fun facts');
      }
    } catch (e) {
      print('Error fetching fun facts: $e');
      _showErrorSnackBar('Error fetching fun facts: $e');
    }
  }

  // Replace the _saveFunFact method in addfunfactpage.dart

Future<bool> _saveFunFact(FunFact fact, {int? index}) async {
  try {
    if (index == null) {
      // CREATE NEW FUN FACT
      var request = http.MultipartRequest(
        'POST',
        url.replace(queryParameters: {'action': 'create'}),
      );
      request.fields['icon'] = fact.icon;
      request.fields['title'] = fact.title;
      request.fields['description'] = fact.description;

      if (fact.imagePath != null && fact.imagePath!.isNotEmpty && File(fact.imagePath!).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('image', fact.imagePath!));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create response status: ${response.statusCode}');
      print('Create response body: "${response.body}"');

      if (response.statusCode == 200) {
        // Check if response body is empty
        if (response.body.trim().isEmpty) {
          print('Empty response body received');
          return false;
        }
        
        try {
          var resBody = json.decode(response.body);
          if (resBody['success'] == true) {
            await _fetchFunFacts();
            return true;
          } else {
            print('Server returned error: ${resBody['message'] ?? 'Unknown error'}');
          }
        } catch (e) {
          print('JSON decode error: $e');
          print('Response body was: "${response.body}"');
          return false;
        }
      }
    } else {
      // EDIT EXISTING FUN FACT
      var request = http.MultipartRequest(
        'POST',
        url.replace(queryParameters: {
          'action': 'update',
          'id': fact.id.toString(),
        }),
      );
      
      // Add form fields
      request.fields['icon'] = fact.icon;
      request.fields['title'] = fact.title;
      request.fields['description'] = fact.description;
      request.fields['id'] = fact.id.toString();

      // Handle image if changed
      if (fact.imagePath != null && 
          fact.imagePath!.isNotEmpty && 
          File(fact.imagePath!).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('image', fact.imagePath!));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update response status: ${response.statusCode}');
      print('Update response body: "${response.body}"');
      print('Update response headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Check if response body is empty
        if (response.body.trim().isEmpty) {
          print('Empty response body received - this indicates a PHP error');
          return false;
        }
        
        try {
          var resBody = json.decode(response.body);
          if (resBody['success'] == true) {
            await _fetchFunFacts();
            return true;
          } else {
            print('Server returned error: ${resBody['message'] ?? 'Unknown error'}');
          }
        } catch (e) {
          print('JSON decode error: $e');
          print('Response body was: "${response.body}"');
          return false;
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return false;
      }
    }
  } catch (e) {
    print('Error saving fun fact: $e');
  }
  return false;
}

  Future<bool> _deleteFunFactBackend(int id) async {
    try {
      final response = await http.delete(url.replace(queryParameters: {'action': 'delete', 'id': id.toString()}));
      if (response.statusCode == 200) {
        var resBody = json.decode(response.body);
        if (resBody['success'] == true) {
          await _fetchFunFacts();
          return true;
        } else {
          print('Delete failed: ${resBody['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      print('Error deleting fun fact: $e');
    }
    return false;
  }

  void _navigateToNewFunFactPage({FunFact? existingFact, int? index}) async {
    await showDialog(
      context: context,
      builder: (context) => FunFactModal(
        fact: existingFact,
        index: index,
        onSave: (newFact) async {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(
                color: buttonColor,
              ),
            ),
          );

          try {
            bool success = await _saveFunFact(
              existingFact == null ? newFact : newFact.copyWith(id: existingFact.id),
              index: index,
            );
            
            // Close loading indicator
            Navigator.pop(context);
            
            if (success) {
              Navigator.pop(context); // Close the modal
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(existingFact == null ? 'Fun fact added successfully!' : 'Fun fact updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to ${existingFact == null ? 'add' : 'update'} fun fact. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            // Close loading indicator
            Navigator.pop(context);
            
            print('Error in onSave: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        textColor: textColor,
        highlightColor: highlightColor,
        buttonColor: buttonColor,
      ),
    );
  }

  void _deleteFunFact(int index) async {
    final funFactToDelete = _funFacts[index];
    
    if (funFactToDelete.id != 0) {
      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Fun Fact'),
          content: Text('Are you sure you want to delete "${funFactToDelete.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(color: buttonColor),
          ),
        );

        bool success = await _deleteFunFactBackend(funFactToDelete.id);
        
        // Close loading indicator
        Navigator.pop(context);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fun fact deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete fun fact'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Fun Facts'),
        backgroundColor: buttonColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchFunFacts,
          ),
        ],
      ),
      backgroundColor: cardColor,
      body: Column(
        children: [
          Expanded(
            child: _funFacts.isEmpty
                ? Center(
                    child: Text(
                      'No fun facts available',
                      style: TextStyle(fontSize: 18, color: Colors.brown.shade400),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _funFacts.length,
                    itemBuilder: (context, index) {
                      final fact = _funFacts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          color: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fact.imagePath != null && fact.imagePath!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Image.network(
                                    'http://10.0.2.2/project1msyamar/${fact.imagePath}',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.error, size: 50),
                                      );
                                    },
                                  ),
                                )
                              else
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  ),
                                  child: Icon(Icons.image_not_supported, size: 50),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: highlightColor.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          fact.icon,
                                          style: TextStyle(fontSize: 24),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          fact.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      fact.description,
                                      style: TextStyle(color: textColor.withOpacity(0.8)),
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'Edit') {
                                        _navigateToNewFunFactPage(existingFact: fact, index: index);
                                      } else if (value == 'Delete') {
                                        _deleteFunFact(index);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'Edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: textColor),
                                            SizedBox(width: 8),
                                            Text('Edit', style: TextStyle(color: textColor)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'Delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _navigateToNewFunFactPage(),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Add New Fun Fact',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FunFact {
  final int id;
  final String icon;
  final String title;
  final String description;
  final String? imagePath;

  FunFact({
    this.id = 0,
    required this.icon,
    required this.title,
    required this.description,
    this.imagePath,
  });

  FunFact copyWith({
    int? id,
    String? icon,
    String? title,
    String? description,
    String? imagePath,
  }) {
    return FunFact(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class FunFactModal extends StatefulWidget {
  final FunFact? fact;
  final int? index;
  final Future<void> Function(FunFact) onSave;

  final Color textColor;
  final Color highlightColor;
  final Color buttonColor;

  const FunFactModal({
    super.key,
    this.fact,
    this.index,
    required this.onSave,
    required this.textColor,
    required this.highlightColor,
    required this.buttonColor,
  });

  @override
  _FunFactModalState createState() => _FunFactModalState();
}

class _FunFactModalState extends State<FunFactModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIcon = '';
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.fact != null) {
      _selectedIcon = widget.fact!.icon;
      _titleController.text = widget.fact!.title;
      _descriptionController.text = widget.fact!.description;
      _imagePath = widget.fact!.imagePath;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
        print('Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.fact == null ? 'Add New Fun Fact' : 'Edit Fun Fact',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.textColor),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon selection
              Wrap(
                alignment: WrapAlignment.center,
                children: ['🐶', '🐱', '🐦', '🐟'].map((icon) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _selectedIcon == icon ? widget.highlightColor : Colors.grey),
                          borderRadius: BorderRadius.circular(15),
                          color: _selectedIcon == icon ? widget.highlightColor.withOpacity(0.3) : Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            icon,
                            style: TextStyle(
                              fontSize: 32,
                              color: _selectedIcon == icon ? widget.highlightColor : Colors.black,
                              fontWeight: _selectedIcon == icon ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Title field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Enter Title',
                  labelStyle: TextStyle(color: widget.textColor),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.highlightColor)),
                  border: OutlineInputBorder(borderSide: BorderSide(color: widget.highlightColor)),
                ),
              ),
              const SizedBox(height: 12),
              
              // Description field
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Enter Description',
                  labelStyle: TextStyle(color: widget.textColor),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.highlightColor)),
                  border: OutlineInputBorder(borderSide: BorderSide(color: widget.highlightColor)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              
              // Image display and selection
              if (_imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _imagePath!.startsWith('http') || _imagePath!.startsWith('uploads/')
                      ? Image.network(
                          _imagePath!.startsWith('http') 
                              ? _imagePath! 
                              : 'http://10.0.2.2/project1msyamar/$_imagePath',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: Icon(Icons.error),
                            );
                          },
                        )
                      : Image.file(
                          File(_imagePath!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                ),
              
              // Image selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Save button
              ElevatedButton(
                onPressed: () async {
                  if (_selectedIcon.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an icon')),
                    );
                    return;
                  }
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }
                  if (_descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a description')),
                    );
                    return;
                  }

                  final fact = FunFact(
                    id: widget.fact?.id ?? 0,
                    icon: _selectedIcon,
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    imagePath: _imagePath,
                  );
                  await widget.onSave(fact);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.buttonColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.fact == null ? 'Save' : 'Update',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}