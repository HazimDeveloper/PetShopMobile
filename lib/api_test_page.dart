import 'package:flutter/material.dart';
import 'api_service.dart';
import 'profile_management.dart';
import 'notes_management.dart';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  _ApiTestPageState createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  String _testResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Test Page'),
        backgroundColor: Colors.brown[300],
      ),
      backgroundColor: Colors.brown[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Integration Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            SizedBox(height: 20),

            // Profile Management Section
            _buildSection(
              title: 'Profile Management',
              description: 'Test profile operations using the new API service',
              children: [
                _buildTestButton('Get Current User Profile', _testGetProfile),
                _buildTestButton('Update Profile', _testUpdateProfile),
                _buildTestButton('Delete Profile', _testDeleteProfile),
                _buildTestButton('Get All Users', _testGetAllUsers),
                _buildTestButton(
                  'Open Profile Management',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileManagementPage()),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Notes Management Section
            _buildSection(
              title: 'Notes Management',
              description: 'Test notes operations using the new API service',
              children: [
                _buildTestButton('Get Current User Notes', _testGetNotes),
                _buildTestButton('Get All Notes (Admin)', _testGetAllNotes),
                _buildTestButton('Add Test Note', _testAddNote),
                _buildTestButton('Update Test Note', _testUpdateNote),
                _buildTestButton('Delete Test Note', _testDeleteNote),
                _buildTestButton(
                  'Open Notes Management',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotesManagementPage()),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Pets Management Section
            _buildSection(
              title: 'Pets Management',
              description: 'Test pets operations',
              children: [
                _buildTestButton('Get All Pets', _testGetAllPets),
                _buildTestButton('Get User Pets', _testGetUserPets),
              ],
            ),

            SizedBox(height: 20),

            // Events & Fun Facts Section
            _buildSection(
              title: 'Events & Fun Facts',
              description: 'Test events and fun facts endpoints',
              children: [
                _buildTestButton('Get All Events', _testGetAllEvents),
                _buildTestButton('Get All Fun Facts', _testGetAllFunFacts),
              ],
            ),

            SizedBox(height: 20),

            // System Info Section
            _buildSection(
              title: 'System Info',
              description: 'Test system info endpoint',
              children: [
                _buildTestButton('Get System Info', _testGetSystemInfo),
              ],
            ),

            SizedBox(height: 20),

            // Test Results
            if (_testResult.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResult,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
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
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.brown[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[300],
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text),
      ),
    );
  }

  // ----------- Profile Management -----------
  Future<void> _testGetProfile() async => _runTest(() => ApiService.getCurrentUserProfile(), 'Get Profile');
  Future<void> _testUpdateProfile() async => _runTest(() => ApiService.updateCurrentUserProfile(
        fullname: 'Test User Updated',
        username: 'testuser_updated',
        email: 'test.updated@example.com',
      ), 'Update Profile');
  Future<void> _testDeleteProfile() async => _runTest(() => ApiService.deleteCurrentUserProfile(), 'Delete Profile');
  Future<void> _testGetAllUsers() async => _runTest(() => ApiService.getAllUsers(), 'Get All Users');

  // ----------- Notes Management -----------
  Future<void> _testGetNotes() async => _runTest(() => ApiService.getCurrentUserNotes(), 'Get Notes');
  Future<void> _testGetAllNotes() async => _runTest(() => ApiService.getAllNotes(), 'Get All Notes');
  Future<void> _testAddNote() async => _runTest(() => ApiService.addNote(
        userId: '1',
        title: 'Test Note from API',
        category: 'General',
        date: DateTime.now().toIso8601String().split('T')[0],
        time: '10:00',
        priority: 'medium',
        content: 'This is a test note created via API integration.',
        pets: ['Test Pet'],
        tags: ['test', 'api'],
      ), 'Add Note');
  Future<void> _testUpdateNote() async => _runTest(() => ApiService.updateNote(
        id: '16', // Use a valid note ID for your test
        title: 'Updated Note Title',
        category: 'Updated Category',
        date: DateTime.now().toIso8601String().split('T')[0],
        time: '11:00',
        priority: 'high',
        content: 'Updated note content.',
        pets: ['Test Pet'],
        tags: ['updated', 'api'],
      ), 'Update Note');
  Future<void> _testDeleteNote() async => _runTest(() => ApiService.deleteNote('16'), 'Delete Note'); // Use a valid note ID

  // ----------- Pets Management -----------
  Future<void> _testGetAllPets() async => _runTest(() => ApiService.getAllPets(), 'Get All Pets');
  Future<void> _testGetUserPets() async => _runTest(() => ApiService.getUserPets('1'), 'Get User Pets'); // Use a valid user ID

  // ----------- Events & Fun Facts -----------
  Future<void> _testGetAllEvents() async => _runTest(() => ApiService.getAllEvents(), 'Get All Events');
  Future<void> _testGetAllFunFacts() async => _runTest(() => ApiService.getAllFunFacts(), 'Get All Fun Facts');

  // ----------- System Info -----------
  Future<void> _testGetSystemInfo() async => _runTest(() => ApiService.getSystemInfo(), 'Get System Info');

  // ----------- Helper for running and formatting tests -----------
  Future<void> _runTest(Future<Map<String, dynamic>> Function() apiCall, String label) async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing $label...\n';
    });

    try {
      final result = await apiCall();
      setState(() {
        _testResult = '$label Result:\n${_formatResult(result)}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '$label Error:\n$e';
        _isLoading = false;
      });
    }
  }

  String _formatResult(Map<String, dynamic> result) {
    return '''
Status: ${result['status']}
Message: ${result['message']}
HTTP Status: ${result['httpStatus']}
Data: ${result['data'] != null ? result['data'].toString() : 'null'}
''';
  }
}