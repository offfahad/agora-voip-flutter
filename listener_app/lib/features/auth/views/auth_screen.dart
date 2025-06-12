import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/error_snakbar.dart';
import '../view_models/auth_view_model.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  final bool isListenerApp;

  const AuthScreen({
    super.key,
    required this.isLogin,
    required this.isListenerApp,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                style: const TextStyle(fontSize: 16, color: Colors.white),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter your valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(fontSize: 16, color: Colors.white),
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  disabledBackgroundColor: Colors.deepPurpleAccent,
                  disabledForegroundColor: Colors.white,
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: authViewModel.isLoading
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        if (_formKey.currentState!.validate()) {
                          final success = widget.isLogin
                              ? await authViewModel.signIn(
                                  _emailController.text,
                                  _passwordController.text,
                                )
                              : await authViewModel.signUp(
                                  _emailController.text,
                                  _passwordController.text,
                                  widget.isListenerApp,
                                );
                          if (success && mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              widget.isListenerApp
                                  ? '/listener_home'
                                  : '/caller_home',
                            );
                          } else if (authViewModel.error != null) {
                            showErrorSnackbar(context, authViewModel.error!);
                          }
                        }
                      },
                child: authViewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isLogin ? 'Login' : 'Register'),
              ),
              const SizedBox(height: 16),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthScreen(
                        isLogin: !widget.isLogin,
                        isListenerApp: widget.isListenerApp,
                      ),
                    ),
                  );
                },
                child: Text(
                  widget.isLogin
                      ? 'Need an account? Register'
                      : 'Have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
