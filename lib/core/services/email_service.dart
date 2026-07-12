import 'dart:convert';
import 'package:http/http.dart' as http;
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
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': dotenv.env['EMAILJS_SERVICE_ID'],
          'template_id': dotenv.env['EMAILJS_TEMPLATE_CONFIRMATION'],
          'user_id': dotenv.env['EMAILJS_PUBLIC_KEY'],
          'template_params': {
            'to_email': attendeeEmail,
            'to_name': attendeeName,
            'event_title': eventTitle,
            'event_date': eventDate,
            'event_location': eventLocation,
          },
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(
          '🔴 EmailJS error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('🔴 Failed to send confirmation email: $e');
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
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': dotenv.env['EMAILJS_SERVICE_ID'],
          'template_id': dotenv.env['EMAILJS_TEMPLATE_CREATOR_NOTIFY'],
          'user_id': dotenv.env['EMAILJS_PUBLIC_KEY'],
          'template_params': {
            'to_email': creatorEmail,
            'to_name': creatorName,
            'attendee_name': attendeeName,
            'event_title': eventTitle,
            'attendee_count': attendeeCount.toString(),
          },
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(
          '🔴 EmailJS error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('🔴 Failed to send creator email: $e');
    }
  }
}
