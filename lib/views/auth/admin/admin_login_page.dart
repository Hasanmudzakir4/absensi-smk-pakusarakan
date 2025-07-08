import 'package:absensi_smk_pakusarakan/controllers/auth_controller.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/widget/login_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthController>(
        builder: (context, authController, _) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
                isPasswordVisible: isPasswordVisible,
                onPasswordToggle: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
                isLoading: authController.isLoading,
                onLogin: () => _login(authController),
              ),
            ),
          );
        },
      ),
    );
  }

  void _login(AuthController authController) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    await authController.login(email, password, context);
  }
}
