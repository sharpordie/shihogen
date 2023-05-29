import 'dart:convert';
import 'dart:io';

import 'package:adbnerve/adbnerve.dart';
import 'package:dedent/dedent.dart';
import 'package:dio/dio.dart';
import 'package:netnerve/netnerve.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  // Future<Response> getKodiFavouriteList() async {
  //   return await setRpc({
  //     'jsonrpc': '2.0',
  //     'method': 'Favourites.GetFavourites',
  //     'params': {
  //       'properties': ['window', 'path', 'thumbnail', 'windowparameter']
  //     },
  //     'id': 1
  //   });
  // }

  Future<bool> hasKodiAddon(String payload) async {
    final command = ['shell', 'test -d "$deposit/addons/$payload"'];
    return (await android.runInvoke(command)).exitCode == 0;
  }

  Future<void> setKodiAddonEnabled(String payload, {bool enabled = true}) async {
    await setRpc({
      'jsonrpc': '2.0',
      'method': 'Addons.SetAddonEnabled',
      'params': {'addonid': payload, 'enabled': enabled ? true : false},
      'id': 1
    });
  }

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

  Future<void> setKodiDependency(String payload, {bool imposed = false}) async {
    final present = await hasKodiAddon(payload);
    if (!imposed && present) return;
    final fetcher = Dio()
      ..options.followRedirects = true
      ..options.headers = {'user-agent': 'mozilla/5.0'};
    final baseurl = 'https://mirrors.kodi.tv/addons/$release';
    final website = '$baseurl/$payload/?C=M&O=D';
    final pattern = RegExp('href="$payload-(.*)(?=.zip" )');
    final content = await (await fetcher.get(website)).data;
    final version = pattern.allMatches(content).last.group(1);
    final address = '$baseurl/$payload/$payload-$version.zip';
    final archive = await getFromAddress(address);
    await android.runUnpack(archive!.path, '$deposit/addons');
  }

  Future<void> setKodiEnablePreferDefaultAudio({bool enabled = false}) async {
    await setSetting('videoplayer.preferdefaultflag', enabled ? true : false);
  }

  Future<void> setKodiEnableShowParentFolder({bool enabled = false}) async {
    await setSetting('filelists.showparentdiritems', enabled ? true : false);
  }

  Future<void> setKodiEnableUnknownSources({bool enabled = false}) async {
    // await setSetting('addons.unknownsources', enabled ? true : false);
    final distant = '$deposit/userdata/guisettings.xml';
    await setXml(distant, '//*[@id="addons.unknownsources"]', enabled ? 'true' : 'false');
  }

  Future<void> setKodiEnableUpdateFromAnyRepositories({bool enabled = false}) async {
    await setSetting('addons.updatemode', enabled ? 1 : 0);
  }

  Future<void> setKodiFavourite(String heading, String variant, String starter, String? picture) async {
    await setRpc({
      'jsonrpc': '2.0',
      'method': 'Favourites.AddFavourite',
      'params': {
        'title': heading,
        'type': 'window',
        'window': variant,
        'windowparameter': starter,
        'thumbnail': picture ?? '',
      },
      'id': 1
    });
  }

  Future<void> setKodiKeyboardList(List<String> payload) async {
    await setSetting('locale.keyboardlayouts', payload);
    await setSetting('locale.activekeyboardlayout', payload);
  }

  Future<void> setKodiLanguageForAudio(String payload) async {
    await setSetting('locale.audiolanguage', payload);
  }

  Future<void> setKodiLanguageForSubtitles(String payload) async {
    await setSetting('locale.subtitlelanguage', payload);
  }

  Future<void> setKodiLanguageForSystem(String payload) async {
    await setKodiDependency('resource.language.$payload');
    await setSetting('locale.language', 'resource.language.$payload');
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

  Future<void> setKodiSubtitleServiceForMovies(String payload) async {
    await setSetting('subtitles.movie', payload);
  }

  Future<void> setKodiSubtitleServiceForSeries(String payload) async {
    await setSetting('subtitles.tv', payload);
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

  ///

  Future<void> setEstuaryMenuList({bool enabled = true}) async {
    await setEstuaryFavourites(enabled: enabled);
    await setEstuaryGames(enabled: enabled);
    await setEstuaryMovie(enabled: enabled);
    await setEstuaryMusic(enabled: enabled);
    await setEstuaryMusicVideo(enabled: enabled);
    await setEstuaryPictures(enabled: enabled);
    await setEstuaryPrograms(enabled: enabled);
    await setEstuaryRadio(enabled: enabled);
    await setEstuaryTv(enabled: enabled);
    await setEstuaryTvShow(enabled: enabled);
    await setEstuaryVideos(enabled: enabled);
    await setEstuaryWeather(enabled: enabled);
  }

  Future<void> setEstuaryMenu(String payload, {bool enabled = true}) async {
    payload = payload.replaceFirst('homemenuno', '');
    final distant = '$deposit/userdata/addon_data/skin.estuary/settings.xml';
    await setXml(distant, '//*[@id="homemenuno$payload"]', (!enabled).toString());
  }

  Future<void> setEstuaryFavourites({bool enabled = true}) async {
    await setEstuaryMenu('favbutton', enabled: enabled);
  }

  Future<void> setEstuaryGames({bool enabled = true}) async {
    await setEstuaryMenu('gamesbutton', enabled: enabled);
  }

  Future<void> setEstuaryMovie({bool enabled = true}) async {
    await setEstuaryMenu('moviebutton', enabled: enabled);
  }

  Future<void> setEstuaryMusic({bool enabled = true}) async {
    await setEstuaryMenu('musicbutton', enabled: enabled);
  }

  Future<void> setEstuaryMusicVideo({bool enabled = true}) async {
    await setEstuaryMenu('musicvideobutton', enabled: enabled);
  }

  Future<void> setEstuaryPictures({bool enabled = true}) async {
    await setEstuaryMenu('picturesbutton', enabled: enabled);
  }

  Future<void> setEstuaryPrograms({bool enabled = true}) async {
    await setEstuaryMenu('programsbutton', enabled: enabled);
  }

  Future<void> setEstuaryRadio({bool enabled = true}) async {
    await setEstuaryMenu('radiobutton', enabled: enabled);
  }

  Future<void> setEstuaryTv({bool enabled = true}) async {
    await setEstuaryMenu('tvbutton', enabled: enabled);
  }

  Future<void> setEstuaryTvShow({bool enabled = true}) async {
    await setEstuaryMenu('tvshowbutton', enabled: enabled);
  }

  Future<void> setEstuaryVideos({bool enabled = true}) async {
    await setEstuaryMenu('videosbutton', enabled: enabled);
  }

  Future<void> setEstuaryWeather({bool enabled = true}) async {
    await setEstuaryMenu('weatherbutton', enabled: enabled);
  }

  ///

  Future<void> setA4ksubtitlesAddon() async {
    const payload = 'service.subtitles.a4ksubtitles';
    if (await hasKodiAddon(payload)) return;
    await setA4ksubtitlesAddonDependencies();
    await setA4ksubtitlesAddonRepository();
    final fetcher = Dio()
      ..options.followRedirects = true
      ..options.headers = {'user-agent': 'mozilla/5.0'};
    const website = 'https://api.github.com/repos/a4k-openproject/a4kSubtitles/releases/latest';
    final content = await (await fetcher.get(website)).data;
    final version = content['name'].toString().replaceFirst('v', '');
    final address = 'https://github.com/a4k-openproject/a4kSubtitles/archive/refs/tags/$payload/$payload-$version.zip';
    final archive = await getFromAddress(address);
    await android.runUnpack(archive!.path, '$deposit/addons');
    final results = await android.runSearch('$deposit/addons/a4kSubtitles-service*');
    final command = ['shell', 'mv ${results![0]} $deposit/addons/$payload'];
    await android.runInvoke(command);
    await setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(package);
    await setKodiWebserver(enabled: true, secured: false);
    await setKodiAddonEnabled(payload, enabled: true);
    await Future.delayed(const Duration(seconds: 5));
    await android.runRepeat('keycode_home');
  }

  Future<void> setA4ksubtitlesDefaults() async {
    await android.runFinish(package);
    final distant = '$deposit/userdata/addon_data/service.subtitles.a4ksubtitles/settings.xml';
    final configs = File(p.join((await getTemporaryDirectory()).path, 'settings.xml'));
    await configs.writeAsString(dedent('''
      <settings version="2">
          <setting id="general.timeout">15</setting>
          <setting id="general.results_limit">20</setting>
          <setting id="general.auto_search" default="true">false</setting>
          <setting id="general.auto_download" default="true">false</setting>
          <setting id="general.use_chardet">true</setting>
          <setting id="addic7ed.enabled">true</setting>
          <setting id="bsplayer.enabled">true</setting>
          <setting id="opensubtitles.enabled">true</setting>
          <setting id="podnadpisi.enabled">true</setting>
          <setting id="subscene.enabled">true</setting>
          <setting id="opensubtitles.username" default="true" />
          <setting id="opensubtitles.password" default="true" />
      </settings>
    '''));
    await android.runExport(configs.path, distant);
  }

  Future<void> setA4ksubtitlesAddonDependencies() async {
    await setKodiDependency('script.module.certifi');
    await setKodiDependency('script.module.chardet');
    await setKodiDependency('script.module.idna');
    await setKodiDependency('script.module.requests');
    await setKodiDependency('script.module.urllib3');
  }

  Future<void> setA4ksubtitlesAddonRepository() async {
    const payload = 'repository.a4ksubtitles';
    if (await hasKodiAddon(payload)) return;
    var baseurl = 'https://a4k-openproject.github.io/a4kSubtitles/packages';
    var address = '$baseurl/a4kSubtitles-repository.zip';
    var archive = await getFromAddress(address);
    await android.runUnpack(archive!.path, '$deposit/addons');
    final results = await android.runSearch('$deposit/addons/a4kSubtitles-repository*');
    final command = ['shell', 'mv ${results![0]} $deposit/addons/$payload'];
    await android.runInvoke(command);
    await setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(package);
    await setKodiWebserver(enabled: true, secured: false);
    await setKodiAddonEnabled(payload, enabled: true);
    await android.runRepeat('keycode_home');
  }

  Future<void> setA4ksubtitlesEnableAutoDownload({bool enabled = false}) async {
    final distant = '$deposit/userdata/addon_data/service.subtitles.a4ksubtitles/settings.xml';
    final present = (await android.runInvoke(['shell', 'test -d "$distant"'])).exitCode == 0;
    if (!present) await setA4ksubtitlesDefaults();
    await setXml(distant, '//*[@id="general.auto_search"]', enabled ? 'true' : 'false', adjunct: false);
    await setXml(distant, '//*[@id="general.auto_download"]', enabled ? 'true' : 'false', adjunct: false);
  }

  ///

  Future<void> setFenAddon() async {
    var payload = 'plugin.video.fen';
    if (await hasKodiAddon(payload)) return;
    await setFenAddonDependencies();
    await setFenAddonRepository();
    final fetcher = Dio()
      ..options.followRedirects = true
      ..options.headers = {'user-agent': 'mozilla/5.0'};
    var baseurl = 'https://github.com/Tikipeter/repository.tikipeter';
    var website = '$baseurl/tree/main/zips/plugin.video.fen';
    var pattern = RegExp('title="plugin.video.fen-([\\d.]+).zip"');
    var content = await (await fetcher.get(website)).data;
    var version = pattern.allMatches(content).last.group(1);
    var address = '$baseurl/raw/main/zips/plugin.video.fen/plugin.video.fen-$version.zip';
    var archive = await getFromAddress(address);
    await android.runUnpack(archive!.path, '$deposit/addons');
    await setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(package);
    await setKodiWebserver(enabled: true, secured: false);
    await setKodiAddonEnabled(payload, enabled: true);
    await setFenFavourites();
    payload = 'script.module.cocoscrapers';
    baseurl = 'https://github.com/CocoJoe2411/repository.cocoscrapers';
    website = '$baseurl/tree/main/zips/script.module.cocoscrapers';
    pattern = RegExp('title="script.module.cocoscrapers-([\\d.]+).zip"');
    content = await (await fetcher.get(website)).data;
    version = pattern.allMatches(content).last.group(1);
    address = '$baseurl/raw/main/zips/script.module.cocoscrapers/script.module.cocoscrapers-$version.zip';
    archive = await getFromAddress(address);
    await android.runUnpack(archive!.path, '$deposit/addons');
    await setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(package);
    await setKodiWebserver(enabled: true, secured: false);
    await setKodiAddonEnabled(payload, enabled: true);
    await android.runRepeat('keycode_home');
  }

  Future<void> setFenAddonDependencies() async {
    await setKodiDependency('script.module.certifi');
    await setKodiDependency('script.module.chardet');
    await setKodiDependency('script.module.idna');
    await setKodiDependency('script.module.requests');
    await setKodiDependency('script.module.urllib3');
  }

  Future<void> setFenAddonRepository() async {
    const payload = 'repository.tikipeter';
    if (await hasKodiAddon(payload)) return;
    final fetcher = Dio()
      ..options.followRedirects = true
      ..options.headers = {'user-agent': 'mozilla/5.0'};
    var website = 'https://tikipeter.github.io';
    var pattern = RegExp('href="repository.tikipeter-([\\d.]+).zip"');
    var content = await (await fetcher.get(website)).data;
    var version = pattern.firstMatch(content)?.group(1);
    var address = '$website/repository.tikipeter-$version.zip';
    var archive = await getFromAddress(address);
    await android.runUnpack(archive!.path, '$deposit/addons');
    await setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(package);
    await setKodiWebserver(enabled: true, secured: false);
    await setKodiAddonEnabled(payload, enabled: true);
    await android.runRepeat('keycode_home');
  }

  Future<void> setFenFavourites() async {
    var adjunct = 'plugin://plugin.video.fen';
    var picture = '$deposit/addons/plugin.video.fen/resources/media/fen_icon.png';
    await setKodiFavourite('Fen', 'videos', adjunct, picture);
  }

  Future<void> setFenMetadataLanguage(String payload, String compact) async {
    final distant = '$deposit/userdata/addon_data/plugin.video.fen/settings.xml';
    await setXml(distant, '//*[@id="meta_language_display"]', payload);
    await setXml(distant, '//*[@id="meta_language"]', compact);
  }

  Future<void> setFenPairForRealdebrid(({String username, String password}) private) async {
    await setRpc({
      'jsonrpc': '2.0',
      'method': 'Addons.ExecuteAddon',
      'params': {
        'addonid': 'plugin.video.fen',
        'params': {'mode': 'real_debrid.authenticate'}
      },
      'id': 0
    });
    await Future.delayed(const Duration(seconds: 8));
    final pattern = RegExp('Enter the following code: (.*)');
    final picture = await android.runScreen();
    final matches = await android.runLookup(File(picture!), pattern);
    if (matches != null) {
      final pincode = matches.first.group(1).toString().replaceAll(' ', '');
      await setPairForRealdebrid(private, pincode);
      await Future.delayed(const Duration(seconds: 8));
    }
  }

  Future<void> setFenPairForTrakt((String, String) private) async {}

  ///

  Future<void> setVstreamAddon() async {
    var payload = 'plugin.video.vstream';
    if (await hasKodiAddon(payload)) return;
    await setVstreamAddonDependencies();
    await setVstreamAddonRepository();
    const address = 'https://api.github.com/repos/Kodi-vStream/venom-xbmc-addons/releases/latest';
    final archive = await getFromGithub(address, RegExp('.*.zip'));
    await android.runUnpack(archive!.path, '$deposit/addons');
    await setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(package);
    await setKodiWebserver(enabled: true, secured: false);
    await setKodiAddonEnabled(payload, enabled: true);
    await setVstreamFavourites();
    await android.runRepeat('keycode_home');
  }

  Future<void> setVstreamAddonDependencies() async {
    await setKodiDependency('script.module.certifi');
    await setKodiDependency('script.module.chardet');
    await setKodiDependency('script.module.idna');
    await setKodiDependency('script.module.pyqrcode');
    await setKodiDependency('script.module.requests');
    await setKodiDependency('script.module.urllib3');
  }

  Future<void> setVstreamAddonRepository() async {
    const payload = 'repository.vstream';
    if (await hasKodiAddon(payload)) return;
    final fetcher = Dio()
      ..options.followRedirects = true
      ..options.headers = {'user-agent': 'mozilla/5.0'};
    const website = 'https://kodi-vstream.github.io/repo';
    final pattern = RegExp('href="repository.vstream-([\\d.]+).zip"');
    final content = await (await fetcher.get(website)).data;
    final version = pattern.allMatches(content).last.group(1);
    var address = '$website/repository.vstream-$version.zip';
    var archive = await getFromAddress(address);
    await android.runUnpack(archive!.path, '$deposit/addons');
    await setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(package);
    await setKodiWebserver(enabled: true, secured: false);
    await setKodiAddonEnabled(payload, enabled: true);
    await android.runRepeat('keycode_home');
  }

  Future<void> setVstreamEnableActivateSubtitles({bool enabled = false}) async {
    final distant = '$deposit/userdata/addon_data/plugin.video.vstream/settings.xml';
    await setXml(distant, '//*[@id="srt-view"]', enabled ? 'true' : 'false', adjunct: false);
  }

  Future<void> setVstreamEnableDisplaySeasonTitle({bool enabled = false}) async {
    final distant = '$deposit/userdata/addon_data/plugin.video.vstream/settings.xml';
    await setXml(distant, '//*[@id="display_season_title"]', enabled ? 'true' : 'false');
  }

  Future<void> setVstreamEnablePlayNextEpisode({bool enabled = false}) async {
    if (enabled) await setKodiDependency('service.upnext');
    final distant = '$deposit/userdata/addon_data/plugin.video.vstream/settings.xml';
    await setXml(distant, '//*[@id="upnext"]', enabled ? 'true' : 'false', adjunct: false);
  }

  Future<void> setVstreamEnableWidelistEverywhere({bool enabled = false}) async {
    final distant = '$deposit/userdata/addon_data/plugin.video.vstream/settings.xml';
    await setXml(distant, '//*[@id="active-view"]', enabled ? 'true' : 'false');
    await setXml(distant, '//*[@id="accueil-view"]', enabled ? '55' : '500', adjunct: false);
    await setXml(distant, '//*[@id="default-view"]', enabled ? '55' : '50', adjunct: false);
    await setXml(distant, '//*[@id="episodes-view"]', enabled ? '55' : '500', adjunct: false);
    await setXml(distant, '//*[@id="movies-view"]', enabled ? '55' : '500', adjunct: false);
    await setXml(distant, '//*[@id="seasons-view"]', enabled ? '55' : '500', adjunct: false);
    await setXml(distant, '//*[@id="tvshows-view"]', enabled ? '55' : '500', adjunct: false);
    await setXml(distant, '//*[@id="visuel-view"]', enabled ? '55' : '500', adjunct: false);
  }

  Future<void> setVstreamFavourites() async {
    var adjunct = 'plugin://plugin.video.vstream/?function=showMenuFilms&sFav=showMenuFilms&site=pastebin&siteUrl=https://pastebin.com/raw/&numPage=1&sMedia=film&title=Films';
    var picture = '$deposit/addons/plugin.video.vstream/resources/art/films.png';
    await setKodiFavourite('Films', 'videos', adjunct, picture);
    adjunct = 'plugin://plugin.video.vstream/?function=showMenuTvShows&sFav=showMenuTvShows&site=pastebin&title=Séries';
    picture = '$deposit/addons/plugin.video.vstream/resources/art/series.png';
    await setKodiFavourite('Séries', 'videos', adjunct, picture);
    adjunct = 'plugin://plugin.video.vstream/?function=showMenuMangas&sFav=showMenuMangas&site=pastebin&title=Animes';
    picture = '$deposit/addons/plugin.video.vstream/resources/art/animes.png';
    await setKodiFavourite('Animes', 'videos', adjunct, picture);
  }

  Future<void> setVstreamPairForRealdebrid(({String username, String password}) private) async {
    final payload = await getTokenForRealdebrid(private);
    if (payload == null) return;
    final distant = '$deposit/userdata/addon_data/plugin.video.vstream/settings.xml';
    await setXml(distant, '//*[@id="hoster_realdebrid_premium"]', 'true');
    await setXml(distant, '//*[@id="hoster_realdebrid_token"]', payload);
  }

  Future<void> setVstreamPairForTrakt((String, String) private) async {}

  Future<void> setVstreamPastebinCodes() async {
    final distant = '$deposit/userdata/addon_data/plugin.video.vstream/settings.xml';
    var fetched = await android.runImport(distant);
    if (fetched == null) return;
    var content = XmlDocument.parse(await File(fetched).readAsString());
    final factors = [
      ['pastebin_label_1', 'ANIMES'],
      ['pastebin_id_1', 'oil7fmFZ8'],
      ['pastebin_label_2', 'CARTOONS'],
      ['pastebin_id_2', 'hr2TRGkt4'],
      ['pastebin_label_3', 'CONCERTS'],
      ['pastebin_id_3', 'B4oyP1nPe'],
      ['pastebin_label_4', 'DOCUMENTARIES'],
      ['pastebin_id_4', '8PMoBQaj4'],
      ['pastebin_label_5', 'MOVIES'],
      ['pastebin_id_5', 'BeiPlyWEc'],
      ['pastebin_label_6', 'SERIES'],
      ['pastebin_id_6', 'euqrrb8Db'],
      ['pastebin_label_7', 'SPECTACLES'],
      ['pastebin_id_7', 'WjhMJHje5'],
    ];
    for (final element in factors) {
      if (content.xpath('//*[@id="${element[0]}"]').isEmpty) {
        final builder = XmlBuilder();
        builder.element('setting', nest: () {
          builder.attribute('id', element[0]);
          builder.text(element[1]);
        });
        content.document?.firstChild?.children.add(builder.buildDocument().firstChild!.copy());
      }
    }
    await File(fetched).writeAsString(content.toXmlString());
    await android.runExport(fetched, distant);
  }
}
