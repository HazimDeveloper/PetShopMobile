import 'package:flutter/material.dart';
import 'package:fyp/notification_helper.dart';
import 'package:fyp/notification_service.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import 'profile.dart';
import 'database_helper.dart';
// Import your PetProvider if you use it
// import 'pet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ADD THESE LINES:
  await NotificationService().initialize();
  await NotificationHelper.setupDailyReminders();
  // Check database connection before running the app
  bool isDatabaseConnected = await DatabaseHelper.checkConnection();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PetProvider()), // Uncomment if you have PetProvider
      ],
      child: MyApp(isDatabaseConnected: isDatabaseConnected),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isDatabaseConnected;

  const MyApp({Key? key, required this.isDatabaseConnected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isDatabaseConnected ? WelcomePage() : DatabaseErrorPage(),
    );
  }
}

class DatabaseErrorPage extends StatefulWidget {
  @override
  State<DatabaseErrorPage> createState() => _DatabaseErrorPageState();
}

class _DatabaseErrorPageState extends State<DatabaseErrorPage> {
  bool _isLoading = false;

  Future<void> _retryConnection() async {
    setState(() => _isLoading = true);
    bool isConnected = await DatabaseHelper.checkConnection();
    if (isConnected) {
      // If connection is successful, navigate to WelcomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomePage()),
      );
    } else {
      // If still not connected, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to the database. Please try again.')),
      );
    }
    setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomePage()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFDDD0), Color(0xFFD7BFAA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
              SizedBox(height: 20),
              Text(
                'Database Connection Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Please check your internet connection\nand try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.brown[600],
                ),
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _retryConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC4A889),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Retry Connection'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  static const Color lightPastelBrown = Color(0xFFEFDDD0);
  static const Color pastelBrown = Color(0xFFD7BFAA);
  static const Color buttonBrown = Color(0xFFC4A889);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_animationController);
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLoginPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lightPastelBrown, pastelBrown],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _bounceAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'images/logopetpunctual.png',
                    height: 250,
                    width: 250,
                  ),
                ),
                SizedBox(height: 50),
                Tooltip(
                  message: 'Get Started',
                  child: ScaleTransition(
                    scale: _fadeAnimation,
                    child: ElevatedButton(
                      onPressed: _navigateToLoginPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBrown,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}