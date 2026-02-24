// lib/presentation/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

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
  String _dept = 'Automation Engineer';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(children: [
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
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 60)],
                ),
                child: isWide
                    ? Row(children: [
                        Expanded(child: _RegisterBrand()),
                        Expanded(child: _RegisterForm(
                          formKey: _formKey,
                          nameCtrl: _nameCtrl, emailCtrl: _emailCtrl,
                          passCtrl: _passCtrl, confCtrl: _confCtrl,
                          dept: _dept, obscure: _obscure,
                          onDeptChanged: (v) => setState(() => _dept = v!),
                          onToggle: () => setState(() => _obscure = !_obscure),
                          onBack: () => Navigator.pop(context),
                        )),
                      ])
                    : _RegisterForm(
                        formKey: _formKey,
                        nameCtrl: _nameCtrl, emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl, confCtrl: _confCtrl,
                        dept: _dept, obscure: _obscure,
                        onDeptChanged: (v) => setState(() => _dept = v!),
                        onToggle: () => setState(() => _obscure = !_obscure),
                        onBack: () => Navigator.pop(context),
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _RegisterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1525), Color(0xFF0A1020)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.blue])),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Text('TECHNODYSIS',
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w800, fontSize: 18,
                color: AppTheme.textColor)),
          ]),
          const SizedBox(height: 40),
          RichText(text: TextSpan(
            style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w700,
              color: AppTheme.textColor, height: 1.35),
            children: [
              const TextSpan(text: 'Join the\n'),
              TextSpan(text: 'team portal.',
                style: const TextStyle(color: AppTheme.accent)),
            ],
          )),
          const SizedBox(height: 16),
          const Text(
            'Create your account to start tracking and resolving issues for our clients across all automation platforms.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.65)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Admin Approval Required',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.accent)),
              const SizedBox(height: 8),
              const Text(
                'New accounts require admin approval. You\'ll receive confirmation once approved.',
                style: TextStyle(
                  fontSize: 12.5, color: AppTheme.textMuted, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('© 2025 Technodysis • Internal use only',
            style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, passCtrl, confCtrl;
  final String dept;
  final bool obscure;
  final void Function(String?) onDeptChanged;
  final VoidCallback onToggle, onBack;

  const _RegisterForm({
    required this.formKey, required this.nameCtrl, required this.emailCtrl,
    required this.passCtrl, required this.confCtrl,
    required this.dept, required this.obscure,
    required this.onDeptChanged, required this.onToggle, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create account',
              style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textColor)),
            const SizedBox(height: 4),
            const Text('Fill in your details to request access',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 28),

            _buildField('FULL NAME', nameCtrl, 'Your full name'),
            const SizedBox(height: 14),
            _buildField('WORK EMAIL', emailCtrl, 'you@technodysis.com',
              type: TextInputType.emailAddress),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _buildField('PASSWORD', passCtrl,
                'Min 8 characters', obscure: obscure)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('CONFIRM', confCtrl,
                'Repeat password', obscure: obscure)),
            ]),
            const SizedBox(height: 14),
            _label('DEPARTMENT / ROLE'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: dept,
              dropdownColor: AppTheme.inkSoft,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textDim, size: 18),
              items: ['Automation Engineer','Developer','Support Engineer',
                      'Project Manager']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onDeptChanged,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Create Account  →'),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: GestureDetector(
              onTap: onBack,
              child: const Text('Already have an account? Sign in',
                style: TextStyle(
                  fontSize: 13, color: AppTheme.accent,
                  fontWeight: FontWeight.w500)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
      color: AppTheme.textMuted, letterSpacing: 0.6));

  Widget _buildField(String label, TextEditingController ctrl, String hint, {
    TextInputType? type, bool obscure = false,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label(label), const SizedBox(height: 6),
    TextFormField(
      controller: ctrl, obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
      decoration: InputDecoration(hintText: hint),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    ),
  ]);
}
