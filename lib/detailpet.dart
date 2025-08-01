import 'package:flutter/material.dart';
import 'package:fyp/profile.dart';
import 'dart:io';

class PetDetailPage extends StatefulWidget {
  final Pet pet;
  final bool isNewlyCreated;

  const PetDetailPage({
    super.key, 
    required this.pet,
    this.isNewlyCreated = false,
  });

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Color theme
  final Color lightPastelBrown = Colors.brown[100]!;
  final Color pastelBrown = Colors.brown[300]!;
  final Color darkPastelBrown = Colors.brown[700]!;
  final Color shadowPastelBrown = Colors.brown[300]!.withOpacity(0.3);

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // Show success message if this is a newly created/updated pet
    if (widget.isNewlyCreated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessMessage();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Pet saved successfully! 🎉'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _calculateAge() {
    try {
      final birthDate = DateTime.parse(widget.pet.dateOfBirthController.text.replaceAll('/', '-'));
      final now = DateTime.now();
      final difference = now.difference(birthDate);
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      
      if (years > 0) {
        return months > 0 ? '$years years, $months months' : '$years years';
      } else if (months > 0) {
        return '$months months';
      } else {
        final days = difference.inDays;
        return '$days days';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildDetailCard(String title, String value, IconData icon, {Color? color}) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowPastelBrown,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (color ?? pastelBrown).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon, 
                      color: color ?? pastelBrown, 
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkPastelBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [pastelBrown, pastelBrown.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowPastelBrown,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Pet Image
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.pet.imagePath != null && widget.pet.imagePath!.isNotEmpty
                        ? Image.file(
                            File(widget.pet.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white,
                                child: Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: pastelBrown,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.white,
                            child: Icon(
                              Icons.pets,
                              size: 60,
                              color: pastelBrown,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Pet Name
                Text(
                  widget.pet.petNameController.text,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                // Age
                Text(
                  'Age: ${_calculateAge()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                
                // Status badges
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusBadge(
                      widget.pet.gender,
                      widget.pet.gender == 'Male' ? Icons.male : Icons.female,
                      widget.pet.gender == 'Male' ? Colors.blue[300]! : Colors.pink[300]!,
                    ),
                    SizedBox(width: 8),
                    _buildStatusBadge(
                      widget.pet.petType,
                      widget.pet.petType == 'Indoor' ? Icons.home : Icons.landscape,
                      Colors.green[300]!,
                    ),
                    if (widget.pet.sterilized) ...[
                      SizedBox(width: 8),
                      _buildStatusBadge(
                        'Sterilized',
                        Icons.medical_services,
                        Colors.orange[300]!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditPetPage(
                            pet: widget.pet,
                            index: 0, // You might need to pass the actual index
                          ),
                        ),
                      ).then((result) {
                        // Refresh the page if pet was updated
                        if (result != null) {
                          setState(() {});
                        }
                      });
                    },
                    icon: Icon(Icons.edit, color: Colors.white),
                    label: Text(
                      'Edit Pet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pastelBrown,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: pastelBrown),
                    label: Text(
                      'Back to List',
                      style: TextStyle(
                        color: pastelBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: pastelBrown, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBrown,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkPastelBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pet Details',
          style: TextStyle(
            color: darkPastelBrown,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (widget.isNewlyCreated)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Saved',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPetHeader(),
                  SizedBox(height: 24),
                  
                  // Pet Details
                  _buildDetailCard(
                    'Breed',
                    widget.pet.breedController.text.isEmpty 
                        ? 'Not specified' 
                        : widget.pet.breedController.text,
                    Icons.category,
                    color: Colors.purple[400],
                  ),
                  
                  _buildDetailCard(
                    'Color',
                    widget.pet.colourController.text.isEmpty 
                        ? 'Not specified' 
                        : widget.pet.colourController.text,
                    Icons.color_lens,
                    color: Colors.indigo[400],
                  ),
                  
                  _buildDetailCard(
                    'Date of Birth',
                    widget.pet.dateOfBirthController.text.isEmpty 
                        ? 'Not specified' 
                        : widget.pet.dateOfBirthController.text,
                    Icons.cake,
                    color: Colors.pink[400],
                  ),
                  
                  _buildDetailCard(
                    'Gender',
                    widget.pet.gender,
                    widget.pet.gender == 'Male' ? Icons.male : Icons.female,
                    color: widget.pet.gender == 'Male' ? Colors.blue[400] : Colors.pink[400],
                  ),
                  
                  _buildDetailCard(
                    'Living Environment',
                    widget.pet.petType,
                    widget.pet.petType == 'Indoor' ? Icons.home : Icons.landscape,
                    color: Colors.green[400],
                  ),
                  
                  _buildDetailCard(
                    'Sterilization Status',
                    widget.pet.sterilized ? 'Sterilized' : 'Not Sterilized',
                    widget.pet.sterilized ? Icons.check_circle : Icons.circle_outlined,
                    color: widget.pet.sterilized ? Colors.green[600] : Colors.orange[600],
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }
}