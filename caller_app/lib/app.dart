import 'package:caller_app/features/auth/views/auth_screen.dart';
import 'package:caller_app/features/call/views/caller_home_screen.dart';
import 'package:caller_app/features/call/views/listener_home_screen.dart';
import 'package:caller_app/features/splash/views/splash_screen.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final bool isListenerApp;

  const MyApp({super.key, required this.isListenerApp});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: isListenerApp ? 'Listener App' : 'Caller App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(isListenerApp: isListenerApp),
        '/auth': (context) =>
            AuthScreen(isLogin: true, isListenerApp: isListenerApp),
        '/login': (context) =>
            AuthScreen(isLogin: true, isListenerApp: isListenerApp),
        '/register': (context) =>
            AuthScreen(isLogin: false, isListenerApp: isListenerApp),
        if (!isListenerApp)
          '/caller_home': (context) => const CallerHomeScreen(),
        if (isListenerApp)
          '/listener_home': (context) => const ListenerHomeScreen(),
      },
    );
  }
}
