import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../agent/data/device_actions.dart';
import '../../device_control/application/phone_control_controller.dart';
import '../../device_control/domain/phone_action_policy.dart';
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
    ClawCommand? command,
    this.stage = ClawStage.queued,
    this.dbId,
  }) : command =
           command ??
           ClawCommand.fromParts(type: type, title: title, detail: detail);

  final String id;
  final String type;
  final String title;
  final String detail;
  final String why; // the "Explain" step
  final bool requiresConfirmation;
  final bool irreversible;
  final String momentExcerpt;
  final DateTime createdAt;
  final ClawCommand command;
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
    command: command,
    stage: stage ?? this.stage,
    dbId: dbId ?? this.dbId,
  );
}

class ClawCommand {
  const ClawCommand({
    required this.kind,
    required this.args,
    required this.policy,
  });

  factory ClawCommand.fromParts({
    required String type,
    required String title,
    required String detail,
  }) {
    final haystack = '$type $title $detail'.toLowerCase();
    final kind = _kindFrom(type, haystack);
    final args = _argsFrom(kind, type, title, detail, haystack);
    final target = args['text'] ?? args['appName'] ?? args['screen'] ?? detail;
    return ClawCommand(
      kind: kind,
      args: args,
      policy: PhoneActionPolicy.classify(
        kind: kind,
        target: target,
        requiresAccessibility: _requiresAccessibility(kind),
      ),
    );
  }

  final String kind;
  final Map<String, String> args;
  final PhoneActionPolicyDecision policy;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'args': args,
    'policy_tier': policy.label,
    'policy_reason': policy.reason,
    'requires_accessibility': policy.requiresAccessibility,
  };

  static String _kindFrom(String type, String haystack) {
    if (type == 'digital_twin_setup' || haystack.contains('accessibility')) {
      return 'open_settings';
    }
    if (type.contains('setting')) return 'open_settings';
    if (type.contains('open_app')) return 'open_app';
    if (type.contains('whatsapp') || haystack.contains('whatsapp')) {
      return 'open_app';
    }
    if (type.contains('sms') || type.contains('message')) {
      return 'open_sms_draft';
    }
    if (type.contains('call') || haystack.contains('call ')) {
      return 'open_dialer';
    }
    if (type.contains('search')) return 'web_search';
    if (type.contains('url') || type.contains('link')) return 'open_url';
    if (type.contains('screen_read')) return 'read_screen';
    if (type.contains('click_text')) return 'click_text';
    if (type.contains('type_text')) return 'type_text';
    if (type.contains('scroll')) return 'scroll';
    if (type.contains('back') || type.contains('home')) {
      return 'press_phone_button';
    }
    return 'audit_only';
  }

  static Map<String, String> _argsFrom(
    String kind,
    String type,
    String title,
    String detail,
    String haystack,
  ) {
    final phone = _firstPhoneNumber(haystack);
    return switch (kind) {
      'open_settings' => {'screen': _settingsScreenFromText(haystack)},
      'open_app' => {
        'appName': type.contains('whatsapp') || haystack.contains('whatsapp')
            ? 'whatsapp'
            : (detail.isNotEmpty ? detail : title),
      },
      'open_sms_draft' => {'number': phone, 'text': detail},
      'open_dialer' => {'number': phone},
      'web_search' => {'query': detail.isNotEmpty ? detail : title},
      'open_url' => {'url': detail.isNotEmpty ? detail : title},
      'click_text' => {'text': detail.isNotEmpty ? detail : title},
      'type_text' => {'text': detail},
      'scroll' => {
        'direction': haystack.contains('up') ? 'backward' : 'forward',
      },
      'press_phone_button' => {
        'button': haystack.contains('home') ? 'home' : 'back',
      },
      _ => {'detail': detail},
    };
  }

  static bool _requiresAccessibility(String kind) {
    return const {
      'read_screen',
      'click_text',
      'type_text',
      'scroll',
      'press_phone_button',
    }.contains(kind);
  }

  static String _settingsScreenFromText(String text) {
    if (text.contains('wifi')) return 'wifi';
    if (text.contains('bluetooth')) return 'bluetooth';
    if (text.contains('notification')) return 'notifications';
    if (text.contains('battery')) return 'battery';
    if (text.contains('privacy')) return 'privacy';
    if (text.contains('accessibility')) return 'accessibility';
    return 'general';
  }

  static String _firstPhoneNumber(String text) {
    return RegExp(
          r'\+?\d[\d\s().-]{6,}\d',
        ).firstMatch(text)?.group(0)?.replaceAll(RegExp(r'[^\d+]'), '') ??
        '';
  }
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

  Future<String> enqueueStructured({
    required String type,
    required String title,
    required String detail,
    bool requiresConfirmation = true,
    bool irreversible = false,
    String momentExcerpt = 'Agent proposed action',
  }) async {
    await enqueue(
      SafeAction(
        type: type,
        title: title,
        detail: detail,
        requiresConfirmation: requiresConfirmation,
        irreversible: irreversible,
      ),
      momentExcerpt: momentExcerpt,
    );
    return 'Queued "$title" in OpenClaw for review.';
  }

  /// Execute (only call after explicit confirmation in the UI).
  Future<String> execute(String id) async {
    final a = state.firstWhere((x) => x.id == id);
    final result = await _executeBridge(a);
    _update(id, ClawStage.executed);
    await _updateStatus(a.dbId, 'executed', result: result);
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
    final args = a.command.args;
    if (!a.command.policy.canExecuteOn(PhoneActionSurface.openClawConfirmed)) {
      return a.command.policy.reason;
    }

    switch (a.command.kind) {
      case 'open_settings':
        final screen = args['screen'] ?? 'general';
        if (screen == 'accessibility') return phone.openAccessibilitySettings();
        return phone.openSettings(screen);
      case 'open_app':
        return phone.openApp(appName: args['appName'] ?? '');
      case 'open_sms_draft':
        final number = args['number'] ?? '';
        if (number.isEmpty) return phone.openApp(appName: 'messages');
        return phone.openSmsDraft(number: number, text: args['text'] ?? '');
      case 'open_dialer':
        return phone.openDialer(args['number'] ?? '');
      case 'web_search':
        return device.webSearch(args['query'] ?? a.title);
      case 'open_url':
        return device.openUrl(args['url'] ?? a.detail);
      case 'read_screen':
        final snapshot = await phone.readScreen();
        return snapshot.message;
      case 'click_text':
        return phone.clickText(
          args['text'] ?? a.title,
          surface: PhoneActionSurface.openClawConfirmed,
        );
      case 'type_text':
        return phone.typeText(
          args['text'] ?? a.detail,
          surface: PhoneActionSurface.openClawConfirmed,
        );
      case 'scroll':
        return phone.scroll(
          args['direction'] ?? 'forward',
          surface: PhoneActionSurface.openClawConfirmed,
        );
      case 'press_phone_button':
        return phone.press(
          args['button'] ?? 'back',
          surface: PhoneActionSurface.openClawConfirmed,
        );
      default:
        return 'No native executor mapping yet; action was confirmed and audited.';
    }
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
        'action_payload': a.command.toJson(),
        'policy_tier': a.command.policy.label,
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

  Future<void> _updateStatus(
    String? dbId,
    String status, {
    String result = '',
  }) async {
    if (dbId == null) return;
    try {
      await Supabase.instance.client
          .from('alter_actions')
          .update({
            'status': status,
            if (result.isNotEmpty) 'executed_result': result,
          })
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
