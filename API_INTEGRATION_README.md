# API Integration for Pet Management App

This document describes the Flutter API integration for the Project1MSYamar pet management application.

## 📁 Files Created/Modified

### New Files:
- `lib/api_service.dart` - Centralized API service class
- `lib/profile_management.dart` - Profile management UI
- `lib/notes_management.dart` - Notes management UI
- `lib/api_test_page.dart` - API testing interface

### Modified Files:
- `lib/addnote.dart` - Updated to use new API service
- `lib/homepage.dart` - Updated to use new API service

## 🔧 API Service Overview

The `ApiService` class provides a centralized way to interact with your PHP API endpoints. It includes:

- **Error handling** with consistent response format
- **Timeout management** (10 seconds default)
- **JSON parsing** with error recovery
- **User ID management** via SharedPreferences
- **Convenience methods** for current user operations

## 📋 API Endpoints Supported

### Profile Management:
- `get_profile` - Get user profile by user_id
- `update_profile` - Update user profile information
- `delete_profile` - Delete user profile

### Notes Management:
- `get_notes` - Get notes for specific user
- `get_all_notes` - Get all notes (admin)
- `add_note` - Add new note
- `update_note` - Update existing note
- `delete_note` - Delete note

## 🚀 Usage Examples

### 1. Profile Management

```dart
// Get current user's profile
final result = await ApiService.getCurrentUserProfile();
if (result['status'] == 'success') {
  final profile = result['data'];
  print('User: ${profile['fullname']}');
}

// Update profile
final updateResult = await ApiService.updateCurrentUserProfile(
  fullname: 'John Doe',
  username: 'johndoe',
  email: 'john@example.com',
);

// Delete profile
final deleteResult = await ApiService.deleteCurrentUserProfile();
```

### 2. Notes Management

```dart
// Get current user's notes
final result = await ApiService.getCurrentUserNotes();
if (result['status'] == 'success') {
  final notes = result['data'];
  // Process notes...
}

// Add new note
final addResult = await ApiService.addNote(
  userId: '1',
  title: 'Vet Appointment',
  category: 'Health',
  date: '2024-01-15',
  time: '14:30',
  priority: 'high',
  content: 'Annual checkup for Max',
  pets: ['Max'],
  tags: ['vet', 'health'],
);

// Update note
final updateResult = await ApiService.updateNote(
  id: '123',
  title: 'Updated Title',
  content: 'Updated content',
);

// Delete note
final deleteResult = await ApiService.deleteNote('123');
```

## 🎨 UI Components

### Profile Management Page
- **View profile** information in a clean card layout
- **Edit mode** with form validation
- **Delete profile** with confirmation dialog
- **Error handling** with retry functionality
- **Loading states** for better UX

### Notes Management Page
- **List view** with search and filtering
- **Category and priority** filters
- **Add/Edit/Delete** operations
- **Modern card design** with color coding
- **Real-time updates** after operations

## 🔍 Response Format

All API responses follow this consistent format:

```json
{
  "status": "success" | "error",
  "message": "Description message",
  "data": { /* response data */ },
  "httpStatus": 200
}
```

## 🛠️ Error Handling

The API service includes comprehensive error handling:

- **Network errors** with timeout protection
- **JSON parsing errors** with fallback
- **HTTP status code** validation
- **User-friendly error messages**
- **Retry mechanisms** in UI components

## 🧪 Testing

Use the `ApiTestPage` to test all API endpoints:

1. Navigate to the test page
2. Click test buttons for different operations
3. View results in the formatted output
4. Test both success and error scenarios

## 📱 Integration with Existing App

### Navigation
Add navigation to the new pages in your main app:

```dart
// Navigate to profile management
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ProfileManagementPage()),
);

// Navigate to notes management
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NotesManagementPage()),
);

// Navigate to API test page
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ApiTestPage()),
);
```

### Dependencies
Ensure these dependencies are in your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

## 🔧 Configuration

### Base URL
Update the base URL in `api_service.dart` if needed:

```dart
static const String baseUrl = 'http://10.0.2.2/project1msyamar/api_test.php';
```

### User ID Storage
The service automatically manages user ID from SharedPreferences:

```dart
// Set user ID after login
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_id', '123');

// Get user ID (handled automatically by API service)
final userId = await ApiService._getUserId();
```

## 🎯 Best Practices

1. **Always check response status** before processing data
2. **Handle loading states** in UI components
3. **Provide user feedback** for all operations
4. **Use error boundaries** for graceful error handling
5. **Test API endpoints** before production deployment
6. **Validate user input** before sending to API
7. **Cache data** when appropriate for better performance

## 🐛 Troubleshooting

### Common Issues:

1. **Network Error**: Check if the API server is running
2. **User ID Missing**: Ensure user is logged in and user_id is stored
3. **JSON Parse Error**: Check API response format
4. **Timeout Error**: Increase timeout duration if needed

### Debug Mode:
Enable debug logging by adding print statements in the API service:

```dart
print('API Request: $url');
print('API Response: ${response.body}');
```

## 📞 Support

For issues or questions:
1. Check the API test page for endpoint testing
2. Review error messages in the console
3. Verify API server configuration
4. Test with known working user IDs (1, 7, 17, 18)

---

**Note**: This integration assumes your PHP API endpoints are working correctly and returning the expected JSON format. Test thoroughly with your actual API implementation. 