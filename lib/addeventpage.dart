import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Admin Events',
    theme: ThemeData(primarySwatch: Colors.brown),
    home: AddEventPage(),
  ));
}

// ------------------- AddEventPage -------------------
class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    final url = Uri.parse('http://10.0.2.2/project1msyamar/fetch_event.php');

    try {
      final response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            events = List<Map<String, dynamic>>.from(data['events']);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMsg = data['message'] ?? 'Failed to load events';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToNewEventPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewEventPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        events.add(result);
      });
    }
  }

  Future<bool> deleteEventFromServer(int id) async {
    final uri = Uri.parse('http://10.0.2.2/project1msyamar/delete_event.php');
    try {
      final response = await http.post(uri, body: {'id': id.toString()});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
    } catch (e) {
      print('Delete request error: $e');
    }
    return false;
  }

  void _showEventOptions(Map<String, dynamic> event, int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.info),
                title: Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showEventDetails(event);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () async {
                  Navigator.pop(context);
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditEventPage(event: event)),
                  );
                  if (updated != null && updated is Map<String, dynamic>) {
                    setState(() {
                      events[index] = updated;
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);
                  bool success = await deleteEventFromServer(event['id']);
                  if (success) {
                    setState(() {
                      events.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Event deleted successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete event')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEventDetails(dynamic event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(event['title'] ?? 'No title'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text('Date: ${event['date']}'),
              Text('Location: ${event['location']}'),
              SizedBox(height: 10),
              Text(event['description'] ?? 'No description'),
              if (event['image_path'] != null && event['image_path'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onTap: () => _showImage('http://10.0.2.2/project1msyamar/${event['image_path']}'),
                    child: Image.network(
                      'http://10.0.2.2/project1msyamar/${event['image_path']}',
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text('Image not available'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          )
        ],
      ),
    );
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: InteractiveViewer(
            child: Image.network(
              url,
              errorBuilder: (_, __, ___) => Text('Image not available', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Colors.brown[100]!;
    final Color appBarColor = Colors.brown[300]!;
    final Color textColor = Colors.brown[700]!;
    final Color cardColor = Colors.white.withOpacity(0.85);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Events'),
        backgroundColor: appBarColor,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadEvents)
        ],
      ),
      backgroundColor: backgroundColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? Center(
                  child: Text(
                    'No events available',
                    style: TextStyle(fontSize: 18, color: Colors.brown[300]),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      color: cardColor,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event["image_path"] != null && event["image_path"].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              child: Image.network(
                                'http://10.0.2.2/project1msyamar/${event["image_path"]}',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            SizedBox(height: 150),
                          ListTile(
                            title: Text(
                              event["title"] ?? "",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event["date"] ?? ""),
                                Text(event["location"] ?? "", style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                            trailing: Icon(Icons.more_vert),
                            onTap: () => _showEventOptions(event, index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewEventPage,
        backgroundColor: appBarColor,
        child: Icon(Icons.add),
      ),
    );
  }
}

// -------------------- NewEventPage -------------------
class NewEventPage extends StatefulWidget {
  const NewEventPage({super.key});

  @override
  _NewEventPageState createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  File? _selectedImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _dateController.text =
              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
        });
      }
    }
  }

  Future<bool> uploadEventToServer() async {
    if (_selectedImage == null) return false;

    final uri = Uri.parse('http://10.0.2.2/project1msyamar/save_event.php');
    var request = http.MultipartRequest('POST', uri);

    request.fields['title'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['location'] = _locationController.text;
    request.fields['date'] = _dateController.text;

    var fileStream = http.ByteStream(_selectedImage!.openRead());
    var length = await _selectedImage!.length();

    var multipartFile = http.MultipartFile(
      'image',
      fileStream,
      length,
      filename: path.basename(_selectedImage!.path),
      contentType: MediaType('image', 'jpeg'),
    );

    request.files.add(multipartFile);

    var response = await request.send();

    return response.statusCode == 200;
  }

  void _saveEvent() async {
    if (_titleController.text.isEmpty || _dateController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields and select an image')),
      );
      return;
    }

    bool success = await uploadEventToServer();

    if (success) {
      Navigator.pop(context, {
        "title": _titleController.text,
        "description": _descriptionController.text,
        "location": _locationController.text,
        "date": _dateController.text,
        "image": _selectedImage!.path,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload event. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Event"),
        backgroundColor: Colors.brown[300],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.brown[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.brown, width: 1),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Icon(Icons.add_a_photo, color: Colors.brown, size: 50),
                      ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField(_titleController, "Event Title", Icons.event),
                    _buildTextField(_descriptionController, "Description", Icons.description),
                    _buildTextField(_locationController, "Location", Icons.location_on),
                    TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: "Date & Time",
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.brown[300]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      readOnly: true,
                      onTap: _selectDateTime,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[300],
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Save Event", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.brown[300]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// -------------------- EditEventPage -------------------
class EditEventPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EditEventPage({super.key, required this.event});

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _dateController;
  File? _selectedImage;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event['title']);
    _descriptionController = TextEditingController(text: widget.event['description']);
    _locationController = TextEditingController(text: widget.event['location']);
    _dateController = TextEditingController(text: widget.event['date']);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageChanged = true;
      });
    }
  }

  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _dateController.text =
              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
        });
      }
    }
  }

  Future<bool> uploadUpdatedEvent() async {
    final uri = Uri.parse('http://10.0.2.2/project1msyamar/edit_event.php');
    var request = http.MultipartRequest('POST', uri);

    request.fields['id'] = widget.event['id'].toString();
    request.fields['title'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['location'] = _locationController.text;
    request.fields['date'] = _dateController.text;

    if (_imageChanged && _selectedImage != null) {
      var fileStream = http.ByteStream(_selectedImage!.openRead());
      var length = await _selectedImage!.length();
      var multipartFile = http.MultipartFile(
        'image',
        fileStream,
        length,
        filename: path.basename(_selectedImage!.path),
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    var response = await request.send();
    return response.statusCode == 200;
  }

  void _saveEdits() async {
    if (_titleController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    bool success = await uploadUpdatedEvent();

    if (success) {
      Navigator.pop(context, {
        'id': widget.event['id'],
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'date': _dateController.text,
        'image': _imageChanged && _selectedImage != null
            ? _selectedImage!.path
            : widget.event['image'],
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = Colors.brown[300]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Event'),
        backgroundColor: appBarColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.brown[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.brown, width: 1),
                ),
                child: _imageChanged && _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : (widget.event['image'] != null && widget.event['image'].toString().isNotEmpty)
                        ? (widget.event['image'].toString().startsWith('http')
                            ? Image.network(widget.event['image'], fit: BoxFit.cover)
                            : Image.file(File(widget.event['image']), fit: BoxFit.cover))
                        : Center(
                            child: Icon(Icons.add_a_photo, color: Colors.brown, size: 50),
                          ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField(_titleController, "Event Title", Icons.event),
                    _buildTextField(_descriptionController, "Description", Icons.description),
                    _buildTextField(_locationController, "Location", Icons.location_on),
                    TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: "Date & Time",
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.brown[300]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      readOnly: true,
                      onTap: _selectDateTime,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEdits,
              style: ElevatedButton.styleFrom(
                backgroundColor: appBarColor,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Update Event", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.brown[300]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
