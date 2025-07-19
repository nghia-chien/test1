import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'register_pages.dart';
import 'main_screen.dart';
import 'package:flutter/foundation.dart';

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

  static const Color primaryBlue = Constants.primaryBlue; // Màu xanh chủ đạo đồng bộ
  static const Color darkBlue = Constants.primaryBlue; // Màu xanh đậm đồng bộ
  static const Color lightBlue = Color(0xFFB6D2FF); // Màu xanh nhạt đồng bộ (gần với #4285F4)
  static const Color white = Constants.pureWhite;
  static const Color black = Constants.darkBlueGrey;
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color facebookBlue = Color(0xFF1877F3);
  static const Color googleBlue = Constants.primaryBlue;

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
              builder: (_) => MainScreen(
                
              ),
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
              builder: (_) => MainScreen(
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Đăng nhập Google thất bại: \\${e.toString()}');
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
                builder: (_) => MainScreen(
                ),
              ),
            );
          }
        }
      } else {
        setState(() => _errorMessage = 'Đăng nhập Facebook thất bại: \\${result.message}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Đăng nhập Facebook thất bại: \\${e.toString()}');
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
      backgroundColor: Constants.pureWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Constants.pureWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Constants.secondaryGrey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Chào mừng đến với',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: black,
                            fontFamily: 'BeautiqueDisplay',
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'WH⬥Y',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: black,
                            fontFamily: 'BeautiqueDisplay',
                           letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: black, // chữ đen
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Nhập email của bạn',
                        hintStyle: TextStyle(color: Constants.secondaryGrey), // xám nhạt
                        prefixIcon: Icon(Icons.email_outlined, color: primaryBlue), // icon hiệu ứng xanh
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryBlue), // border xanh khi focus
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: errorRed),
                        ),
                      ),
                      style: const TextStyle(color: black), // chữ đen
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    Text(
                      'Mật khẩu',
                      style: TextStyle(
                        fontSize: 16,
                        color: black, // chữ đen
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu',
                        hintStyle: TextStyle(color: Constants.secondaryGrey),
                        prefixIcon: Icon(Icons.lock_outline, color: primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: primaryBlue,
                          ),
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: errorRed),
                        ),
                      ),
                      style: const TextStyle(color: black), // chữ đen
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password
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
                    ),
                    const SizedBox(height: 8),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                                  fontWeight: FontWeight.w600,
                                  color: white, // nút chữ trắng
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: primaryBlue.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'hoặc',
                            style: TextStyle(
                              color: Constants.secondaryGrey, // chữ xám
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: primaryBlue.withOpacity(0.3))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social Login Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleFacebookSignIn,
                            icon: const Icon(Icons.facebook, size: 20, color: facebookBlue),
                            label: const Text('Facebook', style: TextStyle(color: facebookBlue)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: facebookBlue,
                              side: const BorderSide(color: facebookBlue),
                              backgroundColor: white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            icon: const Icon(Icons.g_mobiledata, size: 24, color: googleBlue),
                            label: const Text('Google', style: TextStyle(color: googleBlue)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: googleBlue,
                              side: const BorderSide(color: googleBlue),
                              backgroundColor: white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Register Link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Chưa có tài khoản? ',
                          style: TextStyle(
                            color: black, // chữ đen
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
                                    color: primaryBlue, // link hiệu ứng xanh
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
                            color: errorRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: errorRed.withOpacity(0.3)),
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
                    // Thêm nút login nhanh (debug) ở cuối form
                    if (kDebugMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: 'hacphichien@gmail.com',
                              password: '123456',
                            );
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MainScreen()),
                              );
                            }
                          },
                          child: const Text('Login nhanh (debug)'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}