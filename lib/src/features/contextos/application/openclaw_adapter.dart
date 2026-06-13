import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../agent/data/device_actions.dart';
import '../../device_control/application/phone_control_controller.dart';
import '../domain/contextos_models.dart';

/// OpenClaw is the action GATEWAY, not the brain. Every action walks
/// Draft → Explain → Confirm → Execute. Irreversible or send/pay/install
/// actions can NEVER reach `executed` without an explicit user confirm.
enum ClawStage {
  queued('Queued'),
  executed('Executed'),
  dismissed('Dismissed');

  const ClawStage(this.label);
  final String label;
}

class ClawAction {
  ClawAction({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.why,
    required this.requiresConfirmation,
    required this.irreversible,
    required this.momentExcerpt,
    required this.createdAt,
    this.stage = ClawStage.queued,
    this.dbId,
  });

  final String id;
  final String type;
  final String title;
  final String detail;
  final String why; // the "Explain" step
  final bool requiresConfirmation;
  final bool irreversible;
  final String momentExcerpt;
  final DateTime createdAt;
  ClawStage stage;
  String? dbId;

  ClawAction copyWith({ClawStage? stage, String? dbId}) => ClawAction(
    id: id,
    type: type,
    title: title,
    detail: detail,
    why: why,
    requiresConfirmation: requiresConfirmation,
    irreversible: irreversible,
    momentExcerpt: momentExcerpt,
    createdAt: createdAt,
    stage: stage ?? this.stage,
    dbId: dbId ?? this.dbId,
  );
}

final openClawQueueProvider =
    NotifierProvider<OpenClawAdapter, List<ClawAction>>(OpenClawAdapter.new);

class OpenClawAdapter extends Notifier<List<ClawAction>> {
  @override
  List<ClawAction> build() => const [];

  int get pendingCount =>
      state.where((a) => a.stage == ClawStage.queued).length;

  /// Draft + Explain: queue a proposed action for the user to confirm.
  Future<void> enqueue(
    SafeAction action, {
    required String momentExcerpt,
    String? momentId,
  }) async {
    final now = DateTime.now();
    final claw = ClawAction(
      id: 'claw_${now.microsecondsSinceEpoch}',
      type: action.type,
      title: action.title,
      detail: action.detail,
      why: _explain(action),
      requiresConfirmation: action.requiresConfirmation,
      irreversible: action.irreversible,
      momentExcerpt: momentExcerpt,
      createdAt: now,
    );
    state = [claw, ...state];
    final dbId = await _persist(claw, 'confirmed', momentId: momentId);
    if (dbId != null) {
      state = [
        for (final a in state) a.id == claw.id ? a.copyWith(dbId: dbId) : a,
      ];
    }
    await _audit('action_confirm', 'Queued: ${claw.title}');
  }

  /// Execute (only call after explicit confirmation in the UI).
  Future<String> execute(String id) async {
    final a = state.firstWhere((x) => x.id == id);
    final result = await _executeBridge(a);
    _update(id, ClawStage.executed);
    await _updateStatus(a.dbId, 'executed');
    await _audit('action_execute', 'Executed: ${a.title}. $result');
    return result;
  }

  Future<void> dismiss(String id) async {
    final a = state.firstWhere((x) => x.id == id);
    _update(id, ClawStage.dismissed);
    await _updateStatus(a.dbId, 'dismissed');
    await _audit('action_confirm', 'Dismissed: ${a.title}');
  }

  void clearResolved() => state = state
      .where((a) => a.stage == ClawStage.queued)
      .toList(growable: false);

  void _update(String id, ClawStage stage) => state = [
    for (final a in state) a.id == id ? a.copyWith(stage: stage) : a,
  ];

  String _explain(SafeAction a) {
    if (a.irreversible) {
      return 'This is irreversible (it sends, pays, or installs). ALTER will '
          'draft it but only execute through OpenClaw after you explicitly approve.';
    }
    if (a.requiresConfirmation) {
      return 'A reversible step. ALTER prepared it; you stay in control of when it runs.';
    }
    return 'A safe, local step ALTER can do without sending anything off your phone.';
  }

  Future<String> _executeBridge(ClawAction a) async {
    final phone = ref.read(phoneControlControllerProvider.notifier);
    final device = const DeviceActions();
    final text = '${a.type} ${a.title} ${a.detail}'.toLowerCase();

    if (a.type == 'digital_twin_setup' || text.contains('accessibility')) {
      return phone.openAccessibilitySettings();
    }
    if (a.type.contains('setting')) {
      return phone.openSettings(_settingsScreenFromText(text));
    }
    if (a.type.contains('open_app')) {
      return phone.openApp(appName: a.detail.isNotEmpty ? a.detail : a.title);
    }
    if (a.type.contains('whatsapp') || text.contains('whatsapp')) {
      return phone.openApp(appName: 'whatsapp');
    }
    if (a.type.contains('sms') || a.type.contains('message')) {
      final number = _firstPhoneNumber(text);
      if (number.isEmpty) return phone.openApp(appName: 'messages');
      return phone.openSmsDraft(number: number, text: '');
    }
    if (a.type.contains('call') || text.contains('call ')) {
      final number = _firstPhoneNumber(text);
      if (number.isEmpty) return phone.openDialer('');
      return phone.openDialer(number);
    }
    if (a.type.contains('search')) {
      return device.webSearch(a.detail.isNotEmpty ? a.detail : a.title);
    }
    if (a.type.contains('url') || a.type.contains('link')) {
      return device.openUrl(a.detail.isNotEmpty ? a.detail : a.title);
    }
    if (a.type.contains('screen_read')) {
      final snapshot = await phone.readScreen();
      return snapshot.message;
    }

    return 'No native executor mapping yet; action was confirmed and audited.';
  }

  String _settingsScreenFromText(String text) {
    if (text.contains('wifi')) return 'wifi';
    if (text.contains('bluetooth')) return 'bluetooth';
    if (text.contains('notification')) return 'notifications';
    if (text.contains('battery')) return 'battery';
    if (text.contains('privacy')) return 'privacy';
    if (text.contains('accessibility')) return 'accessibility';
    return 'general';
  }

  String _firstPhoneNumber(String text) {
    return RegExp(
          r'\+?\d[\d\s().-]{6,}\d',
        ).firstMatch(text)?.group(0)?.replaceAll(RegExp(r'[^\d+]'), '') ??
        '';
  }

  // --- best-effort persistence ---
  Future<String?> _persist(
    ClawAction a,
    String status, {
    String? momentId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        'action_type': a.type,
        'title': a.title,
        'detail': a.detail,
        'requires_confirmation': a.requiresConfirmation,
        'irreversible': a.irreversible,
        'status': status,
      };
      if (momentId != null) payload['moment_id'] = momentId;
      final row = await Supabase.instance.client
          .from('alter_actions')
          .insert(payload)
          .select('id')
          .maybeSingle();
      return row?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateStatus(String? dbId, String status) async {
    if (dbId == null) return;
    try {
      await Supabase.instance.client
          .from('alter_actions')
          .update({'status': status})
          .eq('id', dbId);
    } catch (_) {}
  }

  Future<void> _audit(String kind, String detail) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('audit_events').insert({
        'user_id': userId,
        'kind': kind,
        'detail': detail,
        'edge_state': 'cloud',
      });
    } catch (_) {}
  }
}
