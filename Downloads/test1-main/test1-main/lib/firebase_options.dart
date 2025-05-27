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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDdknm_TRGKkfeL6xptizphvNVYWaB1-Z8',
    appId: '1:994582313928:web:f5e142c39ebeb3c4199efd',
    messagingSenderId: '994582313928',
    projectId: 'newappfashion-da9d3',
    authDomain: 'newappfashion-da9d3.firebaseapp.com',
    storageBucket: 'newappfashion-da9d3.firebasestorage.app',
    measurementId: 'G-3430GX4PMB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdknm_TRGKkfeL6xptizphvNVYWaB1-Z8',
    appId: '1:994582313928:web:f5e142c39ebeb3c4199efd',
    messagingSenderId: '994582313928',
    projectId: 'newappfashion-da9d3',
    storageBucket: 'newappfashion-da9d3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDdknm_TRGKkfeL6xptizphvNVYWaB1-Z8',
    appId: '1:994582313928:web:f5e142c39ebeb3c4199efd',
    messagingSenderId: '994582313928',
    projectId: 'newappfashion-da9d3',
    storageBucket: 'newappfashion-da9d3.firebasestorage.app',
    iosClientId: '994582313928-web',
    iosBundleId: 'com.example.fashionmix',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDdknm_TRGKkfeL6xptizphvNVYWaB1-Z8',
    appId: '1:994582313928:web:f5e142c39ebeb3c4199efd',
    messagingSenderId: '994582313928',
    projectId: 'newappfashion-da9d3',
    storageBucket: 'newappfashion-da9d3.firebasestorage.app',
    iosClientId: '994582313928-web',
    iosBundleId: 'com.example.fashionmix',
  );
} 