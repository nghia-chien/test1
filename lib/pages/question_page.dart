import 'package:flutter/material.dart';
import '../constants/constants.dart';
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
    {'type': 'Đầy đặn', 'description': 'Dáng người tròn trịa'},
    {'type': 'Cơ bắp', 'description': 'Dáng người có cơ bắp'},
  ];

  bool _isLoading = false;

  // Color scheme
  static const Color primaryBlue = Constants.primaryBlue; // Màu xanh chủ đạo đồng bộ
  static const Color darkBlue = Constants.primaryBlue; // Màu xanh đậm đồng bộ
  static const Color lightGray = Color(0xFFF5F5F5); // Very light gray for backgrounds
  static const Color mediumGray = Color(0xFF9E9E9E); // Medium gray for hints/icons
  static const Color darkGray = Color(0xFF424242); // Dark gray for secondary text/icons
  static const Color black = Color(0xFF212121); // Almost black for main text/titles
  static const Color white = Constants.pureWhite; // Pure white

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
      lastDate: now.subtract(const Duration(days: 365 * 13)), // Minimum 13 years old
      locale: const Locale('vi', 'VN'),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue, // Header background color
              onPrimary: white, // Header text color
              onSurface: black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryBlue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
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
          // Changed to pushAndRemoveUntil to clear the stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
              settings: const RouteSettings(arguments: {'redirectToMain': true}),
            ),
            (route) => false, // Remove all routes below
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
        // Changed to pushAndRemoveUntil to clear the stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
          (route) => false, // Remove all routes below
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
        content: Text(message, style: const TextStyle(color: white)),
        backgroundColor: darkGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: black,
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tên của bạn là gì?'),
        TextFormField(
          controller: _nameController,
          validator: _validateName,
          style: const TextStyle(fontSize: 16, color: black, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Nhập tên đầy đủ',
            hintStyle: const TextStyle(color: mediumGray, fontWeight: FontWeight.w400),
            prefixIcon: const Icon(Icons.person_outline, color: mediumGray, size: 22),
            filled: true, // Ensure background color is applied
            fillColor: white, // Explicitly set background to white
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightGray, width: 1),
            ),
            enabledBorder: OutlineInputBorder( // Ensure consistent border when enabled
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightGray, width: 1),
            ),
            focusedBorder: OutlineInputBorder( // Focus border
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder( // Error border
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: darkGray, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder( // Focused error border
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: darkGray, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBirthDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bạn sinh ngày bao nhiêu?'),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: white, // Explicitly set background to white
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lightGray, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: mediumGray, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _birthDate == null
                        ? 'Chọn ngày sinh'
                        : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year} (${_calculateAge(_birthDate!)} tuổi)',
                    style: TextStyle(
                      fontSize: 16,
                      color: _birthDate == null ? mediumGray : black,
                      fontWeight: _birthDate == null ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: mediumGray),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Giới tính của bạn'),
        DropdownButtonFormField<String>(
          value: _gender,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: mediumGray),
          style: const TextStyle(
            fontSize: 16,
            color: black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Chọn giới tính',
            hintStyle: const TextStyle(color: mediumGray, fontWeight: FontWeight.w400),
            prefixIcon: const Icon(Icons.person_outline, color: mediumGray, size: 22),
            filled: true, // Ensure background color is applied
            fillColor: white, // Explicitly set background to white
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightGray, width: 1),
            ),
            enabledBorder: OutlineInputBorder( // Ensure consistent border when enabled
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightGray, width: 1),
            ),
            focusedBorder: OutlineInputBorder( // Focus border
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder( // Error border
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: darkGray, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder( // Focused error border
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: darkGray, width: 2),
            ),
          ),
          dropdownColor: white, // Ensure dropdown menu itself is white
          items: _genders.map((g) => DropdownMenuItem(
            value: g,
            child: Row(
              children: [
                Icon(
                  g == 'Nam' ? Icons.male :
                  g == 'Nữ' ? Icons.female : Icons.transgender,
                  color: primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  g,
                  style: const TextStyle(
                    color: black,
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: (val) => setState(() => _gender = val),
          selectedItemBuilder: (BuildContext context) {
            return _genders.map((String value) {
              return Text(
                value,
                style: const TextStyle(color: black),
              );
            }).toList();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBodyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn dáng người',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6, // Giảm aspect ratio để item cao hơn, tránh overflow
          ),
          itemCount: _bodyTypes.length,
          itemBuilder: (context, index) {
            final bodyType = _bodyTypes[index];
            final isSelected = _bodyType == bodyType['type'];
            return GestureDetector(
              onTap: () => setState(() => _bodyType = bodyType['type']),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryBlue : white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryBlue : lightGray,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bodyType['type']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? white : black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bodyType['description']!,
                      textAlign: TextAlign.center,
                      maxLines: 2, // Giới hạn 2 dòng
                      overflow: TextOverflow.ellipsis, // Ellipsis nếu tràn
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? white.withOpacity(0.9) : mediumGray,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: darkGray),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Đăng xuất', // Added tooltip for accessibility
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2)) // Consistent strokeWidth
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNameInput(),
                          _buildBirthDatePicker(),
                          _buildGenderSelector(),
                          _buildBodyTypeSelector(),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: white, // Text color for button
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Tiếp tục',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}