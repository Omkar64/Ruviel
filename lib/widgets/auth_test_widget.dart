import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// Simple test to verify auth state persistence
class AuthTestWidget extends StatefulWidget {
  const AuthTestWidget({super.key});

  @override
  State<AuthTestWidget> createState() => _AuthTestWidgetState();
}

class _AuthTestWidgetState extends State<AuthTestWidget> {
  String _authStatus = 'Checking...';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  void _checkAuthStatus() {
    final isAuth = AuthService.isAuthenticated;
    final userId = AuthService.currentUserId;
    setState(() {
      _authStatus = isAuth ? 'Authenticated' : 'Not Authenticated';
      _currentUserId = userId;
    });
    print('Auth Status: $_authStatus, User ID: $_currentUserId');
  }

  void _listenToAuthChanges() {
    AuthService.authStateChanges.listen((AuthState authState) {
      final isAuth = authState.session != null;
      final userId = authState.session?.user?.id;
      setState(() {
        _authStatus = isAuth ? 'Authenticated' : 'Not Authenticated';
        _currentUserId = userId;
      });
      print('Auth State Changed: $_authStatus, User ID: $_currentUserId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Auth Status: $_authStatus'),
            if (_currentUserId != null) 
              Text('User ID: $_currentUserId'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAuthStatus,
              child: const Text('Recheck Auth Status'),
            ),
          ],
        ),
      ),
    );
  }
}