import 'package:flutter/foundation.dart';

class ShareHelper {
  static Future<bool> share({
    required String title,
    required String text,
    required String url,
  }) async {
    if (!kIsWeb) {
      return false;
    }
    return false;
  }

  static Future<bool> shareToFacebook({
    required String url,
    String? quote,
  }) async {
    return false;
  }

  static Future<bool> shareToMessenger({
    required String text,
    String? url,
  }) async {
    return false;
  }

  static Future<bool> shareToWhatsApp({
    required String text,
    String? url,
  }) async {
    return false;
  }

  static Future<bool> shareViaEmail({
    required String subject,
    required String body,
    List<String>? recipients,
  }) async {
    return false;
  }

  static Future<bool> shareToTwitter({
    required String text,
    String? url,
  }) async {
    return false;
  }

  static Future<bool> shareToThreads({
    required String text,
    String? url,
  }) async {
    return false;
  }
}
