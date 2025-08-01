import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detailpet.dart';

// PET MODEL
class Pet {
  final String id;
  final String userId;
  final TextEditingController petNameController;
  final TextEditingController breedController;
  final TextEditingController colourController;
  final TextEditingController dateOfBirthController;
  String gender;
  String petType;
  bool sterilized;
  String? imagePath;

  Pet({
    String? id,
    String petName = '',
    String breed = '',
    String colour = '',
    String dateOfBirth = '',
    this.userId = '',
    this.gender = 'Female',
    this.petType = 'Indoor',
    this.sterilized = false,
    this.imagePath,
  })  : id = id ?? Uuid().v4(),
        petNameController = TextEditingController(text: petName),
        breedController = TextEditingController(text: breed),
        colourController = TextEditingController(text: colour),
        dateOfBirthController = TextEditingController(text: dateOfBirth);

  void dispose() {
    petNameController.dispose();
    breedController.dispose();
    colourController.dispose();
    dateOfBirthController.dispose();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'petName': petNameController.text,
        'breed': breedController.text,
        'colour': colourController.text,
        'dateOfBirth': dateOfBirthController.text,
        'gender': gender,
        'petType': petType,
        'sterilized': sterilized,
        'imagePath': imagePath,
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'],
        petName: json['petName'],
        breed: json['breed'],
        colour: json['colour'],
        dateOfBirth: json['dateOfBirth'],
        gender: json['gender'],
        petType: json['petType'],
        sterilized: json['sterilized'],
        imagePath: json['imagePath'],
      );
}

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
    petNames.add(pet.petNameController.text);
    await prefs.setStringList('petNames', petNames);
  }

  void addPet(Pet pet) {
    _pets.add(pet);
    _savePetToPreferences(pet);
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
    _savePetToPreferences(updatedPet);
    notifyListeners();
  }

  void removePet(int index) async {
    final petId = _pets[index].id;
    _pets[index].dispose();
    _pets.removeAt(index);
    notifyListeners();
    await deletePetFromDatabase(petId);
    _loadPetsData();
  }

  Future<void> _loadPetsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isEmpty) {
        throw Exception("User ID is missing.");
      }
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
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) throw Exception("User ID is missing.");

    final url = isEdit
        ? Uri.parse("http://10.0.2.2/project1msyamar/update_pet.php")
        : Uri.parse("http://10.0.2.2/project1msyamar/add_pet.php");

    final body = {
      "user_id": userId,
      "petName": pet.petNameController.text,
      "breed": pet.breedController.text,
      "colour": pet.colourController.text,
      "dateOfBirth": pet.dateOfBirthController.text,
      "gender": pet.gender,
      "petType": pet.petType,
      "sterilized": pet.sterilized,
      "imagePath": pet.imagePath ?? '',  // If no image, send empty string
    };

    if (isEdit) body["id"] = pet.id;

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final resBody = jsonDecode(response.body);
      if (resBody['success'] == true) {
        print("Pet saved successfully!");
      } else {
        throw Exception("Failed: ${resBody['message']}");
      }
    } else {
      throw Exception("Failed (HTTP ${response.statusCode})");
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
      throw Exception("Failed to load pets from database.");
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

// MAIN APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PetProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.brown[300],
          scaffoldBackgroundColor: Colors.brown[100],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.brown[300],
            foregroundColor: Colors.white,
          ),
        ),
        home: PetPage(),
      ),
    );
  }
}

class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  _PetPageState createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPetsData();
  }

  Future<void> _loadPetsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      print("DEBUG: Loading pets for user_id: $userId");

      if (userId.isEmpty) {
        throw Exception("User ID is missing.");
      }

      List<Pet> pets = await fetchPetsFromDatabase(userId);
      Provider.of<PetProvider>(context, listen: false).setPets(pets);
    } catch (e) {
      print("Error loading pets: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addPet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditPetPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Your Pets"),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(color: Colors.brown[100]),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPetsSection(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPet,
        backgroundColor: Colors.brown.shade300,
        elevation: 10,
        tooltip: "Add a new pet",
        child: Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildPetsSection() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '                      🐶 Your Pets',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            SizedBox(height: 10),
            petProvider.pets.isEmpty
                ? Text('No pets added yet.', style: TextStyle(color: Colors.brown[600], fontSize: 16))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: petProvider.pets.length,
                    itemBuilder: (context, index) {
                      return PetCard(
                        pet: petProvider.pets[index],
                        index: index, // ADD THIS LINE
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditPetPage(pet: petProvider.pets[index], index: index),
                            ),
                          );
                        },
                        onRemove: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Delete Pet"),
                              content: Text("Are you sure you want to delete this pet?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            petProvider.removePet(index);
                          }
                        },
                      );
                    },
                  ),
          ],
        );
      },
    );
  }
}

