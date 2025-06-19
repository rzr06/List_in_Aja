import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      _isLogin
          ? await authService.signIn(_email, _password)
          : await authService.signUp(_email, _password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Email atau Password salah silahkan coba kembali'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Column(
            children: [
              _buildHeader(size),
              _buildFormPanel(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildHeader(Size size) {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Image.asset(
              'assets/images/LogoOnly.png',
              height: 120,
            ),
            const SizedBox(height: 10),
            Image.asset(
              'assets/images/TextOnly.png',
              width: 120,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            Text(
              _isLogin ? 'Selamat Datang Kembali' : 'Buat Akun Baru',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 24),
            _buildForm(),
            const Spacer(),
            _buildToggleAuthMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Iconsax.sms),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val!.contains('@') ? null : 'Email tidak valid',
            onSaved: (val) => _email = val!.trim(),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Iconsax.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (val) => val!.length >= 6 ? null : 'Minimal 6 karakter',
            onSaved: (val) => _password = val!.trim(),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
                    icon: Icon(_isLogin ? Iconsax.login : Iconsax.user_add),
                    label: Text(_isLogin ? 'MASUK' : 'DAFTAR'),
                    onPressed: _submit,
                  ),
          ).animate().fadeIn(delay: 500.ms).scaleXY(begin: 0.8),
        ],
      ),
    );
  }
  
  Widget _buildToggleAuthMode() {
    return TextButton(
      child: Text.rich(
        TextSpan(
          text: _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          children: [
            TextSpan(
              text: _isLogin ? 'Daftar disini' : 'Masuk disini',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
      onPressed: () => setState(() => _isLogin = !_isLogin),
    );
  }
}