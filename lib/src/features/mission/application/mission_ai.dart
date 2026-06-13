import 'dart:convert';

import '../../../services/openai_service.dart';
import '../../profile/domain/user_profile.dart';
import '../data/mission_control_api_client.dart';

/// Generates Mission Control intelligence by prompting OpenAI (through the
/// secure Edge Function) and parsing the result with the existing model
/// `fromJson` constructors. Replaces the dead FastAPI gateway calls.
///
/// All parsers are defensive (missing fields → empty/zero), so prompts focus on
/// the fields the UI renders; anything the model omits degrades gracefully.
class MissionAi {
  MissionAi(this._openai, this._profile);

  final OpenAIService _openai;
  final UserProfile? _profile;

  String get _profileBlock {
    final p = _profile;
    if (p == null || p.displayName.isEmpty) {
      return 'The operator has not filled in a profile yet. Make reasonable, '
          'ambitious assumptions for a driven early-career builder.';
    }
    final parts = <String>[
      'Name: ${p.displayName}',
      if (p.role.isNotEmpty) 'Role: ${p.role}',
      if (p.careerStage.isNotEmpty) 'Career stage: ${p.careerStage}',
      if (p.industry.isNotEmpty) 'Industry: ${p.industry}',
      if (p.skills.isNotEmpty) 'Skills: ${p.skills.join(', ')}',
      if (p.goals.isNotEmpty) 'Goals: ${p.goals.join(', ')}',
      if (p.interests.isNotEmpty) 'Interests: ${p.interests.join(', ')}',
    ];
    return parts.join('\n');
  }

  Future<Map<String, dynamic>> _json(String system, String user) async {
    final raw = await _openai.chat(
      jsonMode: true,
      temperature: 0.55,
      maxTokens: 1800,
      messages: [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    );
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*\n?'), '');
      if (s.endsWith('```')) s = s.substring(0, s.length - 3);
    }
    return jsonDecode(s.trim()) as Map<String, dynamic>;
  }

  // --- 1. Future-OS demo ---------------------------------------------------
  Future<MissionDemoRun> runDemo(String objective) async {
    final json = await _json(
      'You are ALTER Mission Control. Simulate running an end-to-end personal '
      'AI operating system against the operator\'s objective. Respond with ONLY '
      'a JSON object (no markdown) using this schema:\n'
      '{\n'
      '  "headline": string,\n'
      '  "executive_summary": string,\n'
      '  "steps": [ {"name": string, "title": string, "status": "ok", "summary": string, "latency_ms": number} ],\n'
      '  "key_metrics": { "Readiness": string, "Signal": string, "Trust": string },\n'
      '  "next_actions": [string],\n'
      '  "risks": [string],\n'
      '  "opportunities": [string]\n'
      '}\n'
      'Provide 4-6 realistic pipeline steps (voice capture, vision, council, '
      'radar, social graph, reputation). Be concrete and specific.\n\n'
      'OPERATOR PROFILE:\n$_profileBlock',
      'Objective: $objective',
    );
    return MissionDemoRun.fromJson(json);
  }

  // --- 2. Intelligence Kernel decision ------------------------------------
  Future<IntelligenceDecisionReport> decide(String question) async {
    final json = await _json(
      'You are ALTER\'s Intelligence Kernel — a rigorous decision strategist. '
      'Reason through the operator\'s decision over a 36-month horizon and '
      'respond with ONLY JSON (no markdown) using this schema:\n'
      '{\n'
      '  "question": string,\n'
      '  "recommendation": string,            // the clear call to make\n'
      '  "confidence_score": number,          // 0..1\n'
      '  "decision_summary": string,          // 2-3 sentences of reasoning\n'
      '  "recommended_future": string,        // the future this unlocks\n'
      '  "experiment_plan": {"experiment_id": string, "action": string, "why_it_matters": string, "deadline": string, "success_metric": string},\n'
      '  "future_options": [ {"future_id": string, "name": string, "thesis": string, "success_probability": number, "opportunity_score": number, "risk_score": number} ],\n'
      '  "memory_context": [string],          // relevant facts considered\n'
      '  "opportunity_matches": [string],\n'
      '  "next_actions": [string],\n'
      '  "risks": [string],\n'
      '  "opportunities": [string],\n'
      '  "signals": [ {"name": string, "title": string, "status": "ok", "summary": string, "latency_ms": number} ]\n'
      '}\n'
      'Provide 2-3 future_options with probabilities/scores in 0..1, a concrete '
      'experiment_plan, and 3-4 next_actions.\n\nOPERATOR PROFILE:\n$_profileBlock',
      'Decision question: $question',
    );
    return IntelligenceDecisionReport.fromJson(json);
  }

