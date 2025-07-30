import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(home: EventPage(), debugShowCheckedModeBanner: false));
}

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  List<dynamic> events = [];
  bool isLoading = true;
  String? errorMsg;

  final TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 22,
    color: Colors.brown.shade800,
    letterSpacing: 0.6,
    shadows: [
      Shadow(
        color: Colors.brown.shade200,
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
  );

  final TextStyle subtitleStyle = TextStyle(
    fontSize: 15,
    color: Colors.brown.shade700,
    letterSpacing: 0.4,
  );

  final TextStyle descriptionPreviewStyle = TextStyle(
    fontSize: 14,
    color: Colors.brown.shade800,
    height: 1.3,
  );

  final TextStyle dialogTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: Colors.brown.shade900,
    height: 1.3,
  );

  final TextStyle dialogSubtitleStyle = TextStyle(
    fontSize: 16,
    color: Colors.brown.shade700,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  final TextStyle dialogContentStyle = TextStyle(
    fontSize: 16,
    color: Colors.brown.shade800,
    height: 1.6,
  );

  @override
  void initState() {
    super.initState();
    fetchEvents();
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
            events = data['events'];
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

  void _showEventDetails(dynamic event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.brown.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: EdgeInsets.fromLTRB(24, 12, 24, 24),
        title: Text(
          event['title'] ?? 'No title',
          style: dialogTitleStyle,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.calendar_today, 'Date', event['date']),
              SizedBox(height: 10),
              _buildInfoRow(Icons.place, 'Location', event['location']),
              SizedBox(height: 16),
              Divider(color: Colors.brown.shade200, thickness: 1.5),
              SizedBox(height: 16),
              Text(
                event['description'] ?? 'No description',
                style: dialogContentStyle,
                textAlign: TextAlign.justify,
              ),
              if (event['image_path'] != null &&
                  event['image_path'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.shade300.withOpacity(0.4),
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GestureDetector(
                          onTap: () => _showImage(
                              'http://10.0.2.2/project1msyamar/${event['image_path']}'),
                          child: Image.network(
                            'http://10.0.2.2/project1msyamar/${event['image_path']}',
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Text('Image not available'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actionsPadding: EdgeInsets.only(bottom: 12, right: 16),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              elevation: 5,
              shadowColor: Colors.brown.shade200,
            ),
            child: Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.brown.shade50,
              ),
            ),
          )
        ],
      ),
    );
  }

Widget _buildInfoRow(IconData icon, String label, String? value) {
  String displayValue;

  // Try parsing the value to see if it's a valid date
  final parsedDate = DateTime.tryParse(value ?? '');
  if (parsedDate != null) {
    displayValue = '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
  } else {
    displayValue = value ?? 'N/A'; // fallback to original value or N/A
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(icon, size: 22, color: Colors.brown.shade400),
      SizedBox(width: 10),
      Text(
        '$label:',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.brown.shade600,
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          displayValue,
          style: dialogSubtitleStyle.copyWith(fontWeight: FontWeight.normal),
        ),
      ),
    ],
  );
}


  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.95),
          alignment: Alignment.center,
          child: InteractiveViewer(
            child: Image.network(
              url,
              errorBuilder: (_, __, ___) => Text(
                'Image not available',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: Text(
          'Events',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            fontSize: 22,
            color: Colors.brown.shade900,
            shadows: [
              Shadow(
                color: Colors.brown.shade300,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.brown.shade400,
        elevation: 8,
        shadowColor: Colors.brown.shade300,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 7,
                  color: Colors.brown.shade500,
                ),
              ),
            )
          : errorMsg != null
              ? Center(
                  child: Text(
                    errorMsg!,
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : events.isEmpty
                  ? Center(
                      child: Text(
                        'No events available',
                        style: TextStyle(
                          color: Colors.brown.shade400,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => Divider(
                        color: Colors.brown.shade200,
                        thickness: 1,
                        height: 16,
                      ),
                      itemBuilder: (context, index) {
                        var event = events[index];
                        final imageUrl = event['image_path'] != null &&
                                event['image_path'].toString().isNotEmpty
                            ? 'http://10.0.2.2/project1msyamar/${event['image_path']}'
                            : null;
                        final description = event['description'] ?? '';

                        return InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => _showEventDetails(event),
                          splashColor: Colors.brown.shade300.withOpacity(0.5),
                          highlightColor: Colors.brown.shade200.withOpacity(0.3),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.brown.shade50.withOpacity(0.9),
                                  Colors.brown.shade100.withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.shade200.withOpacity(0.4),
                                  offset: Offset(0, 3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null)
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.brown.shade300
                                              .withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        imageUrl,
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 110,
                                          height: 110,
                                          color: Colors.brown.shade200,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.broken_image,
                                              color: Colors.brown.shade400),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: Colors.brown.shade200,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.image_not_supported,
                                        color: Colors.brown.shade400, size: 32),
                                  ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'] ?? 'No title',
                                        style: titleStyle,
                                      ),
                                      SizedBox(height: 10),
                                      Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Icon(Icons.calendar_today, size: 18, color: Colors.brown.shade500),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            event['date'] ?? 'N/A',
            style: subtitleStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    SizedBox(height: 6),
    Row(
      children: [
        Icon(Icons.place, size: 18, color: Colors.brown.shade500),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            event['location'] ?? 'N/A',
            style: subtitleStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ],
),

                                      if (description.isNotEmpty) ...[
                                        SizedBox(height: 12),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.brown.shade50
                                                .withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            description,
                                            style: descriptionPreviewStyle,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    size: 18, color: Colors.brown.shade400),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
