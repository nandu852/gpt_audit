import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _displayName = TextEditingController();
  bool _busy = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
              setState(() => _busy = true);
              try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
              } catch (e) {
                if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign in failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      // Debug info
      print('Google Sign-In Error: $e');
              } finally {
                if (mounted) setState(() => _busy = false);
              }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
      } else {
        if (_password.text != _confirmPassword.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          return;
        }

        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );

        if (credential.user != null && _displayName.text.trim().isNotEmpty) {
          await credential.user!.updateDisplayName(_displayName.text.trim());
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = '${_isLogin ? 'Sign in' : 'Sign up'} failed';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Password is too weak. Use at least 6 characters.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account with this email already exists.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled. Please contact support.';
            break;
          default:
            errorMessage = '${_isLogin ? 'Sign in' : 'Sign up'} failed: ${e.message}';
        }
      } else {
        errorMessage = '${_isLogin ? 'Sign in' : 'Sign up'} failed: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Debug info
      print('Auth Error: $e');
      print('Error Code: ${e is FirebaseAuthException ? e.code : 'N/A'}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _displayName,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (!_isLogin && (value?.trim().isEmpty ?? true)) {
                        return 'Display name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Password is required';
                    }
                    if (!_isLogin && value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _confirmPassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Please confirm your password';
                      }
                      if (value != _password.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _busy ? null : _submitForm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? "Don't have an account? " : "Already have an account? "),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Sign Up' : 'Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}