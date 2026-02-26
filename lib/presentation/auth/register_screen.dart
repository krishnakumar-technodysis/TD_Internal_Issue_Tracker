// lib/presentation/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:issue_tracker/presentation/widgets/app_button.dart';
import 'package:issue_tracker/presentation/widgets/app_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  String _dept     = 'Automation Engineer';
  bool   _obscure  = true;
  bool   _obscureConf = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthViewModel>().signUp(
      email:       _emailCtrl.text.trim(),
      password:    _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
      department:  _dept,
    );
    if (ok && mounted) {
      // Navigate to dashboard on success
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(children: [
        // Background glow
        Positioned(top: -100, right: -100,
            child: Container(width: 400, height: 400,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppTheme.blue.withOpacity(0.06), Colors.transparent])))),
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
                      color: Colors.black.withOpacity(0.6), blurRadius: 60)],
                ),
                child: isWide
                    ? Row(children: [
                  Expanded(child: _BrandPanel()),
                  Expanded(child: _buildForm(context)),
                ])
                    : _buildForm(context),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildForm(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final loading = vm.state == AuthState.loading;

    return Container(
      padding: const EdgeInsets.all(48),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text('Create account',
                style: GoogleFonts.cabin(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppTheme.textColor)),
            const SizedBox(height: 4),
            const Text('Fill in your details to get started',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 28),

            // Error banner
            if (vm.errorMessage != null) ...[
              Container(
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
              const SizedBox(height: 16),
            ],

            // Full name
            _label('FULL NAME'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                  fontSize: 13.5, color: AppTheme.textColor),
              decoration: const InputDecoration(
                  hintText: 'e.g. Amos Khumalo',
                  prefixIcon: Icon(Icons.person_outline,
                      size: 17, color: AppTheme.textDim)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Full name is required';
                if (v.trim().length < 2) return 'Name is too short';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Email
            _label('WORK EMAIL'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                  fontSize: 13.5, color: AppTheme.textColor),
              decoration: const InputDecoration(
                  hintText: 'you@technodysis.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      size: 17, color: AppTheme.textDim)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$');
                if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password + Confirm side by side
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('PASSWORD'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppTheme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Min 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 17, color: AppTheme.textDim),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 17, color: AppTheme.textDim),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('CONFIRM PASSWORD'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confCtrl,
                    obscureText: _obscureConf,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppTheme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Repeat password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 17, color: AppTheme.textDim),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureConf
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 17, color: AppTheme.textDim),
                        onPressed: () =>
                            setState(() => _obscureConf = !_obscureConf),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm';
                      if (v != _passCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 14),

            // Department
            _label('DEPARTMENT / ROLE'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _dept,
              dropdownColor: AppTheme.inkSoft,
              style: const TextStyle(
                  fontSize: 13.5, color: AppTheme.textColor),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textDim, size: 18),
              items: [
                'Automation Engineer',
                'Software Developer',
                'Support Engineer',
                'Project Manager',
                'Business Analyst',
                'Solution Architect'
                'Mobile Architect',
                'Senior Management'
              ].map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              )).toList(),
              onChanged: (v) => setState(() => _dept = v!),
              validator: (v) =>
              v == null || v.isEmpty ? 'Select a department' : null,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 24),

            // Register button
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: loading ? null : _register,
            //     child: loading
            //         ? const SizedBox(height: 18, width: 18,
            //         child: CircularProgressIndicator(
            //             strokeWidth: 2, color: AppTheme.ink))
            //         : const Text('Create Account  →'),
            //   ),
            // ),
            SizedBox(
                width: double.infinity,
                height: 40,
                child: AppButton.wide(
                  label: 'Create Account  →',
                  loading: vm.state == AuthState.loading,
                  onPressed: _register,
                )
            ),
            const SizedBox(height: 20),

            // Sign in link
            Center(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.accent,
                      fontWeight: FontWeight.w500)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600,
          color: AppTheme.textMuted, letterSpacing: 0.6));
}

// ── Brand panel (left side on wide screens) ──────────────────────────
class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF0D1525), Color(0xFF0A1020)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(children: [
            const AppImage.asset(
              'assets/images/td_logo.png',
              width: 40, height: 40,
              shape: AppImageShape.rectangle,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Text('TECHNODYSIS',
                style: GoogleFonts.cabin(
                    fontWeight: FontWeight.w800, fontSize: 18,
                    color: Colors.white70)),
          ]),
          const SizedBox(height: 40),

          // Headline
          RichText(text: TextSpan(
            style: GoogleFonts.cabin(
                fontSize: 23, fontWeight: FontWeight.w700,
                color: Colors.white70, height: 1.35),
            children: const [
              TextSpan(text: 'Join the\n'),
              TextSpan(text: 'team portal.',
                  style: TextStyle(color: Colors.white70)),
            ],
          )),
          const SizedBox(height: 16),

          const Text(
              'Create your account to start tracking and resolving issues for our clients across all automation platforms.',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textDim, height: 1.65)),
          const SizedBox(height: 32),

          // What happens after
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What happens next?',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppTheme.textDim)),
                const SizedBox(height: 10),
                ...[
                  '1. Your account is created immediately',
                  '2. You can log in and start tracking issues',
                  '3. Admin can upgrade your role anytime',
                ].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('→ ',
                          style: TextStyle(
                              color: AppTheme.accent, fontSize: 12)),
                      Expanded(child: Text(s,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textDim,
                              height: 1.5))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('© 2026 Technodysis PVT LTD • All Rights Reserved.',
              style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
        ],
      ),
    );
  }
}
