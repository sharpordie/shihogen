import 'dart:io';

import 'package:netnerve/netnerve.dart';
import 'package:shihogen/updaters/updater.dart';

class Spotify extends Updater {
  Spotify(super.android);

  @override
  String get package => 'com.spotify.tv.android';

  @override
  String get heading => 'Spotify';

  @override
  Future<File?> runGather() async {
    const address = 'https://www.androidfilehost.com/?fid=6006931924117917314';
    return await getFromAndroidfilehost(address);
  }
}
