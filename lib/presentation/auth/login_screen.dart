// lib/presentation/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'auth_viewmodel.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'admin@technodysis.com');
  final _passCtrl  = TextEditingController(text: '123456');
  bool _obscure    = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthViewModel>().signIn(
      _emailCtrl.text.trim(), _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(children: [
        // Background radial glows
        Positioned(top: -100, left: -100,
          child: Container(width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.accent.withOpacity(0.06), Colors.transparent])))),
        Positioned(bottom: -100, right: -100,
          child: Container(width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.blue.withOpacity(0.06), Colors.transparent])))),
        // Grid overlay
        Opacity(opacity: 0.03,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(''),
                fit: BoxFit.cover)))),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 60, offset: const Offset(0, 30))],
                ),
                child: isWide
                    ? Row(children: [
                        Expanded(child: _BrandPanel()),
                        Expanded(child: _FormPanel(
                          formKey: _formKey, emailCtrl: _emailCtrl,
                          passCtrl: _passCtrl, obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          onLogin: _login, vm: vm,
                          onRegister: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        )),
                      ])
                    : Column(children: [
                        _FormPanel(
                          formKey: _formKey, emailCtrl: _emailCtrl,
                          passCtrl: _passCtrl, obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          onLogin: _login, vm: vm,
                          onRegister: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        ),
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D1525), Color(0xFF0A1020)]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand mark
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.blue]),
              ),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TECHNODYSIS',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w800, fontSize: 18,
                  color: AppTheme.textColor)),
              const Text('Issue Tracker',
                style: TextStyle(
                  fontSize: 11, color: AppTheme.textMuted, letterSpacing: 1)),
            ]),
          ]),
          const SizedBox(height: 40),
          RichText(text: TextSpan(
            style: GoogleFonts.syne(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: AppTheme.textColor, height: 1.35),
            children: [
              const TextSpan(text: 'Track issues.\nShip '),
              TextSpan(text: 'faster.',
                style: const TextStyle(color: AppTheme.accent)),
            ],
          )),
          const SizedBox(height: 14),
          const Text(
            'A centralized internal portal for managing technical issues, root cause analysis, and resolution tracking across all client systems.',
            style: TextStyle(
              fontSize: 13, color: AppTheme.textMuted, height: 1.65)),
          const SizedBox(height: 32),
          ...[
            'Real-time issue tracking across all clients',
            'Full audit trail — who opened, resolved, closed',
            'Root cause analytics and trend reporting',
            'Role-based access — Admin & User',
          ].map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.12),
                  border: Border.all(color: AppTheme.accent)),
                child: const Center(
                  child: Text('✓',
                    style: TextStyle(fontSize: 10, color: AppTheme.accent)))),
              const SizedBox(width: 10),
              Expanded(child: Text(f,
                style: const TextStyle(
                  fontSize: 12.5, color: AppTheme.textMuted))),
            ]),
          )),
          const SizedBox(height: 32),
          const Text('© 2025 Technodysis • Internal use only',
            style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure, onLogin, onRegister;
  final AuthViewModel vm;

  const _FormPanel({
    required this.formKey, required this.emailCtrl,
    required this.passCtrl, required this.obscure,
    required this.onToggleObscure, required this.onLogin,
    required this.onRegister, required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16), bottomRight: Radius.circular(16),
          topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome back',
              style: GoogleFonts.syne(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textColor)),
            const SizedBox(height: 4),
            const Text('Sign in to your Technodysis account',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 30),

            // Email
            _FieldLabel('EMAIL ADDRESS'),
            const SizedBox(height: 6),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
              decoration: const InputDecoration(
                hintText: 'you@technodysis.com',
                prefixIcon: Icon(Icons.email_outlined,
                  size: 17, color: AppTheme.textDim)),
              validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
            ),
            const SizedBox(height: 16),

            // Password
            _FieldLabel('PASSWORD'),
            const SizedBox(height: 6),
            TextFormField(
              controller: passCtrl,
              obscureText: obscure,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline,
                  size: 17, color: AppTheme.textDim),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                    size: 17, color: AppTheme.textDim),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
              onFieldSubmitted: (_) => onLogin(),
            ),
            const SizedBox(height: 16),

            // Remember / Forgot
            Row(children: [
              const SizedBox.shrink(),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Text('Forgot password?',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.accent))),
            ]),
            const SizedBox(height: 24),

            // Error
            if (vm.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                    size: 16, color: AppTheme.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(vm.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12.5, color: AppTheme.red))),
                ]),
              ),

            // Sign in button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.state == AuthState.loading ? null : onLogin,
                child: vm.state == AuthState.loading
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.ink))
                    : const Text('Sign In  →'),
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                  style: const TextStyle(
                    fontSize: 11, color: AppTheme.textDim))),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),

            // Demo credentials
            Row(children: [
              Expanded(child: _DemoCard(
                role: 'Admin',
                email: 'admin@technodysis.com',
                color: AppTheme.accent,
                onTap: () {/* fill */ },
              )),
              const SizedBox(width: 10),
              Expanded(child: _DemoCard(
                role: 'User',
                email: 'user@technodysis.com',
                color: AppTheme.blue,
                onTap: () {},
              )),
            ]),
            const SizedBox(height: 24),

            Center(child: RichText(text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              children: [
                const TextSpan(text: "Don't have an account? "),
                WidgetSpan(child: GestureDetector(
                  onTap: onRegister,
                  child: const Text('Request access',
                    style: TextStyle(
                      fontSize: 13, color: AppTheme.accent,
                      fontWeight: FontWeight.w500)),
                )),
              ],
            ))),
          ],
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String role, email;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.role, required this.email,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.inkSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(role,
          style: const TextStyle(
            fontSize: 10.5, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(email,
          style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
          overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 10.5, fontWeight: FontWeight.w600,
      color: AppTheme.textMuted, letterSpacing: 0.6));
}
