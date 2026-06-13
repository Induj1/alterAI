import '../domain/contextos_models.dart';

/// Pre-built phone "moments" for demoing ContextOS without live capture.
class MomentFixture {
  const MomentFixture({
    required this.label,
    required this.source,
    required this.text,
  });

  final String label;
  final MomentSource source;
  final String text;
}

const kMomentFixtures = <MomentFixture>[
  MomentFixture(
    label: 'Fake bank SMS',
    source: MomentSource.notification,
    text:
        'ALERT: Your HDFC account will be SUSPENDED today due to incomplete KYC. '
        'Verify immediately to avoid blocking. Share OTP 482913 with our agent '
        'and click http://hdfc-kyc-verify.top/secure to reactivate. Act now.',
  ),
  MomentFixture(
    label: 'Fake delivery link',
    source: MomentSource.shareSheet,
    text:
        'Your parcel is on hold. A shipping fee of ₹45 is pending. Pay now to '
        'release delivery: https://bit.ly/track-parcel-209 — failure to pay in '
        '2 hours will return your package.',
  ),
  MomentFixture(
    label: 'Suspicious QR payment',
    source: MomentSource.qr,
    text:
        'Scan to RECEIVE ₹5000 cashback. UPI request from winner-rewards@ybl '
        'for ₹5000. Approve the collect request in your UPI app to claim your '
        'prize instantly.',
  ),
  MomentFixture(
    label: 'APK permission screen',
    source: MomentSource.install,
    text:
        'FastLoan Pro wants to install from unknown source. Requested '
        'permissions: read SMS, read contacts, access call logs, accessibility '
        'service, display over other apps, read OTP. Tap Install to continue.',
  ),
  MomentFixture(
    label: 'OTP scam call',
    source: MomentSource.call,
    text:
        'Caller: Sir I am calling from your bank security. We detected fraud on '
        'your card. To block it I need the 6-digit code we just sent. Please '
        'read it to me quickly, do not disconnect or your account will be '
        'frozen. Do not tell anyone, this is confidential.',
  ),
  MomentFixture(
    label: 'Travel delay / location risk',
    source: MomentSource.notification,
    text:
        'Your 18:40 cab to the airport is delayed 25 min due to heavy traffic '
        'on the ORR. Flight 6E-233 boarding closes 19:55. Current ETA to '
        'terminal: 19:48.',
  ),
  MomentFixture(
    label: 'Legit order update',
    source: MomentSource.notification,
    text:
        'Your Amazon order #402-7781 (USB-C cable) is out for delivery and will '
        'arrive today by 7 PM. Track in the Amazon app.',
  ),
  MomentFixture(
    label: 'ALTER self-demo',
    source: MomentSource.manual,
    text:
        'I just got a message saying I won an iPhone in a lucky draw I never '
        'entered. It wants me to pay ₹199 "delivery charge" via a link and '
        'confirm my address. Should I do it?',
  ),
];
