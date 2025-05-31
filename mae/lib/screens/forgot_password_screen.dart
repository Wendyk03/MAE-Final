import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    print("Trying to send reset email to: $email");
    setState(() {
      _isLoading = true;
      _message = null;
    });
    // Validate email is not empty
    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Please enter your email.'),
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
      return;
    }
    // Validate email format
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _isLoading = false;
      });
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Please enter a valid email address.'),
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
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isLoading = false;
      });
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Reset Link Sent'),
              content: const Text(
                'If an account exists for this email, a password reset link has been sent.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('FirebaseAuthException code: \\${e.code}');
      print('Full error: \\${e}');
      String errorMsg = 'Failed to send reset link. Please try again.';
      if (e.code == 'invalid-email') {
        errorMsg = 'The email address is not valid.';
      } else if (e.code == 'missing-android-pkg-name' ||
          e.code == 'missing-continue-uri' ||
          e.code == 'missing-ios-bundle-id') {
        errorMsg = 'App configuration error. Please contact support.';
      } else if (e.code == 'network-request-failed') {
        errorMsg = 'Network error. Please check your connection.';
      }
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(errorMsg),
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
      return;
    } catch (e) {
      setState(() {
        _isLoading = false;
        print('Full error: $e');
      });
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text(
                'Failed to send reset link. Please try again.',
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
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 16),
              const Icon(Icons.lock_reset, size: 56, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Enter your email to receive a password reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Send Reset Link'),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!, style: const TextStyle(color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
