import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlterAppState {
  const AlterAppState({
    required this.onboardingComplete,
    required this.themeMode,
    required this.voiceListening,
    required this.selectedLanguage,
    required this.cameraMode,
    required this.privacyShield,
    required this.proactiveBriefs,
  });

  factory AlterAppState.initial() {
    return const AlterAppState(
      onboardingComplete: false,
      themeMode: ThemeMode.system,
      voiceListening: false,
      selectedLanguage: 'English',
      cameraMode: 'Context',
      privacyShield: true,
      proactiveBriefs: true,
    );
  }

  final bool onboardingComplete;
  final ThemeMode themeMode;
  final bool voiceListening;
  final String selectedLanguage;
  final String cameraMode;
  final bool privacyShield;
  final bool proactiveBriefs;

  AlterAppState copyWith({
    bool? onboardingComplete,
    ThemeMode? themeMode,
    bool? voiceListening,
    String? selectedLanguage,
    String? cameraMode,
    bool? privacyShield,
    bool? proactiveBriefs,
  }) {
    return AlterAppState(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      themeMode: themeMode ?? this.themeMode,
      voiceListening: voiceListening ?? this.voiceListening,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      cameraMode: cameraMode ?? this.cameraMode,
      privacyShield: privacyShield ?? this.privacyShield,
      proactiveBriefs: proactiveBriefs ?? this.proactiveBriefs,
    );
  }
}

class AlterAppController extends Notifier<AlterAppState> {
  @override
  AlterAppState build() => AlterAppState.initial();

  void completeOnboarding() {
    state = state.copyWith(onboardingComplete: true);
  }

  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }

  void toggleListening() {
    state = state.copyWith(voiceListening: !state.voiceListening);
  }

  void setVoiceListening(bool value) {
    state = state.copyWith(voiceListening: value);
  }

  void setLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
  }

  void setCameraMode(String mode) {
    state = state.copyWith(cameraMode: mode);
  }

  void setPrivacyShield(bool value) {
    state = state.copyWith(privacyShield: value);
  }

  void setProactiveBriefs(bool value) {
    state = state.copyWith(proactiveBriefs: value);
  }
}

final alterAppControllerProvider =
    NotifierProvider<AlterAppController, AlterAppState>(AlterAppController.new);
