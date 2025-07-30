import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  _RegisterUserPageState createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/project1msyamar/get_users.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allUsers = List<Map<String, dynamic>>.from(data['users']);
            _filteredUsers = _allUsers;
          });
        } else {
          print('API error: ${data['error']}');
        }
      } else {
        print('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final username = user['username']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        return username.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _refreshList() {
    _fetchUsers();
    _searchController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User list refreshed'),
        backgroundColor: Color(0xFF8D6E63),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registered Users"),
        backgroundColor: Color(0xFFB89A82), // Pastel brown
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh User List',
            onPressed: _refreshList,
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFFAF6E9), // Soft pastel background
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Total users count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Total Users: ${_filteredUsers.length}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E5A4E), // Medium brown
                ),
              ),
            ),
            SizedBox(height: 10),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by username or email",
                prefixIcon: Icon(Icons.search, color: Color(0xFFB89A82)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),

            // User list
            Expanded(
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8D6E63),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final username = user['username'] ?? '';
                        final email = user['email'] ?? '';
                        final createdAt = user['created_at'] ?? '';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFFD7B49E),
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6E5A4E),
                              ),
                            ),
                            subtitle: Text(
                              email,
                              style: TextStyle(color: Color(0xFF8D6E63)),
                            ),
                            trailing: Text(
                              createdAt,
                              style: TextStyle(
                                color: Color(0xFFB89A82),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
