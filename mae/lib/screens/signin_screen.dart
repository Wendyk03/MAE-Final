import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({Key? key}) : super(key: key);

  @override
  State<SigninScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      // Reload user to get latest email verification status
      await userCredential.user?.reload();
      final email = _emailController.text.trim();
      // Email verification check for non-apu/non-admin users
      if (!(email.endsWith('@mail.apu.edu.my') || email.endsWith('@apu.com'))) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          setState(() {
            _isLoading = false;
            _error = 'Please verify your email before logging in.';
          });
          return;
        }
      }
      // Fetch user role from Firestore (now from 'credentials' collection)
      final userDoc =
          await FirebaseFirestore.instance
              .collection('credentials')
              .doc(userCredential.user!.uid)
              .get();
      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
          _error = 'User credentials not found. Please contact support.';
        });
        return;
      }
      final role = userDoc['role'];
      setState(() {
        _isLoading = false;
      });
      // Navigate based on role
      if (role == 'admin') {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/admin-home', (route) => false);
      } else if (role == 'apu-user') {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (role == 'nonapu-user') {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home-na', (route) => false);
      } else {
        setState(() {
          _error = 'Unknown user role. Please contact support.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'user-not-found') {
          _error = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          _error = 'Wrong password provided.';
        } else if (e.code == 'invalid-email') {
          _error = 'The email address is not valid.';
        } else {
          _error = e.message ?? 'Login failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Login failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 16),
              const Icon(Icons.lock_outline, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text('Remember Me'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: Text(
                      'Forgotten Password',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Login'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account yet? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/sign-up');
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
