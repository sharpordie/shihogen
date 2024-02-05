import 'dart:io';

import 'package:adbnerve/adbnerve.dart';
import 'package:netnerve/netnerve.dart';
import 'package:path/path.dart';
import 'package:shihogen/updaters/updater.dart';
import 'package:shihogen/views/launcher.dart';

class Alauncher extends Updater {
  Alauncher(super.android);

  @override
  String get package => 'org.mywire.alauncher';

  @override
  String get heading => 'aLauncher';

  @override
  Future<File?> runGather() async {
    const address = 'https://api.github.com/repos/4v3ngR/aLauncher/releases/latest';
    return await getFromGithub(address, RegExp('arm64-v8a-release.apk'));
  }

  @override
  Future<void> runUpdate() async {
    if (await getRecent() == true) return;
    await runRemove();
    final fetched = await runGather();
    if (fetched == null) return;
    await android.runUpdate(fetched.path);
    await android.runAccord(package, 'read_external_storage');
    await android.runAccord(package, 'write_external_storage');
    await android.runEnable('com.google.android.leanbacklauncher.recommendations', enabled: false);
    await android.runEnable('com.google.android.leanbacklauncher', enabled: false);
    await android.runEnable('com.google.android.tvlauncher', enabled: false);
    await android.runEnable('com.google.android.tvrecommendations', enabled: false);
    await android.runRepeat('keycode_home');
    final visible = await android.runSelect('//*[@text="aLauncher"]');
    if (visible) {
      await android.runRepeat('keycode_dpad_down', repeats: 99);
      await android.runRepeat('keycode_dpad_right', repeats: 99);
      await android.runRepeat('keycode_enter');
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> getAllBackgrounds() async {
    for (final picture in LauncherViewModel().pictureItems) {
      final address = 'https://www.themoviedb.org/t/p/original/$picture.jpg';
      final fetched = await getFromAddress(address);
      if (fetched == null) continue;
      await Future.delayed(const Duration(seconds: 2));
      await android.runExport(fetched.path, '/sdcard/Download');
    }
  }

  Future<void> runRevealSettings() async {
    await android.runRepeat('keycode_dpad_up', repeats: 99);
    await android.runRepeat('keycode_enter');
  }

  Future<void> runVanishCategories() async {
    await android.runEscape();
    await android.setLanguage(DeviceLanguage.enUs);
    await runRevealSettings();
    await android.runSelect('//*[@content-desc="Categories"]');
    final element = await android.runScrape('//*[@content-desc="Add Category"]/parent::*');
    var counter = element?.children[1].children.length;
    if (counter != null) {
      while (counter! > 0) {
        await android.runRepeat('keycode_dpad_up', repeats: counter * 2);
        await android.runRepeat('keycode_dpad_right', repeats: 9);
        await android.runRepeat('keycode_enter');
        await android.runRepeat('keycode_dpad_down', repeats: 9);
        await android.runRepeat('keycode_enter');
        await android.runRepeat('keycode_back', repeats: 2);
        await runRevealSettings();
        await android.runSelect('//*[@content-desc="Categories"]');
        counter -= 1;
      }
    }
    await android.runRepeat('keycode_back', repeats: 2);
  }

  Future<void> setCategory(String payload, int bigness) async {
    if (![80, 90, 100, 110, 120, 130, 140, 150].contains(bigness)) return;
    await android.runEscape();
    await android.setLanguage(DeviceLanguage.enUs);
    await runRevealSettings();
    await android.runSelect('//*[@content-desc="Categories"]');
    await android.runSelect('//*[@content-desc="Add Category"]');
    await Future.delayed(const Duration(seconds: 2)); // TODO: Maybe add this inside adbnerve
    await android.runInsert(payload);
    await android.runRepeat('keycode_enter');
    await android.runRepeat('keycode_dpad_up', repeats: 99);
    await android.runRepeat('keycode_dpad_right', repeats: 9);
    await android.runRepeat('keycode_enter');
    await android.runRepeat('keycode_dpad_down', repeats: 4);
    await android.runRepeat('keycode_enter');
    await android.runSelect('//*[@content-desc="${bigness.toString()}"]');
    await android.runRepeat('keycode_back', repeats: 3);
  }

  Future<void> setApplicationByIndex(String payload, int section, {bool adapted = true}) async {
    await android.runEscape();
    await android.setLanguage(DeviceLanguage.enUs);
    await runRevealSettings();
    await android.runSelect('//*[@content-desc="Applications"]');
    if (!adapted) await android.runSelect('//*[@content-desc="Tab 2 of 3"]');
    await android.runSelect('//*[@content-desc="$payload"]/node[1]');
    await android.runRepeat('keycode_dpad_up', repeats: 99);
    await android.runRepeat('keycode_dpad_down', repeats: section - 1);
    await android.runRepeat('keycode_enter');
    await android.runRepeat('keycode_back', repeats: 2);
  }

  Future<void> setApplicationByTitle(String payload, String section, {bool adapted = true}) async {
    await android.runEscape();
    await android.setLanguage(DeviceLanguage.enUs);
    await runRevealSettings();
    await android.runSelect('//*[@content-desc="Applications"]');
    if (!adapted) await android.runSelect('//*[@content-desc="Tab 2 of 3"]');
    await android.runSelect('//*[@content-desc="$payload"]/node[1]');
    await android.runSelect('//*[@content-desc="$section"]');
    await android.runRepeat('keycode_back', repeats: 2);
  }

  Future<void> setWallpaper(String payload) async {
    await android.runEscape();
    await android.setLanguage(DeviceLanguage.enUs);
    await runRevealSettings();
    await android.runEnable('com.android.documentsui', enabled: true);
    await android.runSelect('//*[@content-desc="Wallpaper"]');
    await android.runSelect('//*[@content-desc="Custom"]');
    final fetched = await getFromAddress(payload);
    if (fetched == null) return;
    await android.runExport(fetched.path, '/sdcard/Download');
    await android.runSelect('//*[@content-desc="Show roots"]');
    await android.runRepeat('keycode_dpad_down', repeats: 2);
    await android.runRepeat('keycode_enter');
    await android.runSelect('//*[@content-desc="Search"]');
    await Future.delayed(const Duration(seconds: 2));
    await android.runInsert(basename(fetched.path));
    await Future.delayed(const Duration(seconds: 2));
    await android.runRepeat('keycode_enter');
    await Future.delayed(const Duration(seconds: 2));
    await android.runRepeat('keycode_enter');
    await Future.delayed(const Duration(seconds: 4));
    await android.runRepeat('keycode_back', repeats: 2);
  }
}
