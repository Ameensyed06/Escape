import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final state = context.read<AppState>();
    try {
      await state.auth.sendPasswordResetEmail(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.actionOrange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _sent ? _SentState(email: _emailCtrl.text.trim()) : _formView(),
        ),
      ),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.cyanGradient,
              borderRadius: AppRadii.lgRadius,
              boxShadow: AppShadows.glow(AppColors.electricCyan),
            ),
            alignment: Alignment.center,
            child: const Icon(Symbols.lock_reset_rounded, color: Colors.white, size: 32),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),
          const SizedBox(height: 20),
          Text('Forgot your password?', style: Theme.of(context).textTheme.headlineSmall)
              .animate()
              .fadeIn(duration: 300.ms, delay: 60.ms),
          const SizedBox(height: 6),
          const Text(
            "Enter the email on your account and we'll send you a link to reset it.",
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: _loading ? 'Sending…' : 'Send Reset Link',
            onTap: _loading ? null : _sendResetLink,
          ),
        ],
      ),
    );
  }
}

class _SentState extends StatelessWidget {
  const _SentState({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: AppColors.cyanGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow(AppColors.electricCyan),
          ),
          alignment: Alignment.center,
          child: const Icon(Symbols.mark_email_read_rounded, color: Colors.white, size: 40),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),
        const SizedBox(height: 24),
        Text('Check your email', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: const TextStyle(color: AppColors.onSurfaceVariant, height: 1.5),
            children: [
              const TextSpan(text: "We've sent a password reset link to "),
              TextSpan(
                text: email.isEmpty ? 'your email' : email,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.onSurface),
              ),
              const TextSpan(text: '. Open it on this device to set a new password.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        GradientButton(
          label: 'Back to Sign In',
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}
