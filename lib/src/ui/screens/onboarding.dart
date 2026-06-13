import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alter/src/features/auth/application/auth_provider.dart';
import 'package:alter/src/features/profile/application/profile_provider.dart';
import 'package:alter/src/features/profile/domain/user_profile.dart';
import 'package:alter/src/ui/routes.dart';
import 'package:alter/src/ui/theme.dart';
import 'package:alter/src/ui/widgets.dart';

// ============================================================
// Login
// ============================================================
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter email and password.');
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
      if (mounted) context.go(AlterRoutes.permissions);
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
    return Scaffold(
      body: GradientScaffold(
        bgColors: const [Color(0xFF2A1F4A), Color(0xFF15101F), AppColors.bg],
        bgCenter: const Alignment(0.0, -1.0),
        orbs: [
          PositionedOrb(
            top: -40,
            left: 0,
            right: 0,
            orb: Orb(
              size: 280,
              blur: 20,
              colors: [AppColors.purple.withValues(alpha: 0.6)],
            ),
          ),
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.white(0.14)),
                  ),
                  child: const StarMark(size: 26),
                ),
                const SizedBox(height: 26),
                Text(
                  'Welcome to your\nfuture.',
                  style: AppText.display(34, weight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in and Alter starts learning your context.',
                  style: AppText.body(15, color: AppColors.white(0.55)),
                ),
                const SizedBox(height: 34),
                _field(Icons.mail_outline, 'Email', controller: _email),
                const SizedBox(height: 12),
                _field(
                  Icons.lock_outline,
                  'Password',
                  controller: _password,
                  obscure: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppText.body(13, color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 18),
                LimeButton(
                  label: _loading
                      ? 'Please wait…'
                      : (_isSignUp ? 'Create account' : 'Continue'),
                  trailing: null,
                  onTap: _loading ? null : _submit,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() {
                    _isSignUp = !_isSignUp;
                    _error = null;
                  }),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : "Don't have an account? Sign up",
                    style: AppText.body(
                      13,
                      weight: FontWeight.w600,
                      color: AppColors.lime,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 1, color: AppColors.white(0.12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: AppText.body(12, color: AppColors.white(0.3)),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 1, color: AppColors.white(0.12)),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(child: _social('Google', _submit)),
                    const SizedBox(width: 12),
                    Expanded(child: _social('Apple', _submit)),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'Privacy-first · on-device by default',
                    style: AppText.body(12, color: AppColors.white(0.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    IconData icon,
    String hint, {
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.white(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.white(0.4)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: AppText.body(15, color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppText.body(15, color: AppColors.white(0.45)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _social(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white(0.12)),
        ),
        child: Text(label, style: AppText.body(14, weight: FontWeight.w600)),
      ),
    );
  }
}

// ============================================================
// Languages
// ============================================================
class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});
  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  static const all = [
    'English',
    'Hindi',
    'Kannada',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Marathi',
    'Bengali',
  ];
  final selected = <String>{'English', 'Hindi'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientScaffold(
        bgColors: const [Color(0xFF2C2150), Color(0xFF15101F), AppColors.bg],
        bgCenter: const Alignment(0.6, -1.0),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP 1 OF 2', style: AppText.kicker(AppColors.lime)),
                const SizedBox(height: 14),
                Text(
                  'What languages\ndo you speak?',
                  style: AppText.display(
                    32,
                    weight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Alter thinks natively in each — switch mid-sentence and it '
                  'keeps up.',
                  style: AppText.body(14.5, color: AppColors.white(0.55)),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 11,
                  runSpacing: 11,
                  children: all
                      .map(
                        (l) => PillChip(
                          label: l,
                          selected: selected.contains(l),
                          onTap: () => setState(() {
                            selected.contains(l)
                                ? selected.remove(l)
                                : selected.add(l);
                          }),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                LimeButton(
                  label: 'Continue',
                  onTap: () => context.go(AlterRoutes.about),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// About You
// ============================================================
class AboutYouScreen extends ConsumerStatefulWidget {
  const AboutYouScreen({super.key});
  @override
  ConsumerState<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends ConsumerState<AboutYouScreen> {
  static const roles = [
    'Student',
    'Working',
    'Job seeker',
    'Founder',
    'Career switcher',
    'Researcher',
  ];
  String role = 'Student';
  bool _saving = false;
  String? _error;

  Future<void> _enterAlter() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) context.go(AlterRoutes.login);
        return;
      }

      final existing = ref.read(userProfileProvider).asData?.value;
      final existingName = existing?.displayName.trim();
      final profile = UserProfile(
        id: user.id,
        displayName: existingName != null && existingName.isNotEmpty
            ? existingName
            : user.email?.split('@').first ?? 'Alter user',
        role: role,
        careerStage: role,
        industry: existing?.industry ?? '',
        bio: existing?.bio.isNotEmpty == true
            ? existing!.bio
            : 'Aspiring AI Engineer',
        skills: existing?.skills.isNotEmpty == true
            ? existing!.skills
            : const ['Python', 'React', 'ML'],
        goals: existing?.goals.isNotEmpty == true
            ? existing!.goals
            : const ['Become an AI Engineer'],
        interests: existing?.interests ?? const [],
        openaiKey: existing?.openaiKey ?? '',
        onboardingDone: true,
      );

      try {
        await ref.read(userProfileProvider.notifier).save(profile);
      } catch (_) {
        ref.read(userProfileProvider.notifier).setLocal(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile sync failed. Entering ALTER locally.'),
            ),
          );
        }
      }

      if (mounted) context.go(AlterRoutes.home);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientScaffold(
        bgColors: const [Color(0xFF3A2566), Color(0xFF15101F), AppColors.bg],
        bgCenter: const Alignment(-0.6, -1.0),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP 2 OF 2', style: AppText.kicker(AppColors.lime)),
                const SizedBox(height: 14),
                Text(
                  'Tell us more\nabout yourself.',
                  style: AppText.display(
                    32,
                    weight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'WHERE ARE YOU RIGHT NOW?',
                  style: AppText.kicker(AppColors.white(0.45), size: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: roles
                      .map(
                        (r) => PillChip(
                          label: r,
                          selected: role == r,
                          onTap: () => setState(() => role = r),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 26),
                Text(
                  'YOUR CURRENT STATE',
                  style: AppText.kicker(AppColors.white(0.45), size: 12),
                ),
                const SizedBox(height: 12),
                _stateRow('B.Tech · CSE, Year 3', 'Python · React · some ML'),
                const SizedBox(height: 10),
                _stateRow(
                  'Tier-2 city · Open to remote',
                  '~15 focus hours / week',
                ),
                const SizedBox(height: 26),
                Text(
                  'FUTURE PLANS',
                  style: AppText.kicker(AppColors.white(0.45), size: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lime.withValues(alpha: 0.14),
                        AppColors.purple.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.lime.withValues(alpha: 0.25),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: AppText.body(
                        15,
                        color: AppColors.white(0.85),
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(text: '"I want to become an '),
                        TextSpan(
                          text: 'AI Engineer',
                          style: TextStyle(
                            color: AppColors.lime,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' and ship something of my own within 3 years."',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppText.body(13, color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                ],
                LimeButton(
                  label: _saving ? 'Entering...' : 'Enter Alter',
                  height: 62,
                  onTap: _saving ? null : _enterAlter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateRow(String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppText.body(12.5, color: AppColors.white(0.5)),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, size: 18, color: AppColors.lime),
        ],
      ),
    );
  }
}
