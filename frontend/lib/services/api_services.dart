import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.10.160.53:3000/api";
  // Get stored token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Save user info
  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  // Get user info
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  // Clear all data
  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Register user - UPDATED WITH USERNAME AND PHONE
  Future<Map<String, dynamic>> register(
      String name, String username, String phone, String email, String password) async {
    try {
      print('Registering user: $email'); // Debug
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'phone': phone,
          'email': email,
          'password': password,
        }),
      );

      print('Register response status: ${response.statusCode}'); // Debug
      print('Register response body: ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveToken(data['token']);
        await _saveUser(data['user']);
        return {'success': true, 'message': data['message'], 'user': data['user']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Register error: $e'); // Debug
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Login user (identifier can be email/username/phone)
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      print('Logging in user: $identifier'); // Debug
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}'); // Debug
      print('Login response body: ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        await _saveUser(data['user']);
        return {'success': true, 'message': data['message'], 'user': data['user']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login error: $e'); // Debug
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await _getToken();
      
      if (token != null) {
        print('Logging out user'); // Debug
        
        final response = await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('Logout response status: ${response.statusCode}'); // Debug
        print('Logout response body: ${response.body}'); // Debug
      }
      
      await _clearData();
      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      print('Logout error: $e'); // Debug
      await _clearData(); // Clear data anyway
      return {'success': true, 'message': 'Logged out'};
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('Forgot password for: $email'); // Debug
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Forgot password response: ${response.statusCode}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Request failed'};
      }
    } catch (e) {
      print('Forgot password error: $e'); // Debug
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get all medicines
  Future<Map<String, dynamic>> getMedicines() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found. Please login again.'};
      }

      print('Fetching medicines with token: $token'); // Debug

      final response = await http.get(
        Uri.parse('$baseUrl/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get medicines response status: ${response.statusCode}'); // Debug
      print('Get medicines response body: ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'medicines': data['medicines']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to get medicines'};
      }
    } catch (e) {
      print('Get medicines error: $e'); // Debug
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add medicine
  Future<Map<String, dynamic>> addMedicine(
      String name, String dosage, String purpose, int frequency, List<String> times) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found. Please login again.'};
      }

      print('Adding medicine: $name, $dosage, $purpose, $frequency, $times'); // Debug

      final response = await http.post(
        Uri.parse('$baseUrl/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'dosage': dosage,
          'purpose': purpose.isEmpty ? null : purpose,
          'frequency': frequency,
          'times': times,
        }),
      );

      print('Add medicine response status: ${response.statusCode}'); // Debug
      print('Add medicine response body: ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message'], 'medicine': data['medicine']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to add medicine'};
      }
    } catch (e) {
      print('Add medicine error: $e'); // Debug
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update medicine
  Future<Map<String, dynamic>> updateMedicine(
      int id, String name, String dosage, String purpose, int frequency, List<String> times) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found. Please login again.'};
      }

      print('Updating medicine ID: $id'); // Debug

      final response = await http.put(
        Uri.parse('$baseUrl/medicines/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'dosage': dosage,
          'purpose': purpose.isEmpty ? null : purpose,
          'frequency': frequency,
          'times': times,
        }),
      );

      print('Update medicine response status: ${response.statusCode}'); // Debug
      print('Update medicine response body: ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to update medicine'};
      }
    } catch (e) {
      print('Update medicine error: $e'); // Debug
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete medicine
  Future<Map<String, dynamic>> deleteMedicine(int id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found. Please login again.'};
      }

      print('Deleting medicine ID: $id'); // Debug

      final response = await http.delete(
        Uri.parse('$baseUrl/medicines/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete medicine response status: ${response.statusCode}'); // Debug
      print('Delete medicine response body: ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to delete medicine'};
      }
    } catch (e) {
      print('Delete medicine error: $e'); // Debug
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}