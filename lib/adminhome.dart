import 'package:flutter/material.dart';
import 'adminlogin.dart';
import 'addeventpage.dart';
import 'addfunfactpage.dart';
import 'registeruserpage.dart'; // Import AdminLogin page

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  // Pastel brown palette
  static const Color backgroundColor = Color(0xFFFAF6E9);
  static const Color containerColor = Color(0xFFF8F1EA);
  static const Color buttonColor = Color(0xFFB89A82);
  static const Color buttonBorderShadow = Color(0xFF8D6E63);
  static const Color iconCircleColor = Color(0xFFD7B49E);
  static const Color iconColor = Colors.white;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Admin Home",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
            color: iconColor,
          ),
        ),
        backgroundColor: buttonColor,
        elevation: 4,
        shadowColor: buttonBorderShadow.withOpacity(0.6),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: iconColor),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminLogin()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Container(
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: buttonBorderShadow.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: buttonBorderShadow.withOpacity(0.3),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 32),
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: 480),
          child: FadeTransition(
            opacity: _animationController.drive(CurveTween(curve: Curves.easeOut)),
            child: SlideTransition(
              position: _animationController.drive(
                Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).chain(
                  CurveTween(curve: Curves.easeOut),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(
                      "Manage your app with ease",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: buttonBorderShadow.withOpacity(0.85),
                        letterSpacing: 0.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildAdminButton(context, "Register User", Icons.person_add_alt_1, RegisterUserPage()),
                  SizedBox(height: 24),
                  _buildAdminButton(context, "Add Event", Icons.event_note, AddEventPage()),
                  SizedBox(height: 24),
                  _buildAdminButton(context, "Add Fun Fact", Icons.pets, AddFunFactPage()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, String title, IconData icon, Widget page) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _navigateToPage(page),
      splashColor: buttonBorderShadow.withOpacity(0.3),
      highlightColor: buttonBorderShadow.withOpacity(0.15),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: buttonBorderShadow.withOpacity(0.5),
              blurRadius: 12,
              offset: Offset(0, 7),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconCircleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: buttonBorderShadow.withOpacity(0.55),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(12),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            SizedBox(width: 22),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: 1.15,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: iconColor.withOpacity(0.85),
            ),
          ],
        ),
      ),
    );
  }
}
