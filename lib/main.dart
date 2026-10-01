import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

/// Local development against the Firebase emulators (`firebase emulators:start
/// --only auth,firestore`), so testing never touches production data:
/// `flutter run --dart-define=USE_EMULATORS=true`. Off in every normal build.
const _useEmulators = bool.fromEnvironment('USE_EMULATORS');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  runApp(const LaufenApp());
}

class LaufenApp extends StatelessWidget {
  const LaufenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
