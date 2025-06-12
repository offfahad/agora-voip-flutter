import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:listener_app/firebase_options.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/firebase_messaging_service.dart';
import 'features/auth/view_models/auth_view_model.dart';
import 'features/call/view_models/caller_view_model.dart';
import 'features/call/view_models/listener_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize services
  await FirebaseMessagingService.instance.initialize(navigatorKey);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CallerViewModel()),
        ChangeNotifierProvider(create: (_) => ListenerViewModel()),
      ],
      child: const MyApp(isListenerApp: true),
    ),
  );
}
