import 'dart:io';

import 'package:adbnerve/adbnerve.dart';

abstract class Updater {
  Updater(this.android) {
    () async {
      await android.runAttach();
    }();
  }

  final Shield android;

  String get package;

  String get heading;

  Future<File?> runGather();

  Future<bool> getRecent() async {
    final command = 'dumpsys package "$package" | grep lastUpdateTime | sed s/.*[=]\\s*// | head -1';
    final scraped = (await android.runInvoke(['shell', command])).stdout.trim();
    if (scraped.toString().isEmpty) return false;
    final results = DateTime.parse(scraped).toLocal();
    final updated = DateTime.now().difference(results).inDays <= 5;
    return updated;
  }

  Future<bool> getSeated() async {
    return await android.getSeated(package);
  }

  Future<void> runRemove() async {
    if (await getSeated() != false) {
      await android.runVanish(package);
    }
  }

  Future<void> runUpdate() async {
    if (await getRecent() == false) {
      final fetched = await runGather();
      if (fetched != null) await android.runUpdate(fetched.path);
    }
  }

  Future<void> setPip({bool enabled = true}) async {
    await android.setPictureInPicture(heading, enabled: enabled);
  }
}
