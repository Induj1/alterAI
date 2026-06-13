import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Real device actions ALTER can take. Every one launches an OS surface (dialer,
/// WhatsApp, SMS, browser, calendar) where the USER makes the final tap — the
/// honest version of "controls the phone": permissioned intents, never silent
/// background automation.
class DeviceActions {
  const DeviceActions();

  Future<String> _open(Uri uri, {bool external = true}) async {
    try {
      final ok = await launchUrl(
        uri,
        mode: external
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
      return ok ? 'ok' : 'could_not_open';
    } catch (e) {
      return 'error: $e';
    }
  }

  Future<String> callNumber(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
    final r = await _open(Uri.parse('tel:$clean'));
    return r == 'ok'
        ? 'Opened the dialer for $clean. The user taps call to confirm.'
        : 'Could not open the dialer ($r).';
  }

  Future<String> sendMessage({
    required String app,
    required String number,
    required String text,
  }) async {
    final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
    final enc = Uri.encodeComponent(text);
    final Uri uri;
    if (app.toLowerCase() == 'whatsapp') {
      uri = Uri.parse('https://wa.me/${clean.replaceAll('+', '')}?text=$enc');
    } else {
      uri = Uri.parse('sms:$clean?body=$enc');
    }
    final r = await _open(uri);
    return r == 'ok'
        ? 'Opened $app with the message prefilled. The user presses send.'
        : 'Could not open $app ($r).';
  }

  Future<String> openUrl(String url) async {
    final fixed = url.startsWith('http') ? url : 'https://$url';
    final r = await _open(Uri.parse(fixed));
    return r == 'ok' ? 'Opened $fixed.' : 'Could not open the link ($r).';
  }

  Future<String> webSearch(String query) async {
    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
    );
    final r = await _open(uri);
    return r == 'ok'
        ? 'Opened a web search for "$query".'
        : 'Could not open the browser ($r).';
  }

  Future<String> addCalendarEvent({
    required String title,
    String details = '',
    String startIso = '',
  }) async {
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': title,
      if (details.isNotEmpty) 'details': details,
    };
    // Google Calendar wants UTC basic format yyyymmddThhmmssZ for dates.
    final start = DateTime.tryParse(startIso);
    if (start != null) {
      final s = _gcalStamp(start.toUtc());
      final e = _gcalStamp(start.toUtc().add(const Duration(hours: 1)));
      params['dates'] = '$s/$e';
    }
    final uri = Uri.https('calendar.google.com', '/calendar/render', params);
    final r = await _open(uri);
    return r == 'ok'
        ? 'Opened Google Calendar with "$title" prefilled. The user saves it.'
        : 'Could not open the calendar ($r).';
  }

  /// Resolve a name to phone number(s) from the user's contacts.
  Future<String> findContact(String name) async {
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      final ok =
          permission == PermissionStatus.granted ||
          permission == PermissionStatus.limited;
      if (!ok) return 'Contacts permission was denied.';
      final all = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final q = name.toLowerCase().trim();
      final matches = all
          .where((Contact c) => (c.displayName ?? '').toLowerCase().contains(q))
          .take(5)
          .toList();
      if (matches.isEmpty) return 'No contact found matching "$name".';
      return matches
          .map((Contact c) {
            final displayName = c.displayName ?? 'Unnamed contact';
            final num = c.phones.isNotEmpty
                ? c.phones.first.number
                : 'no number';
            return '$displayName: $num';
          })
          .join('; ');
    } catch (e) {
      return 'Could not read contacts: $e';
    }
  }

  String _gcalStamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}T${two(dt.hour)}${two(dt.minute)}${two(dt.second)}Z';
  }
}