// PET CARD WIDGET
class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final int index;

  const PetCard({
    super.key, 
    required this.pet,
    required this.onEdit,
    required this.onRemove,
    required this.index,
  });

  void _showPetDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailPage(
          pet: pet,
          isNewlyCreated: false,
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility, color: Colors.blue[600]),
              title: Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showPetDetails(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.orange[600]),
              title: Text('Edit Pet'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[600]),
              title: Text('Delete Pet'),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.brown[50],
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showPetDetails(context),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Pet Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pet.imagePath != null && pet.imagePath!.isNotEmpty
                      ? Image.file(
                          File(pet.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.brown[300],
                              child: Icon(Icons.pets, color: Colors.white, size: 35),
                            );
                          },
                        )
                      : Container(
                          color: Colors.brown[300],
                          child: Icon(Icons.pets, color: Colors.white, size: 35),
                        ),
                ),
              ),
              
              SizedBox(width: 16),
              
              // Pet Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.petNameController.text,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Breed: ${pet.breedController.text.isEmpty ? "Not specified" : pet.breedController.text}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.brown[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          pet.gender == 'Male' ? Icons.male : Icons.female,
                          size: 16,
                          color: pet.gender == 'Male' ? Colors.blue[600] : Colors.pink[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          pet.gender,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          pet.petType == 'Indoor' ? Icons.home : Icons.landscape,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          pet.petType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.brown[600]),
                    onPressed: () => _showOptionsMenu(context),
                    tooltip: 'More options',
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Tap to view',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ADD / EDIT PET PAGE
class AddEditPetPage extends StatefulWidget {
  final Pet? pet;
  final int? index;

  const AddEditPetPage({super.key, this.pet, this.index});

  @override
  _AddEditPetPageState createState() => _AddEditPetPageState();
}

class _AddEditPetPageState extends State<AddEditPetPage> with SingleTickerProviderStateMixin {
  late Pet _editingPet;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // ADD THIS LINE

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.pet != null) {
      _editingPet = Pet(
        id: widget.pet!.id,
        petName: widget.pet!.petNameController.text,
        breed: widget.pet!.breedController.text,
        colour: widget.pet!.colourController.text,
        dateOfBirth: widget.pet!.dateOfBirthController.text,
        gender: widget.pet!.gender,
        petType: widget.pet!.petType,
        sterilized: widget.pet!.sterilized,
        imagePath: widget.pet!.imagePath,
      );
      if (_editingPet.imagePath != null) {
        _imageFile = File(_editingPet.imagePath!);
      }
    } else {
      _editingPet = Pet();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _editingPet.imagePath = pickedFile.path;
        _animationController.forward(from: 0);
      });
    }
  }

  void _savePet() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final petProvider = Provider.of<PetProvider>(context, listen: false);
        bool isEdit = widget.index != null;

        if (isEdit) {
          petProvider.updatePet(widget.index!, _editingPet);
          await savePetToDatabase(_editingPet, isEdit: true);
        } else {
          petProvider.addPet(_editingPet);
          await savePetToDatabase(_editingPet);
        }

        setState(() {
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(isEdit ? 'Pet updated successfully! 🎉' : 'Pet added successfully! 🎉'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: Duration(seconds: 2),
            ),
          );

          // Wait a moment for the snackbar to show, then navigate
          await Future.delayed(Duration(milliseconds: 500));

          // Navigate to pet details page
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PetDetailPage(
                  pet: _editingPet,
                  isNewlyCreated: true,
                ),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Error saving pet: ${e.toString()}'),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePet,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey[400] : Colors.brown.shade300,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isLoading ? 0 : 8,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.pet == null ? 'Adding Pet...' : 'Updating Pet...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                widget.pet == null ? 'Add Pet' : 'Update Pet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.brown.shade300;

    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: themeColor,
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? Icon(Icons.pets, size: 70, color: Colors.white70)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
              _buildInputField(label: 'Pet Name', controller: _editingPet.petNameController, icon: Icons.pets),
              SizedBox(height: 15),
              _buildInputField(label: 'Breed', controller: _editingPet.breedController, icon: Icons.category),
              SizedBox(height: 15),
              _buildInputField(label: 'Colour', controller: _editingPet.colourController, icon: Icons.color_lens),
              SizedBox(height: 15),
              _buildDatePickerField(
                label: 'Date of Birth',
                controller: _editingPet.dateOfBirthController,
                icon: Icons.cake,
              ),
              SizedBox(height: 20),
              _buildDropdownField<String>(
                label: 'Gender',
                value: _editingPet.gender,
                items: ['Female', 'Male'],
                icon: Icons.wc,
                onChanged: (val) => setState(() => _editingPet.gender = val!),
              ),
              SizedBox(height: 20),
              _buildDropdownField<String>(
                label: 'Pet Type',
                value: _editingPet.petType,
                items: ['Indoor', 'Outdoor'],
                icon: Icons.home,
                onChanged: (val) => setState(() => _editingPet.petType = val!),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _editingPet.sterilized,
                    onChanged: (val) => setState(() => _editingPet.sterilized = val!),
                    activeColor: themeColor,
                  ),
                  Text('Sterilized', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter $label' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.brown[300]),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.brown.shade400, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.brown.shade200),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: controller.text.isNotEmpty
              ? _parseDate(controller.text)
              : DateTime.now().subtract(Duration(days: 365 * 2)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.brown.shade300,
                onPrimary: Colors.white,
                onSurface: Colors.brown.shade800,
              ),
            ),
            child: child!,
          ),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text = "${pickedDate.year}/${pickedDate.month}/${pickedDate.day}";
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.brown[300]),
            labelText: label,
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.brown.shade400, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.brown.shade200),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.brown[300]),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.brown.shade400, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.brown.shade200),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
    );
  }
}
