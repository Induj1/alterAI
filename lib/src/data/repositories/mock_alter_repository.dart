import '../../core/theme/alter_palette.dart';
import '../../domain/entities/alter_models.dart';
import '../../domain/repositories/alter_repository.dart';

class MockAlterRepository implements AlterRepository {
  const MockAlterRepository();

  @override
  Future<AssistantBrief> loadAssistantBrief() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return const AssistantBrief(
      greeting: 'Good evening, Aria.',
      focus: 'Your best move is to package the AI networking product demo.',
      nextAction: 'Ask the Growth Clone to draft a launch map.',
      signals: [
        '3 warm intros are ready',
        'Founder community intent is rising',
        'Calendar has a 42 minute focus window',
      ],
    );
  }

  @override
  Future<List<CloneAgent>> loadCloneCouncil() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    return const [
      CloneAgent(
        name: 'Strategist',
        role: 'Market timing and positioning',
        state: 'Synthesizing',
        confidence: 0.88,
        accent: AlterPalette.iris,
        summary: 'Recommends narrowing the beta to investor-backed founders.',
      ),
      CloneAgent(
        name: 'Operator',
        role: 'Execution plan and constraints',
        state: 'Ready',
        confidence: 0.82,
        accent: AlterPalette.cyan,
        summary: 'Flags onboarding friction as the highest execution risk.',
      ),
      CloneAgent(
        name: 'Contrarian',
        role: 'Risk, second-order effects',
        state: 'Challenging',
        confidence: 0.76,
        accent: AlterPalette.aura,
        summary: 'Pushes for one paid pilot before broad storytelling.',
      ),
      CloneAgent(
        name: 'Connector',
        role: 'Network pathfinding',
        state: 'Routing',
        confidence: 0.91,
        accent: AlterPalette.mint,
        summary: 'Found 4 direct paths to design partners through NFC graph.',
      ),
    ];
  }

  @override
  Future<List<FutureScenario>> loadFutureScenarios() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return const [
      FutureScenario(
        title: 'Premium Founder OS',
        horizon: '90 days',
        probability: 0.71,
        upside: 'High retention with 25 invite-only teams.',
        risk: 'Requires crisp memory permissions and trust narrative.',
        levers: ['OfficeKit', 'Clone Council', 'Reputation Engine'],
      ),
      FutureScenario(
        title: 'Conference Network Layer',
        horizon: '45 days',
        probability: 0.63,
        upside: 'NFC-based graph unlocks immediate social proof.',
        risk: 'Event density must be high enough for compounding value.',
        levers: ['NFC', 'Opportunity Radar', 'Social Graph'],
      ),
      FutureScenario(
        title: 'Lens for Field Intelligence',
        horizon: '120 days',
        probability: 0.54,
        upside: 'Camera intelligence becomes a unique daily habit.',
        risk: 'Needs excellent privacy defaults and offline fallback.',
        levers: ['Alter Lens', 'Memory Graph', 'Heatmap'],
      ),
    ];
  }

  @override
  Future<List<OpportunitySignal>> loadOpportunitySignals() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [
      OpportunitySignal(
        title: 'AI operator cohort partnership',
        category: 'Partnership',
        score: 0.94,
        source: 'Firecrawl + social graph',
        window: 'Closes in 5 days',
        evidence: 'Three cohort leads mentioned member tools this week.',
      ),
      OpportunitySignal(
        title: 'Private beta at Founders Table',
        category: 'Community',
        score: 0.87,
        source: 'NFC exchange',
        window: 'Tonight',
        evidence: 'Six attendees match your ideal design partner profile.',
      ),
      OpportunitySignal(
        title: 'OfficeKit pilot with legal ops',
        category: 'Enterprise',
        score: 0.78,
        source: 'Calendar + email intent',
        window: '14 days',
        evidence: 'Repeated workflow pain around briefing and follow-ups.',
      ),
    ];
  }

  @override
  Future<List<SocialContact>> loadSocialGraph() async {
    await Future<void>.delayed(const Duration(milliseconds: 210));
    return const [
      SocialContact(
        name: 'Maya Chen',
        context: 'Seed investor, met at demo night',
        strength: 0.91,
        tags: ['AI infra', 'Warm intro', 'High trust'],
      ),
      SocialContact(
        name: 'Jon Bell',
        context: 'Community lead, operator circle',
        strength: 0.74,
        tags: ['Events', 'Founders', 'NFC'],
      ),
      SocialContact(
        name: 'Nora Singh',
        context: 'Design partner candidate',
        strength: 0.68,
        tags: ['Legal ops', 'OfficeKit'],
      ),
      SocialContact(
        name: 'Ezra Cole',
        context: 'Technical founder, graph systems',
        strength: 0.58,
        tags: ['Neo4j', 'Memory', 'Advisor'],
      ),
    ];
  }

  @override
  Future<List<ReputationEvent>> loadReputationEvents() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [
      ReputationEvent(
        title: 'Delivered beta walkthrough',
        delta: 18,
        description: 'Strong response from three invited operators.',
        timestamp: 'Today',
      ),
      ReputationEvent(
        title: 'Closed the loop on intro',
        delta: 12,
        description: 'Follow-up sent within 2 hours with useful context.',
        timestamp: 'Yesterday',
      ),
      ReputationEvent(
        title: 'Missed advisory reply',
        delta: -4,
        description: 'Reputation engine recommends a concise recovery note.',
        timestamp: '2 days ago',
      ),
    ];
  }

  @override
  Future<List<LensInsight>> loadLensInsights() async {
    await Future<void>.delayed(const Duration(milliseconds: 230));
    return const [
      LensInsight(
        title: 'Whiteboard strategy captured',
        confidence: 0.92,
        description: 'Detected GTM funnel, pricing options, and risk notes.',
        actions: ['Create memory', 'Ask Council', 'Simulate'],
      ),
      LensInsight(
        title: 'Business card enriched',
        confidence: 0.86,
        description: 'Matched contact to LinkedIn, event, and mutual graph.',
        actions: ['Save NFC profile', 'Draft follow-up'],
      ),
      LensInsight(
        title: 'Meeting room context',
        confidence: 0.79,
        description: 'Recognized OfficeKit agenda and open decisions.',
        actions: ['Start briefing', 'Record action items'],
      ),
    ];
  }
}
