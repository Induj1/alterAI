import 'package:alter/src/features/mission/data/mission_control_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MissionDemoRun parses gateway judge-mode response', () {
    final run = MissionDemoRun.fromJson(const <String, dynamic>{
      'headline': 'ALTER ran 9/9 systems.',
      'executive_summary': 'A full future operating loop completed.',
      'key_metrics': <String, dynamic>{
        'systems': '9/9',
        'futures': '3',
        'council': '81%',
      },
      'next_actions': <String>['Run a validation sprint.'],
      'risks': <String>['Momentum can hide weak evidence.'],
      'opportunities': <String>['Create a public proof point.'],
      'steps': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'clone_council',
          'title': 'Clone Council Debate',
          'status': 'ok',
          'summary': '7-agent debate completed.',
          'latency_ms': 42,
        },
      ],
    });

    expect(run.headline, contains('9/9'));
    expect(run.keyMetrics['council'], '81%');
    expect(run.steps.single.isHealthy, isTrue);
    expect(run.nextActions.single, contains('validation'));
  });

  test('IntelligenceDecisionReport parses gateway kernel response', () {
    final report = IntelligenceDecisionReport.fromJson(const <String, dynamic>{
      'question': 'Should I build ALTER into a startup?',
      'recommendation': 'Run a two-week evidence sprint.',
      'confidence_score': 0.82,
      'decision_summary': 'ALTER evaluated the decision through live systems.',
      'recommended_future': 'Future B',
      'experiment_plan': <String, dynamic>{
        'experiment_id': '22222222-2222-4222-8222-222222222222',
        'action': 'Interview ten target users.',
        'why_it_matters': 'This tests whether the startup path has real demand.',
        'deadline': '2026-06-19',
        'success_metric': 'Ten conversations and three beta requests.',
      },
      'future_options': <Map<String, dynamic>>[
        <String, dynamic>{
          'future_id': 'Future B',
          'name': 'Founder path',
          'thesis': 'Validate demand and compound distribution.',
          'success_probability': 0.74,
          'opportunity_score': 88,
          'risk_score': 41,
        },
      ],
      'memory_context': <String>['Goal: build a serious AI product.'],
      'opportunity_matches': <String>['Startup grant (86.4)'],
      'next_actions': <String>['Interview ten target users.'],
      'risks': <String>['False confidence from demo excitement.'],
      'opportunities': <String>['Convert traction into a public proof point.'],
      'signals': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'clone_council',
          'title': 'Clone Council Deliberation',
          'status': 'ok',
          'summary': 'Council confidence is 82%.',
          'latency_ms': 120,
        },
      ],
      'created_memory_id': '11111111-1111-4111-8111-111111111111',
    });

    expect(report.confidenceScore, 0.82);
    expect(report.experimentPlan.action, contains('Interview'));
    expect(report.futureOptions.single.futureId, 'Future B');
    expect(report.signals.single.isHealthy, isTrue);
    expect(report.memorySaved, isTrue);
  });

  test('OutcomeUpdateResult parses execution learning response', () {
    final result = OutcomeUpdateResult.fromJson(const <String, dynamic>{
      'execution_score': 86.5,
      'confidence_delta': 0.11,
      'memory_id': '33333333-3333-4333-8333-333333333333',
      'reputation_event_id': '44444444-4444-4444-8444-444444444444',
      'reputation_score': 652,
      'trust_level': 'strong',
      'profile_updates': <String>[
        'Execution reliability signal: 86.5/100.',
      ],
      'next_recommendation': 'Double down for one more sprint.',
      'memory_summary': 'Experiment completed.',
      'signals': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'outcome_memory',
          'title': 'Outcome Memory Writeback',
          'status': 'ok',
          'summary': 'Saved outcome memory.',
        },
      ],
    });

    expect(result.executionScore, 86.5);
    expect(result.confidenceDelta, 0.11);
    expect(result.memorySaved, isTrue);
    expect(result.reputationLogged, isTrue);
    expect(result.signals.single.isHealthy, isTrue);
  });

  test('FutureTwinResult parses trajectory, evidence, and arbitrage', () {
    final result = FutureTwinResult.fromJson(const <String, dynamic>{
      'twin_id': 'twin-1',
      'user_id': 'user-1',
      'objective': 'Build ALTER',
      'identity_summary': 'Evidence-compounding founder path.',
      'daily_question': 'What proof did you create today?',
      'trajectory': <String, dynamic>{
        'current_trajectory': 'Promising but proof-constrained path',
        'predicted_90_day_future': 'More proof and sharper demand.',
        'best_alternative_future': 'Founder path',
        'alignment_score': 78,
        'execution_velocity': 71,
        'drift_risk': 29,
        'points': <Map<String, dynamic>>[
          <String, dynamic>{
            'label': 'Execution',
            'current_score': 60,
            'predicted_score': 78,
            'best_case_score': 94,
          },
        ],
      },
      'action': <String, dynamic>{
        'action_id': 'action-1',
        'title': 'Talk to 5 users',
        'why_now': 'This creates proof.',
        'deadline': '2026-06-19',
        'success_metric': '5 interviews complete',
        'proof_required': <String>['Notes', 'Artifact'],
        'first_step': 'Message 3 target users',
        'leverage_score': 86,
      },
      'future_options': <Map<String, dynamic>>[
        <String, dynamic>{
          'future_id': 'future_a',
          'name': 'Founder path',
          'thesis': 'Build the company.',
          'success_probability': 0.74,
          'opportunity_score': 88,
          'risk_score': 42,
        },
      ],
      'evidence_signals': <Map<String, dynamic>>[
        <String, dynamic>{
          'evidence_id': 'evidence-1',
          'evidence_type': 'project',
          'title': 'Working prototype',
          'source': 'mission_control',
          'impact_score': 84,
          'confidence': 0.9,
          'memory_id': 'memory-1',
          'summary': 'ALTER is running end to end.',
        },
      ],
      'opportunity_arbitrage': <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Validation arbitrage',
          'leverage_score': 91,
          'why_this_matters': 'Proof changes the curve.',
          'stack': <String>['Users', 'Prototype'],
          'first_step': 'Run interviews',
          'opportunity_refs': <String>['Devpost'],
        },
      ],
      'model_updates': <String>['Increase proof weighting.'],
      'confidence_score': 0.82,
      'decision_report': <String, dynamic>{
        'decision_id': 'decision-1',
        'user_id': 'user-1',
        'question': 'Build ALTER?',
        'recommendation': 'Run validation.',
        'confidence_score': 0.82,
        'decision_summary': 'Decision made.',
        'recommended_future': 'future_a',
        'experiment_plan': <String, dynamic>{
          'experiment_id': 'experiment-1',
          'action': 'Talk to 5 users',
          'why_it_matters': 'Validate demand.',
          'deadline': '2026-06-19',
          'success_metric': '5 interviews complete',
        },
        'future_options': <Map<String, dynamic>>[],
        'memory_context': <String>[],
        'opportunity_matches': <String>[],
        'next_actions': <String>[],
        'risks': <String>[],
        'opportunities': <String>[],
        'signals': <Map<String, dynamic>>[],
      },
      'signals': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'future_twin',
          'title': 'Future Twin',
          'status': 'ok',
          'summary': 'Ready.',
          'latency_ms': 42,
        },
      ],
      'created_memory_id': 'memory-2',
    });

    expect(result.trajectory.alignmentScore, 78);
    expect(result.action.proofRequired.length, 2);
    expect(result.evidenceSignals.first.memorySaved, isTrue);
    expect(result.opportunityArbitrage.first.stack, contains('Users'));
    expect(result.memorySaved, isTrue);
  });
}