  // --- 3. Record outcome of a prior decision ------------------------------
  Future<OutcomeUpdateResult> recordOutcome({
    required IntelligenceDecisionReport report,
    required bool didIt,
    required String whatHappened,
    required String whatLearned,
    required String successMetricResult,
    required double outcomeScore,
  }) async {
    final json = await _json(
      'You are ALTER\'s execution coach. The operator reports the outcome of a '
      'committed experiment. Score their follow-through and update their trust '
      'trajectory. Respond with ONLY JSON (no markdown) using this schema:\n'
      '{\n'
      '  "execution_score": number,           // 0..1\n'
      '  "confidence_delta": number,          // -1..1\n'
      '  "trust_level": string,               // e.g. "Rising", "High trust"\n'
      '  "reputation_score": number,          // integer ~600-950\n'
      '  "profile_updates": [string],\n'
      '  "next_recommendation": string,\n'
      '  "memory_summary": string,\n'
      '  "signals": [ {"name": string, "title": string, "status": "ok", "summary": string, "latency_ms": number} ]\n'
      '}\n\nOPERATOR PROFILE:\n$_profileBlock',
      'Original decision: ${report.question}\n'
      'Committed experiment: ${report.experimentPlan.action}\n'
      'Success metric: ${report.experimentPlan.successMetric}\n'
      'Did they do it: $didIt\n'
      'What happened: $whatHappened\n'
      'What they learned: $whatLearned\n'
      'Success metric result: $successMetricResult\n'
      'Self-rated outcome (0..1): $outcomeScore',
    );
    return OutcomeUpdateResult.fromJson(json);
  }

  // --- 4. Future Twin ------------------------------------------------------
  Future<FutureTwinResult> buildTwin({
    required String objective,
    required List<FutureTwinEvidenceInput> evidence,
  }) async {
    final evidenceText = evidence.isEmpty
        ? 'No recent evidence provided.'
        : evidence
            .map((e) => '- [${e.evidenceType}] ${e.title}: ${e.summary}')
            .join('\n');
    final json = await _json(
      'You are ALTER\'s Future Twin engine. Model the operator\'s 90-day '
      'trajectory toward their objective and compile the single highest-leverage '
      'action. Respond with ONLY JSON (no markdown) using this schema:\n'
      '{\n'
      '  "objective": string,\n'
      '  "identity_summary": string,          // who they are becoming\n'
      '  "daily_question": string,            // the one question to ask daily\n'
      '  "confidence_score": number,          // 0..1\n'
      '  "trajectory": {"current_trajectory": string, "predicted_90_day_future": string, "best_alternative_future": string, "alignment_score": number, "execution_velocity": number, "drift_risk": number, "points": [ {"label": string, "current_score": number, "predicted_score": number, "best_case_score": number} ]},\n'
      '  "action": {"action_id": string, "title": string, "why_now": string, "deadline": string, "success_metric": string, "proof_required": [string], "first_step": string, "leverage_score": number},\n'
      '  "future_options": [ {"future_id": string, "name": string, "thesis": string, "success_probability": number, "opportunity_score": number, "risk_score": number} ],\n'
      '  "opportunity_arbitrage": [ {"title": string, "leverage_score": number, "why_this_matters": string, "stack": [string], "first_step": string, "opportunity_refs": [string]} ],\n'
      '  "model_updates": [string],\n'
      '  "signals": [ {"name": string, "title": string, "status": "ok", "summary": string, "latency_ms": number} ]\n'
      '}\n'
      'Provide 3-5 trajectory points (e.g. Day 0, 30, 60, 90), scores in 0..1.\n\n'
      'OPERATOR PROFILE:\n$_profileBlock',
      'Objective: $objective\n\nRecent evidence:\n$evidenceText',
    );
    return FutureTwinResult.fromJson(json);
  }

  // --- 5. Proof capture ----------------------------------------------------
  Future<ProofCaptureResult> captureProof({
    required String objective,
    required String linkedGoal,
    required String linkedAction,
    required List<ProofEvidenceInput> evidence,
  }) async {
    final evidenceText = evidence
        .map((e) => '- [${e.evidenceType}] ${e.title}: ${e.summary} '
            '(source: ${e.source})')
        .join('\n');
    final json = await _json(
      'You are ALTER\'s Proof Engine. The operator submits evidence that they '
      'executed on a goal. Turn it into a trust-building record, a small memory '
      'graph, and a daily briefing. Respond with ONLY JSON (no markdown) using '
      'this schema:\n'
      '{\n'
      '  "objective": string,\n'
      '  "evidence_records": [ {"evidence_id": string, "evidence_type": string, "title": string, "summary": string, "source": string, "linked_goal": string, "linked_action": string, "impact_score": number, "confidence": number, "trajectory_effect": string} ],\n'
      '  "graph_nodes": [ {"node_id": string, "label": string, "kind": string, "score": number, "status": "active"} ],\n'
      '  "graph_edges": [ {"from_node": string, "to_node": string, "label": string, "strength": number} ],\n'
      '  "daily_briefing": {"morning_question": string, "evening_question": string, "recommended_proof": string, "drift_alert": string, "push_notifications": [string]},\n'
      '  "trust_profile": {"execution_streak": number, "follow_through_score": number, "trust_level": string, "strengths": [string], "risks": [string]},\n'
      '  "future_twin_delta": {"alignment_delta": number, "execution_delta": number, "drift_delta": number, "summary": string, "recommended_recalibration": string},\n'
      '  "next_actions": [string],\n'
      '  "signals": [ {"name": string, "title": string, "status": "ok", "summary": string, "latency_ms": number} ]\n'
      '}\n'
      'Build graph nodes/edges that connect the goal, action, and evidence. '
      'Scores in 0..1.\n\nOPERATOR PROFILE:\n$_profileBlock',
      'Objective: $objective\nLinked goal: $linkedGoal\n'
      'Linked action: $linkedAction\n\nEvidence:\n$evidenceText',
    );
    return ProofCaptureResult.fromJson(json);
  }
}
