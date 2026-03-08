import 'dart:io';

import 'package:flutter/services.dart';

class CookieExtractor {
  static const _channel = MethodChannel('frosty/cookie_extractor');

  static Future<String?> extractTwitchAuthToken() async {
    if (!Platform.isIOS) return null;
    return await _channel.invokeMethod<String>('extractTwitchAuthToken');
  }
}
