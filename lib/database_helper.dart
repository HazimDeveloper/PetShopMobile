import 'package:http/http.dart' as http;

class DatabaseHelper {
  static const String baseUrl = 'http://10.0.2.2/project1msyamar';

  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check_connection.php'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body;
        // Optionally, parse JSON and check for 'status'
        return body.contains('success');
      }
      return false;
    } catch (e) {
      print('Database connection error: $e');
      return false;
    }
  }
}