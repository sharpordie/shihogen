import 'dart:io';

import 'package:netnerve/netnerve.dart';
import 'package:shihogen/updaters/updater.dart';

class Biglybt extends Updater {
  Biglybt(super.android);

  @override
  String get package => 'com.spotify.tv.android';

  @override
  String get heading => 'Spotify';

  @override
  Future<File?> runGather() async {
    const address = 'https://api.github.com/repos/BiglySoftware/BiglyBT-Android/releases/latest';
    return await getFromGithub(address, RegExp('BiglyBT-([\\d.]+).apk'));
  }
}
