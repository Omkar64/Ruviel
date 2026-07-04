import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _currentAuthState = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    // Listen to auth state changes
    AuthService.authStateChanges.listen((isAuth) {
      if (mounted) {
        setState(() {
          _currentAuthState = isAuth;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _checkAuthState() async {
    final isAuth = await AuthService.isAuthenticated();
    if (mounted) {
      setState(() {
        _currentAuthState = isAuth;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // Return the appropriate screen - NO MaterialApp here!
    return _currentAuthState
        ? const HomeScreen()
        : const LoginScreen();
  }
}