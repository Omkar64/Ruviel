// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ShareHelper {
  static Future<bool> share({
    required String title,
    required String text,
    required String url,
  }) async {
    final navigator = html.window.navigator;

    // The "share" API is not yet modelled in dart:html types, so we must
    // access it dynamically and handle the case where it's not available.
    final dynamic navDynamic = navigator;
    final dynamic shareFn = navDynamic.share;

    if (shareFn == null) {
      return false;
    }

    try {
      await shareFn(<String, Object?>{
        'title': title,
        'text': text,
        'url': url,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> shareToFacebook({
    required String url,
    String? quote,
  }) async {
    final message = quote != null ? '$quote\n$url' : url;
    return await share(
      title: 'Share to Facebook',
      text: message,
      url: url,
    );
  }

  static Future<bool> shareToMessenger({
    required String text,
    String? url,
  }) async {
    final message = url != null ? '$text\n$url' : text;
    return await share(
      title: 'Share to Messenger',
      text: message,
      url: url ?? '',
    );
  }

  static Future<bool> shareToWhatsApp({
    required String text,
    String? url,
  }) async {
    final message = url != null ? '$text\n$url' : text;
    return await share(
      title: 'Share to WhatsApp',
      text: message,
      url: url ?? '',
    );
  }

  static Future<bool> shareViaEmail({
    required String subject,
    required String body,
    List<String>? recipients,
  }) async {
    return await share(
      title: subject,
      text: body,
      url: '',
    );
  }

  static Future<bool> shareToTwitter({
    required String text,
    String? url,
  }) async {
    final message = url != null ? '$text\n$url' : text;
    return await share(
      title: 'Share to X/Twitter',
      text: message,
      url: url ?? '',
    );
  }

  static Future<bool> shareToThreads({
    required String text,
    String? url,
  }) async {
    final message = url != null ? '$text\n$url' : text;
    return await share(
      title: 'Share to Threads',
      text: message,
      url: url ?? '',
    );
  }
}
