import 'package:flutter/material.dart';
import 'login.dart'; // Import LoginPage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Password visibility toggle
  bool _obscurePassword = true;

  // Function to save user profile data to SharedPreferences
  Future<void> _saveUserProfile(String name, String username, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
  }

  void _register() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        final response = await http.post(
          Uri.parse('http://10.0.2.2/project1msyamar/signup.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'fullname': _nameController.text, // Corrected this
            'email': _emailController.text,
            'username': _usernameController.text,
            'password': _passwordController.text, // Corrected this
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            // Save user profile after successful registration
            await _saveUserProfile(
              _nameController.text,
              _usernameController.text,
              _emailController.text,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration successful!')),
            );
            Navigator.pop(context); // Navigate back to the login screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'])),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${response.statusCode}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6D0C4), // Same pastel brown background as LoginPage
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Duration(seconds: 1),
                  padding: EdgeInsets.only(bottom: 10),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.pets,
                    size: 100,
                    color: Color(0xFFB89A82),
                  ),
                ),
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFF8D6E63),
                  ),
                ),
                SizedBox(height: 30),
                Form(
                  key: _formKey, 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            hintText: "Enter your full name",
                            icon: Icons.person,
                            validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                          ),
                          SizedBox(height: 15),
                          _buildTextField(
                            controller: _usernameController,
                            hintText: "Enter your username",
                            icon: Icons.account_circle_outlined,
                            validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
                          ),
                          SizedBox(height: 15),
                          _buildTextField(
                            controller: _emailController,
                            hintText: "Enter your email",
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value!.isEmpty) return 'Please enter your email';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email address';
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          _buildPasswordField(),
                          SizedBox(height: 20),
                          _buildSignUpButton(),
                          SizedBox(height: 20),
                          _buildOrDivider(),
                          SizedBox(height: 20),
                          _buildSignInText(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Common TextField builder to maintain consistency
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFFB89A82)),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color(0xFFD7B49E),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color(0xFFD7B49E),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color(0xFF8D6E63),
            width: 1.5,
          ),
        ),
      ),
      style: TextStyle(
        fontSize: 16,
        color: Color(0xFF8D6E63),
      ),
    );
  }

  // Password TextField with visibility toggle
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Color(0xFFB89A82)),
        hintText: "Enter your password",
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color(0xFFD7B49E),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color(0xFFD7B49E),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color(0xFF8D6E63),
            width: 1.5,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Color(0xFF8D6E63),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Please enter your password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      style: TextStyle(
        fontSize: 16,
        color: Color(0xFF8D6E63),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFB89A82),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 10,
      ),
      child: Text(
        "Sign Up",
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFD7B49E),
            thickness: 1.2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "OR",
            style: TextStyle(
              color: Color(0xFF8D6E63),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFD7B49E),
            thickness: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: TextStyle(color: Color(0xFF8D6E63)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
          child: Text(
            "Login here",
            style: TextStyle(
              color: Color(0xFF8D6E63),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
