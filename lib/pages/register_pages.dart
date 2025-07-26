import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  String? _errorMessage;
  String? _successMessage;

  // Updated color scheme matching login page
  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkBlue = Color(0xFF231f20);
  static const Color white = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color facebookBlue = Color(0xFF1877F3);
  static const Color black =Color(0xFF000000);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa, 1 chữ thường và 1 số';
    }
    return null;
  }

  // Confirm password validation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  // Handle email/password registration
  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      setState(() => _errorMessage = 'Vui lòng đồng ý với điều khoản sử dụng');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      setState(() {
        _successMessage = 'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.';
      });

      // Navigate back to login page after successful registration
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'weak-password':
            _errorMessage = 'Mật khẩu quá yếu';
            break;
          case 'email-already-in-use':
            _errorMessage = 'Email đã được sử dụng cho tài khoản khác';
            break;
          case 'invalid-email':
            _errorMessage = 'Email không hợp lệ';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Đăng ký email/mật khẩu không được phép';
            break;
          default:
            _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Có lỗi xảy ra: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle Google Sign In
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      setState(() {
        _successMessage = 'Đăng ký với Google thành công!';
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });

    } catch (e) {
      setState(() => _errorMessage = 'Đăng ký Google thất bại: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle Facebook Sign In
  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.token,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        
        setState(() {
          _successMessage = 'Đăng ký với Facebook thành công!';
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        setState(() => _errorMessage = 'Đăng ký Facebook thất bại: ${result.message}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Đăng ký Facebook thất bại: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
             primaryBlue,
              Color.fromARGB(255, 255, 255, 255),
            ],
            
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [      
              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 350),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255 * 0.5).round()),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: darkBlue.withAlpha((255 * 0.3).round()),
                            blurRadius: 30,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            // Container(
                            //   height: 80,
                            //   width: 140,
                            //   decoration: const BoxDecoration(
                            //     image: DecorationImage(
                            //       image: AssetImage('images/logo.png'),
                            //       fit: BoxFit.contain,
                            //     ),
                            //   ),
                            // ),
                            
                            // Title
                            Text(
                              'Tạo tài khoản',
                              style: TextStyle(
                                fontSize: 24,
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'BeautiqueDisplay',
                              ),
                              textAlign: TextAlign.center,
                            ),
                           const SizedBox(height: 20),

                            // Email Field
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkBlue,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'BeautiqueDisplay',
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: '',
                                prefixIcon: Icon(Icons.email_outlined, color: secondaryGrey),
                                filled: true,
                                fillColor: white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round()),),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round()),),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryBlue, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: errorRed),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(color: darkBlue, fontSize: 16),
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Mật khẩu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkBlue,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'BeautiqueDisplay',
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              validator: _validatePassword,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: '',
                                prefixIcon: Icon(Icons.lock_outline, color: secondaryGrey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: secondaryGrey,
                                  ),
                                  onPressed: () {
                                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                                  },
                                ),
                                filled: true,
                                fillColor: white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round()),),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round()),),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryBlue, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: errorRed),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(color: darkBlue, fontSize: 16),
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password Field
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Xác nhận mật khẩu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkBlue,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'BeautiqueDisplay',
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmPasswordController,
                              validator: _validateConfirmPassword,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                hintText: '',
                                prefixIcon: Icon(Icons.lock_outline, color: secondaryGrey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: secondaryGrey,
                                  ),
                                  onPressed: () {
                                    setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                                  },
                                ),
                                filled: true,
                                fillColor: white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round()),),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: secondaryGrey.withAlpha((255 * 0.3).round()),),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryBlue, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: errorRed),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(color: darkBlue, fontSize: 16),
                            ),
                            const SizedBox(height: 20),

                            // Terms and Conditions Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (value) {
                                    setState(() => _agreeToTerms = value ?? false);
                                  },
                                  activeColor: primaryBlue,
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Tôi đồng ý với ',
                                      style: TextStyle(
                                        color: darkBlue,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Điều khoản sử dụng',
                                          style: TextStyle(
                                            color: primaryBlue,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const TextSpan(text: ' và '),
                                        TextSpan(
                                          text: 'Chính sách bảo mật',
                                          style: TextStyle(
                                            color: primaryBlue,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleEmailRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkBlue,
                                  foregroundColor: white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(white),
                                        ),
                                      )
                                    : const Text(
                                        'Đăng ký',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: white,
                                          fontFamily: 'BeautiqueDisplay',
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                                    icon: Image.asset(
                                'images/icon/google.png',
                                height: 20,
                                width: 20,
                              ),//color: facebookBlue),
                                    label: const Text(
                                      'Google',
                                      style: TextStyle(color: facebookBlue, fontWeight: FontWeight.w600),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: facebookBlue,
                                      side: BorderSide(color: facebookBlue.withAlpha((255 * 0.5).round()),),
                                      backgroundColor: white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _handleFacebookSignIn,
                                    icon: const Icon(Icons.facebook, size: 20, color: facebookBlue),
                                    label: const Text(
                                      'Facebook',
                                      style: TextStyle(color: facebookBlue, fontWeight: FontWeight.w600),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: facebookBlue,
                                      side: BorderSide(color: facebookBlue.withAlpha((255 * 0.5).round()),),
                                      backgroundColor: white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Login Link
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Đã có tài khoản? ',
                                  style: TextStyle(
                                    color: darkBlue,
                                    fontSize: 16,
                                  ),
                                  children: [
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Đăng nhập',
                                          style: TextStyle(
                                            color: primaryBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Success Message
                            if (_successMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha((255 * 0.08).round()),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.withAlpha((255 * 0.3).round()),),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _successMessage!,
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Error Message
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: errorRed.withAlpha((255 * 0.08).round()),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: errorRed.withAlpha((255 * 0.03).round()),),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: errorRed, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: errorRed,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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