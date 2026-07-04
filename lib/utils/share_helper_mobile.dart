import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareHelper {
  static Future<bool> share({
    required String title,
    required String text,
    required String url,
  }) async {
    try {
      await Share.share(
        '$title\n$text\n$url',
        subject: title,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shareToWhatsApp({
    required String text,
    String? url,
  }) async {
    try {
      final message = url != null ? '$text\n$url' : text;
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
      return await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shareToFacebook({
    required String url,
    String? quote,
  }) async {
    try {
      final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}';
      if (quote != null) {
        return await launchUrl(
          Uri.parse('$facebookUrl&quote=${Uri.encodeComponent(quote)}'),
          mode: LaunchMode.externalApplication,
        );
      }
      return await launchUrl(
        Uri.parse(facebookUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shareToMessenger({
    required String text,
    String? url,
  }) async {
    try {
      final message = url != null ? '$text\n$url' : text;
      final messengerUrl = 'https://www.messenger.com/t/?text=${Uri.encodeComponent(message)}';
      return await launchUrl(
        Uri.parse(messengerUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shareViaEmail({
    required String subject,
    required String body,
    List<String>? recipients,
  }) async {
    try {
      final emailUrl = Uri(
        scheme: 'mailto',
        path: recipients?.join(',') ?? '',
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );
      return await launchUrl(
        emailUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shareToTwitter({
    required String text,
    String? url,
  }) async {
    try {
      final message = url != null ? '$text\n$url' : text;
      final twitterUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(message)}';
      return await launchUrl(
        Uri.parse(twitterUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shareToThreads({
    required String text,
    String? url,
  }) async {
    try {
      final message = url != null ? '$text\n$url' : text;
      final threadsUrl = 'https://www.threads.net/intent/post?text=${Uri.encodeComponent(message)}';
      return await launchUrl(
        Uri.parse(threadsUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }
}