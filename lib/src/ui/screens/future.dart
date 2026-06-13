import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alter/src/ui/routes.dart';
import 'package:alter/src/ui/theme.dart';
import 'package:alter/src/ui/widgets.dart';
import 'package:alter/src/ui/screens/main_shell.dart';

class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = MainShell.of(context);
    return GradientScaffold(
      bgColors: const [Color(0xFF2A1D52), Color(0xFF130F22), AppColors.bg],
      bgCenter: const Alignment(-0.4, -1.0),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 130),
          children: [
            PrimaryHeader(
              title: 'FUTURE',
              onGear: shell.openSettings,
              onAvatar: () => shell.goTab(4),
            ),
            const SizedBox(height: 22),
            RichText(
              text: TextSpan(
                style: AppText.display(30, height: 1.08, letterSpacing: -0.2),
                children: const [
                  TextSpan(text: "Build the future\nyou're "),
                  TextSpan(
                    text: 'simulating',
                    style: TextStyle(color: AppColors.lime),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Forecast card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orange.withValues(alpha: 0.16),
                    const Color(0xFFFF4D2D).withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FUTURE MODE · WORKLOAD FORECAST',
                        style: AppText.kicker(AppColors.orange, size: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: AppText.body(
                        14.5,
                        color: AppColors.white(0.85),
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(text: 'Overload likely '),
                        TextSpan(
                          text: 'Thu–Sun next week',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' — 3 deliverables in a 48h window. Acting today reduces pressure ~40%.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Backend control center',
              style: AppText.body(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _entry(
              context,
              'All Backend Features',
              'Gateway, services, endpoints, status, and screens',
              AppColors.lime,
              AppColors.greenDeep,
              AlterRoutes.backend,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Mission Control',
              'Gateway health, decision kernel, proof, Future Twin',
              AppColors.purpleLight,
              AppColors.purpleDeep,
              AlterRoutes.mission,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Permission Hub',
              'Mic, notifications, notification access, camera, contacts',
              AppColors.cyan,
              AppColors.cyanDeep,
              AlterRoutes.permissions,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Phone Control + OpenClaw',
              'Accessibility actions, screen read, queue, audit log',
              AppColors.orange,
              AppColors.pink,
              AlterRoutes.openclaw,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Live Notification Feed',
              'Notification monitor and on-device triage',
              AppColors.green,
              AppColors.greenDeep,
              AlterRoutes.feed,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Agent Tool Executor',
              'Planner to tools: apps, settings, screen, text, scroll',
              AppColors.pink,
              AppColors.purpleLight,
              AlterRoutes.agent,
            ),
            const SizedBox(height: 28),
            Text(
              'Backend-powered services',
              style: AppText.body(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _entry(
              context,
              'Clone Council',
              '5 personas debate your decision',
              AppColors.purpleLight,
              AppColors.purpleDeep,
              AlterRoutes.council,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Future Simulator',
              'Compare parallel paths · Fit Score',
              AppColors.cyan,
              AppColors.cyanDeep,
              AlterRoutes.simulator,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Opportunity Radar',
              'Matches found while you slept',
              AppColors.green,
              AppColors.greenDeep,
              AlterRoutes.radar,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Voice Gateway',
              'Hey Alter runtime and action graph',
              AppColors.cyan,
              AppColors.purpleDeep,
              AlterRoutes.voice,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'ALTER Lens',
              'Camera intelligence and memory candidates',
              AppColors.orange,
              AppColors.pink,
              AlterRoutes.lens,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Social Graph',
              'People, paths, recruiters, mentors',
              AppColors.pink,
              AppColors.purpleLight,
              AlterRoutes.social,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Reputation Engine',
              'Trust score, events, strengths, risks',
              AppColors.orange,
              AppColors.limeDeep,
              AlterRoutes.reputation,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'Memory System',
              'Trusted sources and retrieval',
              AppColors.purpleLight,
              AppColors.purpleDeep,
              AlterRoutes.memory,
            ),
            const SizedBox(height: 12),
            _entry(
              context,
              'OfficeKit',
              'Briefings and work-loop artifacts',
              AppColors.green,
              AppColors.cyanDeep,
              AlterRoutes.officeKit,
            ),
            const SizedBox(height: 30),
            Text(
              'Recommended to build your future',
              style: AppText.body(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Each step raises your AI Engineer Fit Score.',
              style: AppText.body(12.5, color: AppColors.white(0.5)),
            ),
            const SizedBox(height: 14),
            ..._recos.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _recoRow(r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    String title,
    String sub,
    Color c1,
    Color c2,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c1.withValues(alpha: 0.18), c1.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c1.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.2),
                  colors: [c1, c2],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.display(17, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: AppText.body(12.5, color: AppColors.white(0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: AppColors.white(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _recoRow(_Reco r) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: r.c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: AppText.body(14.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  r.meta,
                  style: AppText.body(12, color: AppColors.white(0.5)),
                ),
              ],
            ),
          ),
          Text(
            r.fit,
            style: AppText.body(12, weight: FontWeight.w700, color: r.c),
          ),
        ],
      ),
    );
  }
}

class _Reco {
  final String title, meta, fit;
  final Color c;
  const _Reco(this.title, this.meta, this.fit, this.c);
}

const _recos = [
  _Reco(
    'Ship an LLM fine-tuning project',
    'Fills your portfolio gap',
    '+8 fit',
    AppColors.lime,
  ),
  _Reco(
    'Earn the MLOps micro-cert',
    '14 days · high ROI',
    '+5 fit',
    AppColors.cyan,
  ),
  _Reco(
    'Contribute to a vision repo',
    'Builds reputation',
    '+4 fit',
    AppColors.orange,
  ),
];
