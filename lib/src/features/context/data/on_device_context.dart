import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final onDeviceContextProvider = Provider<OnDeviceContext>(
  (ref) => OnDeviceContext(),
);

/// Reads consented on-device context — today's calendar + current location — so
/// the agent can reason about the user's actual day ("you have a 3pm, leave
/// now"). Each read requests its own runtime permission and degrades gracefully
/// when denied or unavailable. Nothing is read passively or in the background.
class OnDeviceContext {
  OnDeviceContext();

  final DeviceCalendarPlugin _calendar = DeviceCalendarPlugin();

  /// Today's calendar events as readable "HH:MM Title" lines, or a status line.
  Future<String> todayCalendar() async {
    try {
      var granted = (await _calendar.hasPermissions()).data ?? false;
      if (!granted) {
        granted = (await _calendar.requestPermissions()).data ?? false;
      }
      if (!granted) return 'Calendar access not granted.';

      final calendars = (await _calendar.retrieveCalendars()).data ??
          const <Calendar>[];
      if (calendars.isEmpty) return 'No calendars found on this device.';

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final events = <Event>[];
      for (final calendar in calendars) {
        final id = calendar.id;
        if (id == null) continue;
        final result = await _calendar.retrieveEvents(
          id,
          RetrieveEventsParams(startDate: start, endDate: end),
        );
        events.addAll(result.data ?? const <Event>[]);
      }
      if (events.isEmpty) return 'No events on the calendar today.';

      events.sort((a, b) => (a.start ?? now).compareTo(b.start ?? now));
      String hhmm(DateTime? d) {
        if (d == null) return '';
        return '${d.hour.toString().padLeft(2, '0')}:'
            '${d.minute.toString().padLeft(2, '0')}';
      }

      return events.take(8).map((e) {
        final time = hhmm(e.start);
        final title = (e.title ?? '').trim().isEmpty ? 'Untitled' : e.title!;
        return time.isEmpty ? title : '$time $title';
      }).join('; ');
    } catch (e) {
      return 'Could not read the calendar: $e';
    }
  }

  /// Current approximate location as "lat, lng", or a status line.
  Future<String> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Location services are turned off.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Location access not granted.';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return '${pos.latitude.toStringAsFixed(4)}, '
          '${pos.longitude.toStringAsFixed(4)}';
    } catch (e) {
      return 'Could not read location: $e';
    }
  }

  /// Combined snapshot used by the agent's read_my_context tool.
  Future<String> snapshot({
    bool calendar = true,
    bool location = true,
  }) async {
    final parts = <String>[];
    if (calendar) parts.add('Today: ${await todayCalendar()}');
    if (location) parts.add('Location: ${await currentLocation()}');
    return parts.join(' | ');
  }
}
