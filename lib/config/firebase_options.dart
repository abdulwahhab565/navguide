import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS is not configured in this project scope. '
          'Run: flutterfire configure to generate iOS options.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not supported in this project.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows is not supported in this project.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not supported in this project.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_eb7-bYyxd6BIW5rkwAUrHTPb_mbuTUc',
    appId: '1:649590785422:web:f33660712bf67e3dffd0df',
    messagingSenderId: '649590785422',
    projectId: 'navguide-uenr',
    authDomain: 'navguide-uenr.firebaseapp.com',
    storageBucket: 'navguide-uenr.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_eb7-bYyxd6BIW5rkwAUrHTPb_mbuTUc',
    appId: '1:649590785422:android:a3f7eb5e31d52603ffd0df',
    messagingSenderId: '649590785422',
    projectId: 'navguide-uenr',
    storageBucket: 'navguide-uenr.firebasestorage.app',
  );
}
