// lib/presentation/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool    _loading = false;
  bool    _sent    = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthViewModel>()
          .sendPasswordReset(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      setState(() {
        _error = e.toString().contains('user-not-found')
            ? 'No account found for this email address.'
            : 'Failed to send reset email. Please try again.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blueDim,
      body: Stack(children: [
        Positioned(top: -100, left: -100,
            child: _Glow(AppTheme.accent.withOpacity(0.06))),
        Positioned(bottom: -100, right: -100,
            child: _Glow(AppTheme.blue.withOpacity(0.06))),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 60, offset: const Offset(0, 30))],
                ),
                child: _sent ? _SuccessView(
                  email: _emailCtrl.text.trim(),
                  onBack: () => Navigator.pop(context),
                ) : _FormView(
                  formKey:   _formKey,
                  emailCtrl: _emailCtrl,
                  loading:   _loading,
                  error:     _error,
                  onSubmit:  _submit,
                  onBack:    () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Form ─────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit, onBack;
  const _FormView({required this.formKey, required this.emailCtrl,
    required this.loading, required this.error,
    required this.onSubmit, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.arrow_back_rounded, size: 15, color: AppTheme.textDim),
              SizedBox(width: 4),
              Text('Back to Sign In',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textDim)),
            ]),
          ),
          const SizedBox(height: 28),

          // Icon
          Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: AppTheme.accentBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2))),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppTheme.accent, size: 26)),
          const SizedBox(height: 20),

          Text('Reset Password',
              style: GoogleFonts.cabin(fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppTheme.textColor)),
          const SizedBox(height: 8),
          const Text(
              "Enter your email and we'll send you a link to reset your password.",
              style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.5)),
          const SizedBox(height: 28),

          // Error
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.red.withOpacity(0.25))),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, size: 15, color: AppTheme.red),
                const SizedBox(width: 8),
                Expanded(child: Text(error!,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.red))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Email field label
          const Text('EMAIL ADDRESS',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
            decoration: const InputDecoration(
                hintText: 'you@technodysis.com',
                prefixIcon: Icon(Icons.email_outlined, size: 17, color: AppTheme.textDim)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('Send Reset Link',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success ───────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String email;
  final VoidCallback onBack;
  const _SuccessView({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: AppTheme.greenBg, shape: BoxShape.circle,
              border: Border.all(color: AppTheme.green.withOpacity(0.3))),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppTheme.green, size: 28)),
      const SizedBox(height: 20),
      Text('Check your email',
          style: GoogleFonts.cabin(fontSize: 20, fontWeight: FontWeight.w700,
              color: AppTheme.textColor)),
      const SizedBox(height: 12),
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.6),
          children: [
            const TextSpan(text: 'A password reset link was sent to\n'),
            TextSpan(text: email,
                style: const TextStyle(
                    color: AppTheme.textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      const SizedBox(height: 6),
      const Text("Check your spam folder if you don't see it.",
          style: TextStyle(fontSize: 12, color: AppTheme.textDim),
          textAlign: TextAlign.center),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity, height: 44,
        child: ElevatedButton(
          onPressed: onBack,
          child: const Text('Back to Sign In',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow(this.color);
  @override
  Widget build(BuildContext context) => Container(
      width: 400, height: 400,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent])));
}