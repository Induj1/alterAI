import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_control_bridge.dart';

final deviceControlBridgeProvider = Provider<DeviceControlBridge>((ref) {
  return DeviceControlBridge();
});

final phoneControlControllerProvider =
    NotifierProvider<PhoneControlController, PhoneControlState>(
      PhoneControlController.new,
    );

class PhoneControlController extends Notifier<PhoneControlState> {
  @override
  PhoneControlState build() {
    Future.microtask(refresh);
    return const PhoneControlState();
  }

  Future<void> refresh() async {
    final enabled = await ref
        .read(deviceControlBridgeProvider)
        .isAccessibilityEnabled();
    state = state.copyWith(accessibilityEnabled: enabled, error: '');
  }

  Future<String> openAccessibilitySettings() async {
    final result = await ref
        .read(deviceControlBridgeProvider)
        .openAccessibilitySettings();
    _audit(
      kind: 'permission',
      target: 'accessibility_settings',
      message: result.message,
      ok: result.ok,
      requiresAccessibility: false,
    );
    return result.message;
  }

  Future<String> openApp({String appName = '', String packageName = ''}) async {
    final result = await ref
        .read(deviceControlBridgeProvider)
        .openApp(appName: appName, packageName: packageName);
    _audit(
      kind: 'open_app',
      target: packageName.isNotEmpty ? packageName : appName,
      message: result.message,
      ok: result.ok,
      requiresAccessibility: false,
    );
    return result.message;
  }

  Future<String> openSettings(String screen) async {
    final result = await ref
        .read(deviceControlBridgeProvider)
        .openSettings(screen);
    _audit(
      kind: 'open_settings',
      target: screen,
      message: result.message,
      ok: result.ok,
      requiresAccessibility: false,
    );
    return result.message;
  }

  Future<String> openDialer(String number) async {
    final result = await ref
        .read(deviceControlBridgeProvider)
        .openDialer(number);
    _audit(
      kind: 'open_dialer',
      target: number,
      message: result.message,
      ok: result.ok,
      requiresAccessibility: false,
    );
    return result.message;
  }

  Future<String> openSmsDraft({
    required String number,
    required String text,
  }) async {
    final result = await ref
        .read(deviceControlBridgeProvider)
        .openSmsDraft(number: number, text: text);
    _audit(
      kind: 'open_sms_draft',
      target: number,
      message: result.message,
      ok: result.ok,
      requiresAccessibility: false,
    );
    return result.message;
  }

  Future<String> press(String action) async {
    final result = await ref
        .read(deviceControlBridgeProvider)
        .globalAction(action);
    await refresh();
    _audit(
      kind: 'accessibility_action',
      target: action,
      message: result.message,
      ok: result.ok,
      requiresAccessibility: true,
    );
    return result.message;
  }

  Future<String> clickText(String text) async {
    final result = await ref.read(deviceControlBridgeProvider).clickText(text);
    await refresh();
    _audit(
      kind: 'click_text',
      target: text,
      message: result.message,
      ok: result.ok,
      requiresAccessibility: true,
    );
    return result.message;
  }

  Future<String> typeText(String text) async {
    final result = await ref.read(deviceControlBridgeProvider).typeText(text);
    await refresh();
    _audit(
      kind: 'type_text',
      target: _redact(text),
      message: result.message,
      ok: result.ok,
      requiresAccessibility: true,
    );
    return result.message;
  }

  Future<String> scroll(String direction) async {
    final result = await ref
        .read(deviceControlBridgeProvider)
        .scroll(direction);
    await refresh();
    _audit(
      kind: 'scroll',
      target: direction,
      message: result.message,
      ok: result.ok,
      requiresAccessibility: true,
    );
    return result.message;
  }

  Future<String> tap({required double x, required double y}) async {
    final result = await ref.read(deviceControlBridgeProvider).tap(x: x, y: y);
    await refresh();
    _audit(
      kind: 'tap',
      target: '${x.round()},${y.round()}',
      message: result.message,
      ok: result.ok,
      requiresAccessibility: true,
    );
    return result.message;
  }

  Future<DeviceScreenSnapshot> readScreen() async {
    final snapshot = await ref.read(deviceControlBridgeProvider).readScreen();
    await refresh();
    state = state.copyWith(lastSnapshot: snapshot);
    _audit(
      kind: 'read_screen',
      target: snapshot.packageName,
      message: snapshot.message,
      ok: snapshot.ok,
      requiresAccessibility: true,
    );
    return snapshot;
  }

  void clearAudit() => state = state.copyWith(audit: const []);

  void _audit({
    required String kind,
    required String target,
    required String message,
    required bool ok,
    required bool requiresAccessibility,
  }) {
    final entry = PhoneControlAuditEntry(
      kind: kind,
      target: target,
      message: message,
      ok: ok,
      requiresAccessibility: requiresAccessibility,
      at: DateTime.now(),
    );
    final next = [entry, ...state.audit].take(80).toList(growable: false);
    state = state.copyWith(audit: next, error: ok ? '' : message);
  }

  String _redact(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 8) return 'text:${trimmed.length} chars';
    return 'text:${trimmed.length} chars:${trimmed.substring(0, 4)}...';
  }
}

class PhoneControlState {
  const PhoneControlState({
    this.accessibilityEnabled = false,
    this.audit = const [],
    this.lastSnapshot,
    this.error = '',
  });

  final bool accessibilityEnabled;
  final List<PhoneControlAuditEntry> audit;
  final DeviceScreenSnapshot? lastSnapshot;
  final String error;

  PhoneControlState copyWith({
    bool? accessibilityEnabled,
    List<PhoneControlAuditEntry>? audit,
    DeviceScreenSnapshot? lastSnapshot,
    String? error,
  }) {
    return PhoneControlState(
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      audit: audit ?? this.audit,
      lastSnapshot: lastSnapshot ?? this.lastSnapshot,
      error: error ?? this.error,
    );
  }
}

class PhoneControlAuditEntry {
  const PhoneControlAuditEntry({
    required this.kind,
    required this.target,
    required this.message,
    required this.ok,
    required this.requiresAccessibility,
    required this.at,
  });

  final String kind;
  final String target;
  final String message;
  final bool ok;
  final bool requiresAccessibility;
  final DateTime at;
}
