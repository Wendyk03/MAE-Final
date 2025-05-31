import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Username is required.';
      });
      return;
    }
    if (_firstNameController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'First name is required.';
      });
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Last name is required.';
      });
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Email is required.';
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Password is required.';
      });
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please confirm your password.';
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _isLoading = false;
        _error = 'Passwords do not match.';
      });
      return;
    }
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Assign role based on email domain
      String email = _emailController.text.trim();
      String role;
      bool requireEmailVerification = false;
      if (email.endsWith('@apu.com')) {
        role = 'admin';
      } else if (email.endsWith('@mail.apu.edu.my')) {
        role = 'apu-user';
      } else {
        role = 'nonapu-user';
        requireEmailVerification = true;
      }

      // Store user credentials and role in a single 'credentials' collection
      await FirebaseFirestore.instance
          .collection('credentials')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': email,
            'username': _usernameController.text.trim(),
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Force reload user to ensure it's up-to-date
      await userCredential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (requireEmailVerification) {
        await user?.sendEmailVerification();
      }
      // Always sign out after registration to prevent auto-login (for all roles)
      await FirebaseAuth.instance.signOut();
      setState(() {
        _isLoading = false;
      });
      // Show confirmation popup after successful sign up
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Sign Up Successful'),
              content: const Text(
                'Your account has been created successfully.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      if (requireEmailVerification) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Verify your email'),
                content: const Text(
                  'A verification link has been sent to your email. Please verify your email before logging in.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/sign-in', (route) => false);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/sign-in', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'weak-password') {
          _error = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          _error = 'The account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          _error = 'The email address is not valid.';
        } else {
          _error = e.message ?? 'Sign up failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Sign up failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
              const Icon(Icons.person_add_alt_1, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Sign Up'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
