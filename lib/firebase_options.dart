// ignore_for_file: public_member_api_docs

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
GlobalFirebaseOptions get defaultFirebaseOptions {
  // This value will be retrieved on web
  if (kIsWeb) {
    return const GlobalFirebaseOptions(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDOwAqN_tXy81oN7-Jbl9uymHhukGib_mE',
        appId: '1:471117272148:web:4592ba8c06dce7af5813d9',
        messagingSenderId: '471117272148',
        projectId: 'rise-d9a8a',
        authDomain: 'rise-d9a8a.firebaseapp.com',
        databaseURL: 'https://rise-d9a8a-default-rtdb.firebaseio.com/',
        storageBucket: 'rise-d9a8a.firebasestorage.app',
      ),
      web: true,
    );
  }

  // This value will be retrieved on Android
  if (defaultTargetPlatform == TargetPlatform.android) {
    return const GlobalFirebaseOptions(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDOwAqN_tXy81oN7-Jbl9uymHhukGib_mE',
        appId: '1:471117272148:android:a8c06dce7af5813d9549c1',
        messagingSenderId: '471117272148',
        projectId: 'rise-d9a8a',
        storageBucket: 'rise-d9a8a.firebasestorage.app',
      ),
      web: false,
    );
  }

  // This value will be retrieved on iOS
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return const GlobalFirebaseOptions(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDOwAqN_tXy81oN7-Jbl9uymHhukGib_mE',
        appId: '1:471117272148:ios:4592ba8c06dce7af5813d9',
        messagingSenderId: '471117272148',
        projectId: 'rise-d9a8a',
        authDomain: 'rise-d9a8a.firebaseapp.com',
        databaseURL: 'https://rise-d9a8a-default-rtdb.firebaseio.com/',
        storageBucket: 'rise-d9a8a.firebasestorage.app',
      ),
      web: false,
    );
  }

  // This value will be retrieved on non-Android, non-iOS platforms
  return const GlobalFirebaseOptions(
    options: FirebaseOptions(
      apiKey: 'AIzaSyDOwAqN_tXy81oN7-Jbl9uymHhukGib_mE',
      appId: '1:471117272148:web:4592ba8c06dce7af5813d9',
      messagingSenderId: '471117272148',
      projectId: 'rise-d9a8a',
      authDomain: 'rise-d9a8a.firebaseapp.com',
      databaseURL: 'https://rise-d9a8a-default-rtdb.firebaseio.com/',
      storageBucket: 'rise-d9a8a.firebasestorage.app',
    ),
    web: true,
  );
}

class GlobalFirebaseOptions {
  const GlobalFirebaseOptions({
    required this.options,
    required this.web,
  });

  final FirebaseOptions options;
  final bool web;
}
