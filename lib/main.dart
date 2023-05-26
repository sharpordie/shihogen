import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shihogen/views/accounts.dart';
import 'package:shihogen/views/discover.dart';
import 'package:shihogen/views/guidance.dart';
import 'package:shihogen/views/launcher.dart';
import 'package:shihogen/views/updating.dart';
import 'package:wakelock/wakelock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable();
  runApp(myApp());
}

Widget myApp() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  return MaterialApp(
    title: 'Shihogen',
    debugShowCheckedModeBanner: false,
    darkTheme: ThemeData.dark(useMaterial3: true),
    theme: ThemeData.light(useMaterial3: true),
    themeMode: ThemeMode.light,
    initialRoute: '/discover',
    routes: {
      '/discover': (context) => DiscoverView(),
      '/guidance': (context) => GuidanceView(),
      '/launcher': (context) => LauncherView(),
      '/accounts': (context) => AccountsView(),
      '/updating': (context) => UpdatingView(),
    },
  );
}