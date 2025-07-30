import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'note_model.dart';

class DateNotesView extends StatefulWidget {
  final DateTime selectedDate;

  const DateNotesView({super.key, required this.selectedDate});

  @override
  State<DateNotesView> createState() => _DateNotesViewState();
}

class _DateNotesViewState extends State<DateNotesView> {
  final Color lightPastelBrown = Colors.brown[100]!;
  final Color pastelBrown = Colors.brown[300]!;
  final Color darkPastelBrown = Colors.brown[700]!;
  final Color shadowPastelBrown = Colors.brown[300]!.withOpacity(0.3);

  List<Note> _notesForDate = [];
  bool _isLoading = true;

  final String apiBaseUrl = 'http://10.0.2.2/project1msyamar/getnotes.php';

  @override
  void initState() {
    super.initState();
    _loadNotesForDate();
  }

  Future<void> _loadNotesForDate() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    if (userId.isNotEmpty) {
      final url = Uri.parse('$apiBaseUrl?user_id=$userId');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(response.body);
          if (jsonResp['status'] == 'success') {
            List<dynamic> data = jsonResp['data']['notes'] ?? jsonResp['data'];
            List<Note> allNotes = data.map((item) {
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

            // Filter notes for the selected date
            List<Note> filteredNotes = allNotes.where((note) {
              return note.date.year == widget.selectedDate.year &&
                     note.date.month == widget.selectedDate.month &&
                     note.date.day == widget.selectedDate.day;
            }).toList();

            // Sort by time (newest first)
            filteredNotes.sort((a, b) => b.dateTime.compareTo(a.dateTime));

            setState(() {
              _notesForDate = filteredNotes;
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Error fetching notes: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildNoteCard(Note note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 6,
          shadowColor: shadowPastelBrown,
          child: ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.pets, color: pastelBrown),
            ),
            title: Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            subtitle: Text(
              "${note.category} - ${note.time.format(context)}\nPets: ${note.pets.join(', ')}",
              style: TextStyle(fontSize: 14, color: darkPastelBrown),
            ),
          ),
        ),
      ),
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
          icon: Icon(Icons.arrow_back, color: darkPastelBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notes for ${_formatDate(widget.selectedDate)}',
          style: TextStyle(color: pastelBrown, fontSize: 20),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(pastelBrown),
              ),
            )
          : _notesForDate.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add,
                          size: 80,
                          color: pastelBrown.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No notes found for this date",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: darkPastelBrown,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotesForDate,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _notesForDate.length,
                    itemBuilder: (context, index) {
                      return _buildNoteCard(_notesForDate[index]);
                    },
                  ),
                ),
    );
  }
}