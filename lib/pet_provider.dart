import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fyp/profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// PROVIDER
class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];

  List<Pet> get pets => _pets;

  void setPets(List<Pet> pets) {
    _pets = pets;
    notifyListeners();
  }

  Future<void> _savePetToPreferences(Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> petNames = prefs.getStringList('petNames') ?? [];
    petNames.add(pet.petNameController.text); // Add the new pet name
    await prefs.setStringList('petNames', petNames); // Save pet names to SharedPreferences
  }

  void addPet(Pet pet) {
    _pets.add(pet);
    _savePetToPreferences(pet); // Save pet name to SharedPreferences
    notifyListeners();
  }

  void updatePet(int index, Pet updatedPet) {
    _pets[index].petNameController.text = updatedPet.petNameController.text;
    _pets[index].breedController.text = updatedPet.breedController.text;
    _pets[index].colourController.text = updatedPet.colourController.text;
    _pets[index].dateOfBirthController.text = updatedPet.dateOfBirthController.text;
    _pets[index].gender = updatedPet.gender;
    _pets[index].petType = updatedPet.petType;
    _pets[index].sterilized = updatedPet.sterilized;
    _pets[index].imagePath = updatedPet.imagePath;
    _savePetToPreferences(updatedPet); // Save pet name to SharedPreferences
    notifyListeners();
  }

  void removePet(int index) async {
    final petId = _pets[index].id;
    _pets[index].dispose();
    _pets.removeAt(index);
    notifyListeners();
    await deletePetFromDatabase(petId); // Ensure deletion is called properly
    _loadPetsData();  // Refetch pets list after deletion
  }

  Future<void> _loadPetsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      List<Pet> pets = await fetchPetsFromDatabase(userId);
      setPets(pets);
    } catch (e) {
      print("Error loading pets: $e");
    }
  }
}

// DATABASE FUNCTIONS
Future<void> savePetToDatabase(Pet pet, {bool isEdit = false}) async {
  try {
    final url = isEdit
        ? Uri.parse("http://10.0.2.2/project1msyamar/update_pet.php")
        : Uri.parse("http://10.0.2.2/project1msyamar/add_pet.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": pet.id,
        "user_id": pet.userId,
        "petName": pet.petNameController.text,
        "breed": pet.breedController.text,
        "colour": pet.colourController.text,
        "dateOfBirth": pet.dateOfBirthController.text,
        "gender": pet.gender,
        "petType": pet.petType,
        "sterilized": pet.sterilized,
        "imagePath": pet.imagePath,
      }),
    );

    if (response.statusCode == 200) {
      final resBody = jsonDecode(response.body);
      if (resBody['success'] == true) {
        print("Pet saved successfully!");
      } else {
        throw Exception("Failed: ${resBody['message'] ?? 'Unknown error'}");
      }
    } else {
      throw Exception("Failed to save pet (HTTP ${response.statusCode})");
    }
  } catch (e) {
    print("Error saving pet: $e");
  }
}

Future<List<Pet>> fetchPetsFromDatabase(String userId) async {
  try {
    final url = Uri.parse("http://10.0.2.2/project1msyamar/get_pets.php?user_id=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Pet.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load pets");
    }
  } catch (e) {
    print("Error fetching pets: $e");
    return [];
  }
}

Future<void> deletePetFromDatabase(String petId) async {
  try {
    final url = Uri.parse("http://10.0.2.2/project1msyamar/delete_pet.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": petId}),
    );

    final responseBody = jsonDecode(response.body);
    print("Delete Response: $responseBody");

    if (response.statusCode == 200 && responseBody["success"] == true) {
      print("Pet deleted from database successfully!");
    } else {
      print("Failed to delete pet: ${responseBody["message"]}");
    }
  } catch (e) {
    print("Error deleting pet: $e");
  }
}
