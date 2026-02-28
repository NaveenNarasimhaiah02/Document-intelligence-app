import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/ac.dart';
import 'home_screen.dart';
import '../services/storage_service.dart';
import '../widgets/animated_scanning_logo.dart';

class LoginScreen extends StatefulWidget {
  final StorageService storage;
  const LoginScreen({super.key, required this.storage});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identityController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  Timer? _resendTimer;
  int _secondsRemaining = 0;

  void _login() async {
    if (_isOtpSent) {
      _verifyOtp();
      return;
    }

    final rawInput = _identityController.text.trim();
    if (rawInput.isEmpty) {
      _showSnackBar('Please enter your email or phone number');
      return;
    }

    final input = rawInput;
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
    final digits = input.replaceAll(RegExp(r'\D'), '');
    bool isEmail = emailRegex.hasMatch(input);
    bool isPhone = digits.length >= 10 && !input.contains('@');

    if (!isEmail && !isPhone) {
      _showSnackBar('Please enter a valid email or phone number');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
        _startResendTimer();
      });
      _showSnackBar('OTP sent to $input');
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _secondsRemaining = 300;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _timerText {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _loginAsGuest() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final settingsBox = widget.storage.settingsBox;
    await settingsBox.put('isLoggedIn', true);
    await settingsBox.put('isGuest', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(storage: widget.storage)),
      );
    }
  }

  static const String _dummyOtp = '888888';

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp != _dummyOtp) {
      _showSnackBar('Invalid OTP. Please try 888888 for testing.');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    
    final input = _identityController.text.trim();
    final isEmail = input.contains('@');

    final settingsBox = widget.storage.settingsBox;
    await settingsBox.put('isLoggedIn', true);
    await settingsBox.put('isGuest', false);
    if (isEmail) {
      await settingsBox.put('userEmail', input);
      await settingsBox.put('userPhone', '');
    } else {
      await settingsBox.put('userEmail', '');
      await settingsBox.put('userPhone', input);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(storage: widget.storage)),
      );
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _identityController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AC.header1, AC.header2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Logo Icon
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const ClipOval(
                    child: AnimatedScanningLogo(size: 112),
                  ),
                ),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'SmartScan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Snap. Scan. Done.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Dynamic Input Section
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isOtpSent 
                    ? Column(
                        key: const ValueKey('otp_field'),
                        children: [
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AC.textP, letterSpacing: 8, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            decoration: InputDecoration(
                              hintText: '000000',
                              hintStyle: TextStyle(color: AC.textS.withAlpha(100), letterSpacing: 8),
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              fillColor: Colors.white.withAlpha(240),
                              counterText: "",
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sent to ${_identityController.text}',
                            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          if (_secondsRemaining > 0)
                            Text(
                              'Resend OTP in $_timerText',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            )
                          else
                            TextButton(
                              onPressed: _isLoading ? null : _login,
                              child: const Text('Resend OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              _resendTimer?.cancel();
                              setState(() {
                                _isOtpSent = false;
                                _secondsRemaining = 0;
                              });
                            },
                            child: const Text('Change Email/Phone', style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      )
                    : TextField(
                        key: const ValueKey('id_field'),
                        controller: _identityController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AC.textP),
                        decoration: InputDecoration(
                          hintText: 'Email or Phone Number',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          fillColor: Colors.white.withAlpha(240),
                        ),
                      ),
                ),
                
                const SizedBox(height: 32),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AC.header1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AC.header1))
                      : Text(
                          _isOtpSent ? 'Verify & Login' : 'Send OTP',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ),
                if (!_isOtpSent) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _loginAsGuest,
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(color: Colors.white.withAlpha(220), 
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                
                // Privacy Note
                Text(
                  'Your documents are processed securely and locally.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
