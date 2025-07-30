import 'package:flutter/material.dart';
import 'profile.dart';

class PetDetailPage extends StatelessWidget {
  final Pet pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pet Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.brown[300], // Pastel brown for AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPetInfoCard('Pet Name', pet.petNameController.text),
              _buildPetInfoCard('Breed', pet.breedController.text),
              _buildPetInfoCard('Colour', pet.colourController.text),
              _buildPetInfoCard('Date of Birth', pet.dateOfBirthController.text),
              _buildPetInfoCard('Gender', pet.gender),
              _buildPetInfoCard('Pet Type', pet.petType),
              _buildPetInfoCard('Sterilized', pet.sterilized ? "Yes" : "No"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetInfoCard(String title, String value) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.brown[50], // Light pastel brown for card background
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[800]), // Darker brown for title
            ),
            Text(
              value,
              style: TextStyle(fontSize: 20, color: Colors.brown[700]), // Slightly darker brown for value
            ),
          ],
        ),
      ),
    );
  }
}
