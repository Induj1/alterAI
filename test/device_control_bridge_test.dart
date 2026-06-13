import 'package:alter/src/features/device_control/data/device_control_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses native device control result', () {
    final result = DeviceControlResult.fromMap({
      'ok': true,
      'message': 'Opened Android settings.',
    });

    expect(result.ok, isTrue);
    expect(result.message, 'Opened Android settings.');
  });

  test('parses visible screen snapshot', () {
    final snapshot = DeviceScreenSnapshot.fromMap({
      'ok': true,
      'message': 'Read 1 visible nodes.',
      'packageName': 'com.example',
      'className': 'Root',
      'text': 'Continue',
      'nodes': [
        {
          'text': 'Continue',
          'className': 'android.widget.Button',
          'viewId': 'continue_button',
          'clickable': true,
          'editable': false,
          'scrollable': false,
          'bounds': {'left': 1, 'top': 2, 'right': 3, 'bottom': 4},
        },
      ],
    });

    expect(snapshot.ok, isTrue);
    expect(snapshot.nodes.single.text, 'Continue');
    expect(snapshot.nodes.single.clickable, isTrue);
  });
}
