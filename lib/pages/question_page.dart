import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main_screen.dart';
import 'login_page.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _birthDate;
  String? _gender;
  String? _bodyType;

  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];
  final List<Map<String, String>> _bodyTypes = [
    {'type': 'Gầy', 'description': 'Dáng người nhỏ, ít cơ'},
    {'type': 'Trung bình', 'description': 'Dáng người cân đối'},
    {'type': 'Mập', 'description': 'Dáng người to, nhiều mỡ'},
    {'type': 'Cơ bắp', 'description': 'Dáng người có cơ bắp'},
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: now.subtract(const Duration(days: 365 * 13)), // Tối thiểu 13 tuổi
      locale: const Locale('vi', 'VN'),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên của bạn';
    }
    if (value.trim().length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (_birthDate == null || _gender == null || _bodyType == null) {
      _showErrorSnackBar('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    final age = _calculateAge(_birthDate!);
    if (age < 13) {
      _showErrorSnackBar('Bạn phải từ 13 tuổi trở lên');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(),
              settings: RouteSettings(arguments: {'redirectToMain': true}),
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'dob': _birthDate!.toIso8601String(),
        'age': age,
        'gender': _gender,
        'bodyType': _bodyType,
        'createdAt': FieldValue.serverTimestamp(),
        'profileCompleted': true,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Đã xảy ra lỗi. Vui lòng thử lại');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha((0.3 * 255).round()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tên của bạn là gì?'),
            TextFormField(
              controller: _nameController,
              validator: _validateName,
              decoration: const InputDecoration(
                hintText: 'Nhập tên đầy đủ của bạn...',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthDatePicker() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Ngày sinh của bạn là gì?'),
            InkWell(
              onTap: _pickBirthDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _birthDate == null
                          ? 'Chọn ngày sinh'
                          : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}${_birthDate != null ? ' (${_calculateAge(_birthDate!)} tuổi)' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _birthDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Giới tính của bạn là gì?'),
            DropdownButtonFormField<String>(
              value: _gender,
              items: _genders.map((g) => DropdownMenuItem(
                value: g,
                child: Row(
                  children: [
                    Icon(
                      g == 'Nam' ? Icons.male : 
                      g == 'Nữ' ? Icons.female : Icons.transgender,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(g),
                  ],
                ),
              )).toList(),
              onChanged: (val) => setState(() => _gender = val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Chọn giới tính',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyTypeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Bạn thuộc dáng người như nào?'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3,
              ),
              itemCount: _bodyTypes.length,
              itemBuilder: (context, index) {
                final bodyType = _bodyTypes[index];
                final isSelected = _bodyType == bodyType['type'];
                return InkWell(
                  onTap: () => setState(() => _bodyType = bodyType['type']),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bodyType['type']!,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bodyType['description']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNameInput(),
                    _buildDivider(),
                    _buildBirthDatePicker(),
                    _buildDivider(),
                    _buildGenderSelector(),
                    _buildDivider(),
                    _buildBodyTypeSelector(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Tiếp tục'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}