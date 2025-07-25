import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'register_pages.dart';
import 'main_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  // Updated color scheme based on image
  static const Color primaryBlue = Color(0xFF209CFF);
  static const Color secondaryGrey = Color(0xFF7D7F85);
  static const Color darkBlue = Color(0xFF231f20);
  static const Color white = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color facebookBlue = Color(0xFF1877F3);
  static const Color black =Color(0xFF000000);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    return null;
  }

  // Handle email/password login
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Sau khi đăng nhập thành công, kiểm tra redirectToMain
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['redirectToMain'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainScreen(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'Không tìm thấy tài khoản với email này';
            break;
          case 'wrong-password':
            _errorMessage = 'Mật khẩu không chính xác';
            break;
          case 'invalid-email':
            _errorMessage = 'Email không hợp lệ';
            break;
          case 'user-disabled':
            _errorMessage = 'Tài khoản đã bị vô hiệu hóa';
            break;
          case 'too-many-requests':
            _errorMessage = 'Quá nhiều lần thử. Vui lòng thử lại sau';
            break;
          default:
            _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle Google Sign In
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      // Sau khi đăng nhập thành công, kiểm tra redirectToMain
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['redirectToMain'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainScreen(),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Đăng nhập Google thất bại: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle Facebook Sign In
  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.token,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        // Sau khi đăng nhập thành công, kiểm tra redirectToMain
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['redirectToMain'] == true) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MainScreen(),
              ),
            );
          }
        }
      } else {
        setState(() => _errorMessage = 'Đăng nhập Facebook thất bại: ${result.message}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Đăng nhập Facebook thất bại: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle forgot password
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email để khôi phục mật khẩu');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email khôi phục mật khẩu đã được gửi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Không thể gửi email khôi phục: ${e.toString()}');
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
          child: Center(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
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
                      Container(
                        height: 100,
                        width: 180,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('images/logo2.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      //const SizedBox(height: 8),
                      
                      // Subtitle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'With Honor, Be ',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              fontFamily: 'BeautiqueDisplay',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'You',
                            style: TextStyle(
                              fontSize: 14,
                              color: white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              fontFamily: 'BeautiqueDisplay',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

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
                      const SizedBox(height: 24),

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
                      const SizedBox(height: 8),
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
                      //const SizedBox(height: 16),
                      Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: primaryBlue, // link hiệu ứng xanh
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),const SizedBox(height: 30),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailLogin,
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
                                  'Đăng nhập',
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

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: secondaryGrey.withAlpha((255 * 0.5).round()),)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'hoặc',
                              style: TextStyle(
                                color: secondaryGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: secondaryGrey.withAlpha((255 * 0.5).round()),)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Social Login Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              icon: Image.asset(
                                'images/icon/google.png',
                                height: 20,
                                width: 20,
                              ),
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

                      // Register Link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Chưa có tài khoản? ',
                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 16,
                            ),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Đăng ký',
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

                      // Error Message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: errorRed.withAlpha((255 * 0.08).round()),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: errorRed.withAlpha((255 * 0.3).round()),),
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
      ),
    );
  }
}