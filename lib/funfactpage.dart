import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserFunFactPage extends StatefulWidget {
  const UserFunFactPage({super.key});

  @override
  _UserFunFactPageState createState() => _UserFunFactPageState();
}

class _UserFunFactPageState extends State<UserFunFactPage> {
  List<dynamic> funFacts = [];
  bool isLoading = true;
  String? errorMsg;

  final Uri apiUrl = Uri.parse('http://10.0.2.2/project1msyamar/fetch_fun.php?action=list');

  final TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
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

  final TextStyle dialogContentStyle = TextStyle(
    fontSize: 16,
    color: Colors.brown.shade800,
    height: 1.6,
  );

  @override
  void initState() {
    super.initState();
    fetchFunFacts();
  }

  Future<void> fetchFunFacts() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            funFacts = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMsg = data['message'] ?? 'Failed to load fun facts';
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

  void _showFunFactDetails(dynamic fact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.brown.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: EdgeInsets.fromLTRB(24, 12, 24, 24),
        title: Column(
          children: [
            if (fact['icon'] != null && fact['icon'].toString().isNotEmpty)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.brown.shade200.withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade400.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  fact['icon'],
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.brown.shade700,
                    height: 1,
                  ),
                ),
              ),
            SizedBox(height: 12),
            Text(
              fact['title'] ?? 'No title',
              style: dialogTitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fact['description'] ?? 'No description',
                style: dialogContentStyle,
                textAlign: TextAlign.justify,
              ),
              if (fact['image_path'] != null &&
                  fact['image_path'].toString().isNotEmpty)
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
                              'http://10.0.2.2/project1msyamar/${fact['image_path']}'),
                          child: Image.network(
                            'http://10.0.2.2/project1msyamar/${fact['image_path']}',
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
          'Fun Facts',
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
              : funFacts.isEmpty
                  ? Center(
                      child: Text(
                        'No fun facts available',
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
                      itemCount: funFacts.length,
                      separatorBuilder: (_, __) => Divider(
                        color: Colors.brown.shade200,
                        thickness: 1,
                        height: 16,
                      ),
                      itemBuilder: (context, index) {
                        var fact = funFacts[index];
                        final imageUrl = fact['image_path'] != null &&
                                fact['image_path'].toString().isNotEmpty
                            ? 'http://10.0.2.2/project1msyamar/${fact['image_path']}'
                            : null;
                        final description = fact['description'] ?? '';

                        return _AnimatedFunFactCard(
                          fact: fact,
                          imageUrl: imageUrl,
                          description: description,
                          titleStyle: titleStyle,
                          descriptionPreviewStyle: descriptionPreviewStyle,
                          onTap: () => _showFunFactDetails(fact),
                        );
                      },
                    ),
    );
  }
}

class _AnimatedFunFactCard extends StatefulWidget {
  final dynamic fact;
  final String? imageUrl;
  final String description;
  final TextStyle titleStyle;
  final TextStyle descriptionPreviewStyle;
  final VoidCallback onTap;

  const _AnimatedFunFactCard({
    super.key,
    required this.fact,
    this.imageUrl,
    required this.description,
    required this.titleStyle,
    required this.descriptionPreviewStyle,
    required this.onTap,
  });

  @override
  __AnimatedFunFactCardState createState() => __AnimatedFunFactCardState();
}

class __AnimatedFunFactCardState extends State<_AnimatedFunFactCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  bool _pressed = false;

  void _onTapDown(_) {
    setState(() {
      _scale = 0.97;
      _pressed = true;
    });
  }

  void _onTapUp(_) {
    setState(() {
      _scale = 1.0;
      _pressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_scale),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed
                ? [
                    Colors.brown.shade200.withOpacity(0.9),
                    Colors.brown.shade300.withOpacity(0.9),
                  ]
                : [
                    Colors.brown.shade50.withOpacity(0.9),
                    Colors.brown.shade100.withOpacity(0.9),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.shade300.withOpacity(_pressed ? 0.5 : 0.4),
              offset: Offset(0, 3),
              blurRadius: _pressed ? 12 : 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl != null)
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade300.withOpacity(0.35),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    widget.imageUrl!,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: Colors.brown.shade200,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: Colors.brown.shade400),
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
                child: Icon(Icons.image_not_supported, color: Colors.brown.shade400, size: 32),
              ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.brown.shade200.withOpacity(0.7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.shade400.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.fact['icon'] ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.brown.shade700,
                            height: 1,
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.fact['title'] ?? 'No title',
                          style: widget.titleStyle,
                        ),
                      ),
                    ],
                  ),
                  if (widget.description.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade50.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.description,
                        style: widget.descriptionPreviewStyle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.brown.shade400),
          ],
        ),
      ),
    );
  }
}
