import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Shown right after sign-up when the Supabase project requires the user
/// to click a confirmation link before they can sign in.
class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  bool _resending = false;
  bool _resent = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    final state = context.read<AppState>();
    try {
      await state.auth.resendConfirmationEmail(widget.email);
      if (mounted) setState(() => _resent = true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.actionOrange),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
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
              Text(
                'Check your email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: const TextStyle(color: AppColors.onSurfaceVariant, height: 1.5),
                  children: [
                    const TextSpan(text: "We've sent a confirmation link to "),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.onSurface),
                    ),
                    const TextSpan(
                      text: '. Tap the link to activate your account, then come back and sign in.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              const SizedBox(height: 32),
              if (_resent)
                const Pill(
                  label: 'Email resent',
                  icon: Symbols.check_circle_rounded,
                  color: AppColors.cyanSoft,
                  textColor: AppColors.cyanDeep,
                ),
              if (_resent) const SizedBox(height: 20),
              OutlineButton(
                label: _resending ? 'Sending…' : 'Resend Email',
                icon: Symbols.mail_outline_rounded,
                onTap: _resending ? () {} : _resend,
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: 'Back to Sign In',
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
