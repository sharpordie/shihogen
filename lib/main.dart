import 'package:flutter/material.dart';
import 'package:shihogen/views/discover.dart';
import 'package:shihogen/views/guidance.dart';
import 'package:shihogen/views/launcher.dart';
import 'package:shihogen/views/settings.dart';
import 'package:shihogen/views/updating.dart';
import 'package:wakelock/wakelock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable();
  runApp(myApp());
}

Widget myApp() {
  return MaterialApp(
    title: 'Shihogen',
    debugShowCheckedModeBanner: false,
    darkTheme: ThemeData.dark(useMaterial3: true),
    theme: ThemeData.light(useMaterial3: true),
    themeMode: ThemeMode.system,
    initialRoute: '/discover',
    routes: {
      '/discover': (context) => DiscoverView(),
      '/guidance': (context) => GuidanceView(),
      '/launcher': (context) => LauncherView(),
      '/settings': (context) => SettingsView(),
      '/updating': (context) => UpdatingView(),
    },
  );
}