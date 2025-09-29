import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../auth.dart';
import '../home_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = AuthService.instance.isAuthenticated;
    setState(() {
      _isAuthenticated = isAuth;
      _isLoading = false;
    });
  }

  void _onAuthStateChanged() {
    setState(() {
      _isAuthenticated = AuthService.instance.isAuthenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return HomeDashboard(onSignOut: _onAuthStateChanged);
    } else {
      return AuthPage(onAuthSuccess: _onAuthStateChanged);
    }
  }
}
