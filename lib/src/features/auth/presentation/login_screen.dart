import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/premium_controls.dart';
import '../application/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUp(email, password);
      } else {
        await auth.signIn(email, password);
      }
      if (mounted) context.go('/permissions');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AmbientScaffold(
        scrollable: false,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientBorderPanel(
                      child: GlassPanel(
                        padding: const EdgeInsets.all(22),
                        child: Icon(
                          LucideIcons.sparkles,
                          size: 42,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2100.ms, color: Colors.white54),
                const SizedBox(height: 24),
                GradientText(
                  'ALTER',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ).animate().fadeIn(duration: 480.ms),
                const SizedBox(height: 6),
                Text(
                  'Voice-first AI Future Operating System',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 120.ms, duration: 480.ms),
                const SizedBox(height: 32),
                GlassPanel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isSignUp ? 'Create account' : 'Sign in',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Field(
                        controller: _emailController,
                        label: 'Email',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _passwordController,
                        label: 'Password',
                        icon: LucideIcons.lock,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? LucideIcons.eye : LucideIcons.eye_off,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AlterPalette.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.circle_alert,
                                color: AlterPalette.danger,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AlterPalette.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      PremiumButton(
                        label: _loading
                            ? 'Please wait…'
                            : (_isSignUp ? 'Create account' : 'Sign in'),
                        icon: _loading
                            ? LucideIcons.loader
                            : LucideIcons.arrow_right,
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() {
                          _isSignUp = !_isSignUp;
                          _error = null;
                        }),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign in'
                              : "Don't have an account? Sign up",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AlterPalette.iris,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlterPalette.iris, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
