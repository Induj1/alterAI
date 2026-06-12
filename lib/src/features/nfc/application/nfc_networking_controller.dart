import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/nfc_networking_gateway.dart';
import '../domain/nfc_match.dart';
import '../domain/nfc_match_engine.dart';
import '../domain/nfc_profile.dart';

final localNfcProfileProvider = Provider<NfcProfile>((ref) {
  return NfcProfile(
    userId: 'alter-user-aria',
    displayName: 'Aria Shah',
    role: 'Founder',
    portfolioUrl: 'https://alter.ai/aria',
    resumeUrl: 'https://alter.ai/aria/resume',
    linkedinUrl: 'https://linkedin.com/in/ariashah',
    skills: const [
      'AI Product',
      'Flutter',
      'Growth',
      'Pitching',
      'Graph Systems',
    ],
    interests: const [
      'Future of work',
      'Agentic tools',
      'Founder communities',
      'NFC networking',
    ],
    goals: const [
      'Find design partners',
      'Build premium AI OS',
      'Launch founder beta',
    ],
    lookingFor: const [
      'Co-founder',
      'Pilot customers',
      'Hackathon team',
      'Investor intros',
    ],
    startupStage: 'Prototype',
    preferredHackathons: const ['AI Agents', 'Future of Work', 'DevTools'],
    location: 'Bengaluru',
    updatedAt: DateTime.utc(2026, 6, 11),
  );
});

final nfcNetworkingGatewayProvider = Provider<NfcNetworkingGateway>((ref) {
  return NfcManagerNetworkingGateway();
});

final nfcMatchEngineProvider = Provider<NfcMatchEngine>((ref) {
  return const NfcMatchEngine();
});

final nfcNetworkingControllerProvider =
    NotifierProvider<NfcNetworkingController, NfcNetworkingState>(
  NfcNetworkingController.new,
);

class NfcNetworkingController extends Notifier<NfcNetworkingState> {
  @override
  NfcNetworkingState build() {
    return NfcNetworkingState(
      localProfile: ref.watch(localNfcProfileProvider),
    );
  }

  Future<void> refreshAvailability() async {
    state = state.copyWith(
      phase: NfcNetworkingPhase.checking,
      errorMessage: '',
    );
    try {
      final availability =
          await ref.read(nfcNetworkingGatewayProvider).checkAvailability();
      state = state.copyWith(
        phase: availability == AlterNfcAvailability.enabled
            ? NfcNetworkingPhase.idle
            : NfcNetworkingPhase.unavailable,
        availability: availability,
      );
    } catch (error) {
      state = state.copyWith(
        phase: NfcNetworkingPhase.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> scanAndMatch() async {
    state = state.copyWith(
      phase: NfcNetworkingPhase.scanning,
      errorMessage: '',
    );
    try {
      final peer = await ref.read(nfcNetworkingGatewayProvider).scanProfile();
      final result = ref.read(nfcMatchEngineProvider).evaluate(
            localProfile: state.localProfile,
            peerProfile: peer,
          );
      state = state.copyWith(
        phase: NfcNetworkingPhase.matched,
        availability: AlterNfcAvailability.enabled,
        lastResult: result,
      );
    } catch (error) {
      state = state.copyWith(
        phase: NfcNetworkingPhase.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> shareProfile() async {
    state = state.copyWith(
      phase: NfcNetworkingPhase.writing,
      errorMessage: '',
    );
    try {
      await ref.read(nfcNetworkingGatewayProvider).writeProfile(state.localProfile);
      state = state.copyWith(
        phase: NfcNetworkingPhase.idle,
        availability: AlterNfcAvailability.enabled,
      );
    } catch (error) {
      state = state.copyWith(
        phase: NfcNetworkingPhase.error,
        errorMessage: error.toString(),
      );
    }
  }

  void previewMatch() {
    final result = ref.read(nfcMatchEngineProvider).evaluate(
          localProfile: state.localProfile,
          peerProfile: _previewPeer,
        );
    state = state.copyWith(
      phase: NfcNetworkingPhase.matched,
      lastResult: result,
      errorMessage: '',
    );
  }

  Future<void> stop() async {
    await ref.read(nfcNetworkingGatewayProvider).stop();
    state = state.copyWith(phase: NfcNetworkingPhase.idle);
  }
}

class NfcNetworkingState {
  const NfcNetworkingState({
    required this.localProfile,
    this.phase = NfcNetworkingPhase.idle,
    this.availability,
    this.lastResult,
    this.errorMessage = '',
  });

  final NfcProfile localProfile;
  final NfcNetworkingPhase phase;
  final AlterNfcAvailability? availability;
  final NfcExchangeResult? lastResult;
  final String errorMessage;

  bool get isBusy =>
      phase == NfcNetworkingPhase.checking ||
      phase == NfcNetworkingPhase.scanning ||
      phase == NfcNetworkingPhase.writing;

  NfcNetworkingState copyWith({
    NfcProfile? localProfile,
    NfcNetworkingPhase? phase,
    AlterNfcAvailability? availability,
    NfcExchangeResult? lastResult,
    String? errorMessage,
  }) {
    return NfcNetworkingState(
      localProfile: localProfile ?? this.localProfile,
      phase: phase ?? this.phase,
      availability: availability ?? this.availability,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum NfcNetworkingPhase {
  idle,
  checking,
  scanning,
  writing,
  matched,
  unavailable,
  error,
}

final _previewPeer = NfcProfile(
  userId: 'alter-peer-maya',
  displayName: 'Maya Chen',
  role: 'Investor',
  portfolioUrl: 'https://maya.vc',
  resumeUrl: 'https://maya.vc/bio',
  linkedinUrl: 'https://linkedin.com/in/mayachen',
  skills: const [
    'AI Product',
    'Fundraising',
    'Founder Coaching',
    'Marketplaces',
    'Growth',
  ],
  interests: const [
    'Agentic tools',
    'Founder communities',
    'Future of work',
    'DevTools',
  ],
  goals: const [
    'Meet AI founders',
    'Source design partners',
    'Invest in future of work',
  ],
  lookingFor: const [
    'Investor intros',
    'Pilot customers',
    'Startup demos',
  ],
  startupStage: 'Prototype',
  preferredHackathons: const ['AI Agents', 'DevTools'],
  location: 'Bengaluru',
  updatedAt: DateTime.utc(2026, 6, 11),
);
