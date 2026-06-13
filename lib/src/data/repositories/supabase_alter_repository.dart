import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/alter_palette.dart';
import '../../domain/entities/alter_models.dart';
import '../../domain/repositories/alter_repository.dart';

class SupabaseAlterRepository implements AlterRepository {
  SupabaseAlterRepository(this._client);
  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  // ── Assistant Brief ───────────────────────────────────────────────────────

  @override
  Future<AssistantBrief> loadAssistantBrief() async {
    final rows = await _client
        .from('assistant_briefs')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return _seedBrief();
    }
    final r = rows.first;
    return AssistantBrief(
      greeting: r['greeting'] as String,
      focus: r['focus'] as String,
      nextAction: r['next_action'] as String,
      signals: List<String>.from(r['signals'] as List),
    );
  }

  Future<AssistantBrief> _seedBrief() async {
    const brief = AssistantBrief(
      greeting: 'Welcome to ALTER.',
      focus: 'Set up your first goal and let the intelligence kernel guide you.',
      nextAction: 'Ask the Growth Clone to draft a launch map.',
      signals: [
        'Your profile is ready',
        'Connect your first contact',
        'Explore Opportunity Radar',
      ],
    );
    await _client.from('assistant_briefs').insert({
      'user_id': _uid,
      'greeting': brief.greeting,
      'focus': brief.focus,
      'next_action': brief.nextAction,
      'signals': brief.signals,
    });
    return brief;
  }

  // ── Clone Council ─────────────────────────────────────────────────────────

  @override
  Future<List<CloneAgent>> loadCloneCouncil() async {
    final rows = await _client
        .from('clone_agents')
        .select()
        .eq('user_id', _uid)
        .order('created_at');

    if (rows.isEmpty) return _seedCloneAgents();

    return rows.map((r) {
      return CloneAgent(
        name: r['name'] as String,
        role: r['role'] as String,
        state: r['state'] as String,
        confidence: (r['confidence'] as num).toDouble(),
        accent: Color(int.parse(r['accent_hex'] as String)),
        summary: r['summary'] as String,
      );
    }).toList();
  }

  Future<List<CloneAgent>> _seedCloneAgents() async {
    const agents = [
      (
        name: 'Strategist',
        role: 'Market timing and positioning',
        state: 'Synthesizing',
        confidence: 0.88,
        accent: AlterPalette.iris,
        summary: 'Recommends narrowing the beta to investor-backed founders.',
      ),
      (
        name: 'Operator',
        role: 'Execution plan and constraints',
        state: 'Ready',
        confidence: 0.82,
        accent: AlterPalette.cyan,
        summary: 'Flags onboarding friction as the highest execution risk.',
      ),
      (
        name: 'Contrarian',
        role: 'Risk, second-order effects',
        state: 'Challenging',
        confidence: 0.76,
        accent: AlterPalette.aura,
        summary: 'Pushes for one paid pilot before broad storytelling.',
      ),
      (
        name: 'Connector',
        role: 'Network pathfinding',
        state: 'Routing',
        confidence: 0.91,
        accent: AlterPalette.mint,
        summary: 'Found 4 direct paths to design partners through NFC graph.',
      ),
    ];

    for (final a in agents) {
      await _client.from('clone_agents').insert({
        'user_id': _uid,
        'name': a.name,
        'role': a.role,
        'state': a.state,
        'confidence': a.confidence,
        'accent_hex': a.accent.toARGB32().toString(),
        'summary': a.summary,
      });
    }

    return agents
        .map(
          (a) => CloneAgent(
            name: a.name,
            role: a.role,
            state: a.state,
            confidence: a.confidence,
            accent: a.accent,
            summary: a.summary,
          ),
        )
        .toList();
  }

  // ── Future Scenarios ──────────────────────────────────────────────────────

  @override
  Future<List<FutureScenario>> loadFutureScenarios() async {
    final rows = await _client
        .from('future_scenarios')
        .select()
        .eq('user_id', _uid)
        .order('created_at');

    if (rows.isEmpty) return _seedFutureScenarios();

    return rows.map((r) {
      return FutureScenario(
        title: r['title'] as String,
        horizon: r['horizon'] as String,
        probability: (r['probability'] as num).toDouble(),
        upside: r['upside'] as String,
        risk: r['risk'] as String,
        levers: List<String>.from(r['levers'] as List),
      );
    }).toList();
  }

  Future<List<FutureScenario>> _seedFutureScenarios() async {
    const scenarios = [
      (
        title: 'Premium Founder OS',
        horizon: '90 days',
        probability: 0.71,
        upside: 'High retention with 25 invite-only teams.',
        risk: 'Requires crisp memory permissions and trust narrative.',
        levers: ['OfficeKit', 'Clone Council', 'Reputation Engine'],
      ),
      (
        title: 'Conference Network Layer',
        horizon: '45 days',
        probability: 0.63,
        upside: 'NFC-based graph unlocks immediate social proof.',
        risk: 'Event density must be high enough for compounding value.',
        levers: ['NFC', 'Opportunity Radar', 'Social Graph'],
      ),
      (
        title: 'Lens for Field Intelligence',
        horizon: '120 days',
        probability: 0.54,
        upside: 'Camera intelligence becomes a unique daily habit.',
        risk: 'Needs excellent privacy defaults and offline fallback.',
        levers: ['Alter Lens', 'Memory Graph', 'Heatmap'],
      ),
    ];

    for (final s in scenarios) {
      await _client.from('future_scenarios').insert({
        'user_id': _uid,
        'title': s.title,
        'horizon': s.horizon,
        'probability': s.probability,
        'upside': s.upside,
        'risk': s.risk,
        'levers': s.levers,
      });
    }

    return scenarios
        .map(
          (s) => FutureScenario(
            title: s.title,
            horizon: s.horizon,
            probability: s.probability,
            upside: s.upside,
            risk: s.risk,
            levers: s.levers,
          ),
        )
        .toList();
  }

  // ── Opportunity Signals ───────────────────────────────────────────────────

  @override
  Future<List<OpportunitySignal>> loadOpportunitySignals() async {
    final rows = await _client
        .from('opportunity_signals')
        .select()
        .eq('user_id', _uid)
        .order('score', ascending: false);

    if (rows.isEmpty) return _seedOpportunitySignals();

    return rows.map((r) {
      return OpportunitySignal(
        title: r['title'] as String,
        category: r['category'] as String,
        score: (r['score'] as num).toDouble(),
        source: r['source'] as String,
        window: r['time_window'] as String,
        evidence: r['evidence'] as String,
      );
    }).toList();
  }

  Future<List<OpportunitySignal>> _seedOpportunitySignals() async {
    const signals = [
      (
        title: 'AI operator cohort partnership',
        category: 'Partnership',
        score: 0.94,
        source: 'Firecrawl + social graph',
        window: 'Closes in 5 days',
        evidence: 'Three cohort leads mentioned member tools this week.',
      ),
      (
        title: 'Private beta at Founders Table',
        category: 'Community',
        score: 0.87,
        source: 'NFC exchange',
        window: 'Tonight',
        evidence: 'Six attendees match your ideal design partner profile.',
      ),
      (
        title: 'OfficeKit pilot with legal ops',
        category: 'Enterprise',
        score: 0.78,
        source: 'Calendar + email intent',
        window: '14 days',
        evidence: 'Repeated workflow pain around briefing and follow-ups.',
      ),
    ];

    for (final s in signals) {
      await _client.from('opportunity_signals').insert({
        'user_id': _uid,
        'title': s.title,
        'category': s.category,
        'score': s.score,
        'source': s.source,
        'time_window': s.window,
        'evidence': s.evidence,
      });
    }

    return signals
        .map(
          (s) => OpportunitySignal(
            title: s.title,
            category: s.category,
            score: s.score,
            source: s.source,
            window: s.window,
            evidence: s.evidence,
          ),
        )
        .toList();
  }

  // ── Social Graph ──────────────────────────────────────────────────────────

  @override
  Future<List<SocialContact>> loadSocialGraph() async {
    final rows = await _client
        .from('social_contacts')
        .select()
        .eq('user_id', _uid)
        .order('strength', ascending: false);

    if (rows.isEmpty) return _seedSocialContacts();

    return rows.map((r) {
      return SocialContact(
        name: r['name'] as String,
        context: r['context'] as String,
        strength: (r['strength'] as num).toDouble(),
        tags: List<String>.from(r['tags'] as List),
      );
    }).toList();
  }

  Future<List<SocialContact>> _seedSocialContacts() async {
    const contacts = [
      (
        name: 'Maya Chen',
        context: 'Seed investor, met at demo night',
        strength: 0.91,
        tags: ['AI infra', 'Warm intro', 'High trust'],
      ),
      (
        name: 'Jon Bell',
        context: 'Community lead, operator circle',
        strength: 0.74,
        tags: ['Events', 'Founders', 'NFC'],
      ),
      (
        name: 'Nora Singh',
        context: 'Design partner candidate',
        strength: 0.68,
        tags: ['Legal ops', 'OfficeKit'],
      ),
      (
        name: 'Ezra Cole',
        context: 'Technical founder, graph systems',
        strength: 0.58,
        tags: ['Neo4j', 'Memory', 'Advisor'],
      ),
    ];

    for (final c in contacts) {
      await _client.from('social_contacts').insert({
        'user_id': _uid,
        'name': c.name,
        'context': c.context,
        'strength': c.strength,
        'tags': c.tags,
      });
    }

    return contacts
        .map(
          (c) => SocialContact(
            name: c.name,
            context: c.context,
            strength: c.strength,
            tags: c.tags,
          ),
        )
        .toList();
  }

  // ── Reputation Events ─────────────────────────────────────────────────────

  @override
  Future<List<ReputationEvent>> loadReputationEvents() async {
    final rows = await _client
        .from('reputation_events')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(20);

    if (rows.isEmpty) return _seedReputationEvents();

    return rows.map((r) {
      return ReputationEvent(
        title: r['title'] as String,
        delta: r['delta'] as int,
        description: r['description'] as String,
        timestamp: r['timestamp'] as String,
      );
    }).toList();
  }

  Future<List<ReputationEvent>> _seedReputationEvents() async {
    const events = [
      (
        title: 'Account created',
        delta: 10,
        description: 'Welcome to ALTER. Your reputation journey begins.',
        timestamp: 'Just now',
      ),
      (
        title: 'Profile set up',
        delta: 8,
        description: 'Complete your profile to increase trust signals.',
        timestamp: 'Just now',
      ),
    ];

    for (final e in events) {
      await _client.from('reputation_events').insert({
        'user_id': _uid,
        'title': e.title,
        'delta': e.delta,
        'description': e.description,
        'timestamp': e.timestamp,
      });
    }

    return events
        .map(
          (e) => ReputationEvent(
            title: e.title,
            delta: e.delta,
            description: e.description,
            timestamp: e.timestamp,
          ),
        )
        .toList();
  }

  // ── Lens Insights ─────────────────────────────────────────────────────────

  @override
  Future<List<LensInsight>> loadLensInsights() async {
    final rows = await _client
        .from('lens_insights')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(10);

    if (rows.isEmpty) return _seedLensInsights();

    return rows.map((r) {
      return LensInsight(
        title: r['title'] as String,
        confidence: (r['confidence'] as num).toDouble(),
        description: r['description'] as String,
        actions: List<String>.from(r['actions'] as List),
      );
    }).toList();
  }

  Future<List<LensInsight>> _seedLensInsights() async {
    const insights = [
      (
        title: 'Whiteboard strategy captured',
        confidence: 0.92,
        description: 'Detected GTM funnel, pricing options, and risk notes.',
        actions: ['Create memory', 'Ask Council', 'Simulate'],
      ),
      (
        title: 'Business card enriched',
        confidence: 0.86,
        description: 'Matched contact to LinkedIn, event, and mutual graph.',
        actions: ['Save NFC profile', 'Draft follow-up'],
      ),
      (
        title: 'Meeting room context',
        confidence: 0.79,
        description: 'Recognized OfficeKit agenda and open decisions.',
        actions: ['Start briefing', 'Record action items'],
      ),
    ];

    for (final i in insights) {
      await _client.from('lens_insights').insert({
        'user_id': _uid,
        'title': i.title,
        'confidence': i.confidence,
        'description': i.description,
        'actions': i.actions,
      });
    }

    return insights
        .map(
          (i) => LensInsight(
            title: i.title,
            confidence: i.confidence,
            description: i.description,
            actions: i.actions,
          ),
        )
        .toList();
  }
}

