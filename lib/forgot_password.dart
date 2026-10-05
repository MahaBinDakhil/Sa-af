import 'package:flutter/material.dart';

import 'services/auth_service.dart';

const Color darkGreen = Color(0xFF17372A);
const Color buttonGreen = Color(0xFF1F6B45);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await AuthService().sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: darkGreen,
            title: const Text(
              'Check your email',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'A password reset link has been sent to $email.',
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: buttonGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthService.errorMessage(e),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ==================================================
                // BACK BUTTON
                // ==================================================

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // LOGO
                // ==================================================

                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // TITLE
                // ==================================================

                const Center(
                  child: Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                const Center(
                  child: Text(
                    'Enter your email address and we will send you\na link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ==================================================
                // EMAIL LABEL
                // ==================================================

                const Text(
                  'Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // EMAIL FIELD
                // ==================================================

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2E604F),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: buttonGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // SEND RESET LINK
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          buttonGreen.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // BACK TO LOGIN
                // ==================================================

                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}