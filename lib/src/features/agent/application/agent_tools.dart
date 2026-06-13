import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contextos/application/daytwin_controller.dart';
import '../../contextos/application/decision_council_controller.dart';
import '../../contextos/application/futuretwin_controller.dart';
import '../../contextos/application/lifeshield_controller.dart';
import '../../contextos/application/openclaw_adapter.dart';
import '../../contextos/domain/contextos_models.dart';
import '../../device_control/application/phone_control_controller.dart';
import '../data/device_actions.dart';
import 'agent_execution_runtime.dart';
import 'notification_monitor.dart';

/// OpenAI tool schemas the agent can call. Engine tools route to the ContextOS
/// engines; device tools launch permissioned OS surfaces the user confirms.
const kAgentTools = <Map<String, dynamic>>[
  {
    'type': 'function',
    'function': {
      'name': 'safety_check',
      'description':
          'Check whether a message, link, QR/payment, or install prompt is safe '
          'to act on. Use whenever the user shares something suspicious or asks '
          '"is this safe / a scam".',
      'parameters': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string', 'description': 'The content to check.'},
        },
        'required': ['text'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'plan_day',
      'description':
          'Model the user\'s day into Default / Risk / Optimized timelines and '
          'return pressure points and the single next best move.',
      'parameters': {
        'type': 'object',
        'properties': {
          'context': {
            'type': 'string',
            'description':
                'The user\'s plans, deadlines, commute, meetings today.',
          },
        },
        'required': ['context'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'weigh_decision',
      'description':
          'Simulate a bigger life/work decision into Safe / Smart / Bold paths '
          'with a regret-minimizing recommendation.',
      'parameters': {
        'type': 'object',
        'properties': {
          'decision': {
            'type': 'string',
            'description': 'The decision to weigh.',
          },
        },
        'required': ['decision'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'ask_council',
      'description':
          'Convene five inner voices (Practical, Risk, Future, Skeptic, Action) '
          'for an important decision; returns consensus + recommendation.',
      'parameters': {
        'type': 'object',
        'properties': {
          'question': {'type': 'string'},
        },
        'required': ['question'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'find_contact',
      'description':
          'Look up a person in the user\'s contacts by name to get their phone '
          'number. Use this BEFORE calling or messaging someone by name '
          '(e.g. "call mom").',
      'parameters': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'required': ['name'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'call_number',
      'description': 'Open the phone dialer for a number (user taps to call).',
      'parameters': {
        'type': 'object',
        'properties': {
          'number': {'type': 'string'},
        },
        'required': ['number'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'send_message',
      'description':
          'Open WhatsApp or SMS with a prefilled message (user presses send).',
      'parameters': {
        'type': 'object',
        'properties': {
          'app': {
            'type': 'string',
            'enum': ['whatsapp', 'sms'],
          },
          'number': {'type': 'string'},
          'text': {'type': 'string'},
        },
        'required': ['app', 'number', 'text'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'open_url',
      'description': 'Open a website or app link in the browser.',
      'parameters': {
        'type': 'object',
        'properties': {
          'url': {'type': 'string'},
        },
        'required': ['url'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'web_search',
      'description': 'Search the web for something.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
        },
        'required': ['query'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'add_calendar_event',
      'description':
          'Open the calendar with an event prefilled (user saves it).',
      'parameters': {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'details': {'type': 'string'},
          'start_iso': {
            'type': 'string',
            'description': 'ISO-8601 start time if known.',
          },
        },
        'required': ['title'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'open_app',
      'description':
          'Open an installed Android app by common name or package name.',
      'parameters': {
        'type': 'object',
        'properties': {
          'app_name': {
            'type': 'string',
            'description': 'Common app name, e.g. WhatsApp, Chrome, Gmail.',
          },
          'package_name': {
            'type': 'string',
            'description': 'Android package name if known.',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'open_settings',
      'description':
          'Open Android settings: accessibility, wifi, bluetooth, notifications, apps, battery, privacy, or general.',
      'parameters': {
        'type': 'object',
        'properties': {
          'screen': {'type': 'string'},
        },
        'required': ['screen'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'read_screen',
      'description':
          'Read visible on-screen text through the user-enabled Android Accessibility service.',
      'parameters': {'type': 'object', 'properties': <String, dynamic>{}},
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'click_text',
      'description':
          'Click a visible UI element by text through Accessibility. Do not use for Send, Pay, Confirm, Install, Approve, or other high-impact final actions.',
      'parameters': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string'},
        },
        'required': ['text'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'type_text',
      'description':
          'Type text into the currently focused editable field through Accessibility.',
      'parameters': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string'},
        },
        'required': ['text'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'press_phone_button',
      'description':
          'Perform a global Android Accessibility action: back, home, recents, notifications, or quick_settings.',
      'parameters': {
        'type': 'object',
        'properties': {
          'button': {
            'type': 'string',
            'enum': [
              'back',
              'home',
              'recents',
              'notifications',
              'quick_settings',
            ],
          },
        },
        'required': ['button'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'scroll_screen',
      'description':
          'Scroll the current visible screen forward/down or backward/up through Accessibility.',
      'parameters': {
        'type': 'object',
        'properties': {
          'direction': {
            'type': 'string',
            'enum': ['forward', 'backward', 'up', 'down'],
          },
        },
        'required': ['direction'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'queue_openclaw_action',
      'description':
          'Queue a phone action in OpenClaw for explicit user review and confirmation. Use for send/pay/install/approve/delete or any action that commits something.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action_type': {'type': 'string'},
          'title': {'type': 'string'},
          'detail': {'type': 'string'},
          'irreversible': {'type': 'boolean'},
        },
        'required': ['action_type', 'title'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'notification_reply',
      'description':
          'Reply to the latest Android notification only when Android exposes a quick-reply action. Use only after explicit user confirmation.',
      'parameters': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string'},
          'package_name': {'type': 'string'},
        },
        'required': ['text'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'run_phone_agent_loop',
      'description':
          'Run the observe-plan-act phone loop: observe screen, plan, execute safe step, re-observe, and audit.',
      'parameters': {
        'type': 'object',
        'properties': {
          'goal': {'type': 'string'},
        },
        'required': ['goal'],
      },
    },
  },
];

/// Short human label for a tool, shown as a chip while it runs.
String agentToolLabel(String name) => switch (name) {
  'find_contact' => 'Looking up contact…',
  'safety_check' => 'Running LifeShield…',
  'plan_day' => 'Modeling your day…',
  'weigh_decision' => 'Simulating futures…',
  'ask_council' => 'Convening the council…',
  'call_number' => 'Opening dialer…',
  'send_message' => 'Opening message…',
  'open_url' => 'Opening link…',
  'web_search' => 'Searching the web…',
  'notification_reply' => 'Replying to notification...',
  'run_phone_agent_loop' => 'Running phone agent loop...',
  'add_calendar_event' => 'Opening calendar…',
  'open_app' => 'Opening app...',
  'open_settings' => 'Opening settings...',
  'read_screen' => 'Reading visible screen...',
  'click_text' => 'Clicking visible item...',
  'type_text' => 'Typing text...',
  'press_phone_button' => 'Pressing phone control...',
  'scroll_screen' => 'Scrolling screen...',
  'queue_openclaw_action' => 'Queuing OpenClaw action...',
  _ => 'Working…',
};

/// Executes a tool call and returns a concise text result for the model.
Future<String> executeAgentTool(
  Ref ref,
  String name,
  Map<String, dynamic> args,
) async {
  const device = DeviceActions();
  final phone = ref.read(phoneControlControllerProvider.notifier);
  String s(String k) => (args[k] ?? '').toString();

  switch (name) {
    case 'safety_check':
      final ls = ref.read(lifeShieldControllerProvider.notifier);
      ls.setSource(MomentSource.shareSheet);
      ls.setInput(s('text'));
      await ls.capture();
      final a = ref.read(lifeShieldControllerProvider).analysis;
      if (a == null) return 'No analysis available.';
      return 'Verdict: ${a.verdict.label}. ${a.headline}. ${a.whyItMatters} '
          '${a.redFlags.isEmpty ? '' : 'Red flags: ${a.redFlags.join('; ')}.'}';

    case 'plan_day':
      final d = ref.read(dayTwinControllerProvider.notifier);
      d.setInput(s('context'));
      await d.simulate();
      final r = ref.read(dayTwinControllerProvider).result;
      if (r == null) return 'No plan available.';
      return '${r.headline}. Next best move: ${r.nextBestMove}. '
          'Pressure points: ${r.pressurePoints.join('; ')}.';

    case 'weigh_decision':
      final f = ref.read(futureTwinControllerProvider.notifier);
      f.setInput(s('decision'));
      await f.simulate();
      final r = ref.read(futureTwinControllerProvider).result;
      if (r == null) return 'No simulation available.';
      return '${r.headline}. ${r.summary} Recommended path: ${r.recommended}. '
          '${r.regretMinimizer}';

    case 'ask_council':
      final c = ref.read(decisionCouncilProvider.notifier);
      c.setTopic(s('question'));
      await c.convene();
      final r = ref.read(decisionCouncilProvider).result;
      if (r == null) return 'No council result.';
      return 'Consensus: ${r.consensus} Recommendation: ${r.recommendation} '
          'Dissent: ${r.dissent}';

    case 'find_contact':
      return device.findContact(s('name'));
    case 'call_number':
      return device.callNumber(s('number'));
    case 'send_message':
      return device.sendMessage(
        app: s('app'),
        number: s('number'),
        text: s('text'),
      );
    case 'open_url':
      return device.openUrl(s('url'));
    case 'web_search':
      return phone.browserSearch(s('query'));
    case 'notification_reply':
      return ref
          .read(notificationMonitorProvider.notifier)
          .replyToLatest(text: s('text'), packageName: s('package_name'));
    case 'run_phone_agent_loop':
      await ref.read(agentExecutionRuntimeProvider.notifier).runGoal(s('goal'));
      final runtime = ref.read(agentExecutionRuntimeProvider);
      return 'Phone loop completed ${runtime.completedSteps}/${runtime.plan.length} steps. Latest audit: ${runtime.audit.isEmpty ? 'none' : runtime.audit.first.summary}';
    case 'add_calendar_event':
      return device.addCalendarEvent(
        title: s('title'),
        details: s('details'),
        startIso: s('start_iso'),
      );
    case 'open_app':
      return phone.openApp(
        appName: s('app_name'),
        packageName: s('package_name'),
      );
    case 'open_settings':
      return phone.openSettings(s('screen'));
    case 'read_screen':
      final snapshot = await phone.readScreen();
      if (!snapshot.ok) return snapshot.message;
      final structured = ref
          .read(phoneControlControllerProvider)
          .lastStructuredScreen;
      return structured?.toAgentSummary() ?? snapshot.message;
    case 'click_text':
      final target = s('text');
      if (_isHighImpactClick(target)) {
        return 'I can prepare this, but I will not click "$target" directly. Use OpenClaw confirmation for final send/pay/install/approve actions.';
      }
      return phone.clickText(target);
    case 'type_text':
      return phone.typeText(s('text'));
    case 'press_phone_button':
      return phone.press(s('button'));
    case 'scroll_screen':
      return phone.scroll(s('direction'));
    case 'queue_openclaw_action':
      return ref
          .read(openClawQueueProvider.notifier)
          .enqueueStructured(
            type: s('action_type'),
            title: s('title'),
            detail: s('detail'),
            irreversible: args['irreversible'] == true,
          );
    default:
      return 'Unknown tool: $name';
  }
}

bool _isHighImpactClick(String text) {
  return RegExp(
    r'\b(send|pay|confirm|approve|install|buy|purchase|transfer|delete|allow|grant)\b',
    caseSensitive: false,
  ).hasMatch(text);
}
