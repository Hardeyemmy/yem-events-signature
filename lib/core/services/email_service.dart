import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  Future<void> sendRsvpConfirmationEmail({
    required String attendeeEmail,
    required String attendeeName,
    required String eventTitle,
    required String eventDate,
    required String eventLocation,
  }) async {
    try {
      await emailjs.send(
        dotenv.env['EMAILJS_SERVICE_ID']!,
        dotenv.env['EMAILJS_TEMPLATE_CONFIRMATION']!,
        {
          'to_email': attendeeEmail,
          'to_name': attendeeName,
          'event_title': eventTitle,
          'event_date': eventDate,
          'event_location': eventLocation,
        },
        emailjs.Options(publicKey: dotenv.env['EMAILJS_PUBLIC_KEY']!),
      );
      print('Confirmation email sent to $attendeeEmail');
    } catch (e) {
      print('Fail to send Confirmation email: $e');
    }
  }

  Future<void> sendCreatorNotificationEmail({
    required String creatorEmail,
    required String creatorName,
    required String attendeeName,
    required String eventTitle,
    required int attendeeCount,
  }) async {
    try {
      await emailjs.send(
        dotenv.env['EMAILJS_SERVICE_ID']!,
        dotenv.env['EMAILJS_TEMPLATE_CREATOR_NOTIFY']!,
        {
          'to_email': creatorEmail,
          'to_name': creatorName,
          'attendee_name': attendeeName,
          'event_title': eventTitle,
          'attendee_count': attendeeCount,
        },
        emailjs.Options(publicKey: dotenv.env['EMAILJS_PUBLIC_KEY']),
      );
      print('Creator Notification email sent to: $creatorEmail');
    } catch (e) {
      print('Failed to send creator email: $e');
    }
  }
}
