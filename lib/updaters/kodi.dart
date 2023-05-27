import 'dart:convert';
import 'dart:io';

import 'package:adbnerve/adbnerve.dart';
import 'package:dio/dio.dart';
import 'package:shihogen/updaters/updater.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

class Kodi extends Updater {
  Kodi(super.android);

  @override
  String get package => 'org.xbmc.kodi';

  String get deposit => '/sdcard/Android/data/$package/files/.kodi';

  String get heading => 'Kodi';

  String get release => 'nexus';

  // ...

  @override
  Future<File?> runGather() async {
    throw UnimplementedError();
  }

  @override
  Future<void> runRemove() async {
    await super.runRemove();
    await android.runRemove('/sdcard/Android/data/$package');
  }

  @override
  Future<void> runUpdate() async {
    if (await getRecent()) return;
    final fetched = await runGather();
    if (fetched == null) return;
    await android.runUpdate(fetched.path);
    await setKodiPermissions();
    await android.runLaunch(package);
    await Future.delayed(const Duration(seconds: 10));
    await android.runFinish(package);
    await android.runRepeat('keycode_home');
  }

  ///

  Future<Response> getSetting(String setting) async {
    final results = await setRpc({
      'jsonrpc': '2.0',
      'method': 'Settings.GetSettingValue',
      'params': {'setting': setting},
      'id': 1
    });
    return results;
  }

  Future<void> setSetting(String setting, dynamic payload) async {
    await setRpc({
      'jsonrpc': '2.0',
      'method': 'Settings.SetSettingValue',
      'params': {'setting': setting, 'value': payload},
      'id': 1
    });
  }

  Future<Response<dynamic>> setRpc(Map payload) async {
    final command = ['shell', 'netstat -an | grep 8080 | grep -i listen'];
    final present = (await android.runInvoke(command)).stdout.toString().trim().isNotEmpty;
    if (!present) throw Exception('Instance is not running, please ensure to launch it');

    final address = await android.getIpAddr();
    final results = await Dio().post(
      'http://$address:8080/jsonrpc',
      options: Options(headers: {HttpHeaders.contentTypeHeader: 'application/json'}),
      data: jsonEncode(payload),
    );
    return results;
  }

  Future<void> setXml(String distant, String pattern, String payload, {bool adjunct = true}) async {
    final command = ['shell', 'netstat -an | grep 8080 | grep -i listen'];
    final present = (await android.runInvoke(command)).stdout.toString().trim().isNotEmpty;
    if (present) throw Exception('Instance is running, please ensure to finish it');

    var fetched = await android.runImport(distant);
    if (fetched == null) return;
    var content = XmlDocument.parse(await File(fetched).readAsString());
    content.xpath(pattern).first.innerText = payload;
    if (adjunct) content.xpath(pattern).first.setAttribute('default', 'false');
    await File(fetched).writeAsString(content.toXmlString());
    await android.runExport(fetched, distant);
  }

  ///

  Future<void> setKodiAfr({bool enabled = false}) async {
    await setSetting('videoplayer.adjustrefreshrate', enabled ? 2 : 0);
  }

  Future<void> setKodiAfrDelay({double seconds = 0}) async {
    if (seconds < 0 || seconds > 20) return;
    await setSetting('videoscreen.delayrefreshchange', (seconds * 10).toInt());
  }

  Future<void> setKodiAudioPassthrough({bool enabled = false}) async {
    final payload = enabled ? [true, 10] : [false, 1];
    await setSetting('audiooutput.channels', payload[1]);
    await setSetting('audiooutput.dtshdpassthrough', payload[0]);
    await setSetting('audiooutput.dtspassthrough', payload[0]);
    await setSetting('audiooutput.eac3passthrough', payload[0]);
    await setSetting('audiooutput.passthrough', payload[0]);
    await setSetting('audiooutput.truehdpassthrough', payload[0]);
  }

  Future<void> setKodiLanguageForAudio(String payload) async {
    await setSetting('locale.audiolanguage', payload);
  }

  Future<void> setKodiLanguageForSubtitles(String payload) async {
    await setSetting('locale.subtitlelanguage', payload);
  }

  Future<void> setKodiLanguageListForDownloadedSubtitles(List<String> payload) async {
    await setSetting('subtitles.languages', payload);
  }

  Future<void> setKodiPermissions() async {
    await android.runAccord(package, 'read_external_storage');
    await android.runAccord(package, 'write_external_storage');
    await android.runEscape();
    await android.setLanguage(DeviceLanguage.enUs);
    await android.runReveal(DeviceSetting.tvMainSettings);
    await android.runSelect('//*[@text="Apps"]');
    await android.runSelect('//*[@text="See all apps"]');
    await android.runSelect('//*[@text="$heading"]');
    await android.runSelect('//*[@text="Permissions"]');
    await android.runRepeat('keycode_dpad_down');
    await android.runRepeat('keycode_enter');
    await android.runSelect('//*[@text="Allow all the time"]');
    await android.runRepeat('keycode_tab', repeats: 2);
    await android.runRepeat('keycode_enter');
    await android.runRepeat('keycode_back');
    await android.runRepeat('keycode_tab');
    await android.runRepeat('keycode_enter');
    await android.runSelect('//*[@text="Allow only while using the app"]');
    await android.runRepeat('keycode_home');
  }

  Future<void> setKodiWebserver({bool enabled = false, bool secured = true}) async {
    final distant = '$deposit/userdata/guisettings.xml';
    await setXml(distant, '//*[@id="services.webserver"]', enabled ? 'true' : 'false');
    await setXml(distant, '//*[@id="services.webserverauthentication"]', secured ? 'true' : 'false');
    if (!enabled) return;
    await android.runLaunch(package);
    await android.runLaunch(package);
    final command = ['shell', 'netstat -an | grep 8080 | grep -i listen'];
    while ((await android.runInvoke(command)).stdout.toString().trim().isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
