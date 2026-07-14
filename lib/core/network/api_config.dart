import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Set to true to connect to production Render URL, or false for localhost emulator
  static const bool isProduction = false;

  static String get identityUrl {
    if (isProduction) {
      return 'https://journal-trend-tracker-backend.onrender.com';
    } else {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:5251';
      }
      return 'http://localhost:5251';
    }
  }

  static String get paperUrl {
    if (isProduction) {
      return 'https://prn-paperservice.onrender.com';
    } else {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:5145';
      }
      return 'http://localhost:5145';
    }
  }

  static String get userUrl {
    if (isProduction) {
      return 'https://user-service-9nhk.onrender.com';
    } else {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:5210';
      }
      return 'http://localhost:5210';
    }
  }

  static String get adminUrl {
    if (isProduction) {
      return 'https://admin-service-924r.onrender.com';
    } else {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:5035';
      }
      return 'http://localhost:5035';
    }
  }

  static String get trendUrl {
    if (isProduction) {
      return 'https://journal-trend-tracker-backend-vyt9.onrender.com';
    } else {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:5003';
      }
      return 'http://localhost:5003';
    }
  }
}
