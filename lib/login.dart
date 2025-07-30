import 'package:flutter/material.dart';
import 'signup.dart';
import 'homepage.dart';
import 'adminlogin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _login() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/project1msyamar/login.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return; // Ensure the widget is still in the tree

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('responseData: ${response.body}');
        if (responseData['status'] == 'success') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(username: _usernameController.text),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid username or password')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpPage()),
    );
  }

  void _navigateToAdminLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6D0C4), // Pastel brown background
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: Duration(seconds: 1),
                  child: Icon(
                    Icons.pets,
                    size: 100,
                    color: Color(0xFFB89A82), // Softer pastel brown for icon
                  ),
                  padding: EdgeInsets.only(bottom: 10),
                  curve: Curves.easeInOut,
                ),
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFF8D6E63), // Dark pastel brown for text
                  ),
                ),
                SizedBox(height: 30), // Spacing
                Container(
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
                          controller: _usernameController,
                          hintText: "Enter your username",
                          icon: Icons.person,
                        ),
                        SizedBox(height: 15),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: "Enter your password",
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildLoginButton(),
                        SizedBox(height: 20),
                        _buildOrDivider(),
                        SizedBox(height: 20),
                        _buildSignUpText(),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
      ),
      style: TextStyle(
        fontSize: 16,
        color: Color(0xFF8D6E63),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFB89A82),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 10,
      ),
      child: Text(
        "Log In",
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

  Widget _buildSignUpText() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
            TextButton(
              onPressed: _navigateToSignUp,
              child: Text(
                "Sign Up",
                style: TextStyle(
                  color: Color(0xFF8D6E63),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        _buildAdminLoginText(context),
      ],
    );
  }

  Widget _buildAdminLoginText(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Are you an admin?",
          style: TextStyle(color: Color(0xFF8D6E63)),
        ),
        TextButton(
          onPressed: () {
            _navigateToAdminLogin(context);
          },
          child: Text(
            "Login Here",
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
