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
        print('Failed to load fun facts');
      }
    } catch (e) {
      print('Error fetching fun facts: $e');
    }
  }

  Future<bool> _saveFunFact(FunFact fact, {int? index}) async {
    try {
      if (index == null) {
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

        if (response.statusCode == 200) {
          var resBody = json.decode(response.body);
          if (resBody['success'] == true) {
            await _fetchFunFacts();
            return true;
          }
        }
      } else {
        String? base64Image;
        if (fact.imagePath != null &&
            fact.imagePath!.isNotEmpty &&
            File(fact.imagePath!).existsSync()) {
          final bytes = await File(fact.imagePath!).readAsBytes();
          base64Image = 'data:image/${fact.imagePath!.split('.').last};base64,${base64Encode(bytes)}';
        }

        final body = json.encode({
          'icon': fact.icon,
          'title': fact.title,
          'description': fact.description,
          'imageBase64': base64Image ?? '', 
        });

        final response = await http.put(
          url.replace(queryParameters: {
            'action': 'update',
            'id': fact.id.toString(),
          }),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 200) {
          var resBody = json.decode(response.body);
          if (resBody['success'] == true) {
            await _fetchFunFacts();
            return true;
          }
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
          bool success = await _saveFunFact(
            existingFact == null ? newFact : newFact.copyWith(id: existingFact.id),
            index: index,
          );
          if (success) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save fun fact')),
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
      bool success = await _deleteFunFactBackend(funFactToDelete.id);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete fun fact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Fun Facts'),
        backgroundColor: buttonColor,
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
                              fact.imagePath != null && fact.imagePath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                      child: Image.network(
                                        'http://10.0.2.2/project1msyamar/${fact.imagePath}',
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const SizedBox(height: 150),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ListTile(
                                  title: Text(
                                    fact.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    fact.description,
                                    style: TextStyle(color: textColor.withOpacity(0.8)),
                                  ),
                                  trailing: PopupMenuButton<String>( // For edit and delete options
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
                                        child: Text('Edit', style: TextStyle(color: textColor)),
                                      ),
                                      PopupMenuItem(
                                        value: 'Delete',
                                        child: Text('Delete', style: TextStyle(color: textColor)),
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
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
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
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Enter Description',
                  labelStyle: TextStyle(color: widget.textColor),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.highlightColor)),
                  border: OutlineInputBorder(borderSide: BorderSide(color: widget.highlightColor)),
                ),
              ),
              const SizedBox(height: 12),
              if (_imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imagePath!),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
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
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
