import 'package:adbnerve/adbnerve.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shihogen/updaters/alauncher.dart';
import 'package:shihogen/updaters/biglybt.dart';
import 'package:shihogen/updaters/kodinerds_nexus.dart';
import 'package:shihogen/updaters/kodinerds_omega.dart';
import 'package:shihogen/updaters/spotify.dart';
import 'package:shihogen/updaters/smarttube_beta.dart';
import 'package:shihogen/widgets/own_appbar.dart';
import 'package:shihogen/widgets/own_header.dart';

class UpdatingView extends ViewWidget<UpdatingViewModel> {
  UpdatingView({super.key}) : super(builder: () => UpdatingViewModel());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: OwnAppBar(
          btnText: 'Done',
          loading: viewModel.loading.value,
          onClick: () async => await viewModel.onDoneClicked(),
        ),
        body: Column(
          children: [
            OwnHeader(
              heading: 'Updating',
              message: viewModel.message.value,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: Text(
                    viewModel.loading.value
                        ? 'The whole process can take a long time, please be patient.'
                        : viewModel.failure.value
                            ? 'The process was interrupted for some reason, sorry for the inconvenience. You can safely close this application.'
                            : viewModel.success.value
                                ? 'Everything went well, enjoy your brand new installation. You can safely close this application.'
                                : '...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 2.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpdatingViewModel extends ViewModel {
  late final SharedPreferences sharing;
  late final loading = createProperty<bool>(false);
  late final failure = createProperty<bool>(false);
  late final success = createProperty<bool>(false);
  late final message = createProperty<String>('Has started, wait');
  late final Shield android;

  @override
  void initState() {
    super.initState();
    () async {
      loading.value = true;
      sharing = await SharedPreferences.getInstance();
      android = Shield(sharing.getString('address')!);
      await android.runAttach();
      await onDoneClicked();
    }();
  }

  Future<void> onDoneClicked() async {
    if (success.value || failure.value) {
      loading.value = true;
      await Navigator.pushNamed(context, '/discover');
      loading.value = false;
    } else {
      try {
        loading.value = true;
        await android.runRepeat('keycode_home');
        await android.runEscape();
        await setAlauncher1();
        await setKodinerdsNexusForFrench();
        await setKodinerdsNexusForEnglish();
        await setSmarttube();
        await setAlauncher2();
        await setShield();
        if (context.mounted) message.value = 'Has succeed, congrats';
        failure.value = false;
        success.value = true;
      } catch (e, stacktrace) {
        debugPrint(stacktrace.toString());
        debugPrint(e.toString());
        if (context.mounted) message.value = 'Has stopped, retry';
        failure.value = true;
        success.value = false;
      } finally {
        loading.value = false;
      }
    }
  }

  ///

  ///

  Future<void> setAlauncher1() async {
    message.value = 'Alauncher package';
    final updater = Alauncher(android);
    await updater.runUpdate();
    await updater.runVanishCategories();
    await updater.getAllBackgrounds();
    await updater.setWallpaper(sharing.getString('picture')!);
  }

  Future<void> setAlauncher2() async {
    message.value = 'Alauncher package';
    final updater = Alauncher(android);

    // Reset the application list
    await android.runFinish(updater.package);
    await android.runLaunch(updater.package);
    await Future.delayed(const Duration(seconds: 10));

    await updater.setCategory('_', 110);
    await updater.setCategory('_', 100);
    await updater.setCategory('_', 100);
    await updater.setApplicationByIndex('Kodinerds', 3);
    // await updater.setApplicationByIndex('Spotify', 3);
    await updater.setApplicationByIndex('SmartTube beta', 3);
    await updater.setApplicationByIndex('Kodinerds Omega', 3);
  }

  Future<void> setKodinerdsNexusForEnglish() async {
    message.value = 'Kodinerds English';
    final package = KodinerdsNexus(android);
    await android.runFinish(package.package);
    final updater = KodinerdsOmega(android);
    // await updater.runRemove();
    await updater.runUpdate();
    await updater.setPip(enabled: false);

    await android.runFinish(updater.package);
    await updater.setEstuaryColor('SKINDEFAULT');
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiAudioPassthrough(enabled: true);
    await updater.setKodiEnableKeymapFix(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);
    await updater.setKodiSettingLevel('3');

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiEnablePreferDefaultAudio(enabled: false);
    await updater.setKodiEnableShowParentFolder(enabled: false);
    await updater.setKodiEnableUpdateFromAnyRepositories(enabled: true);
    await updater.setKodiLanguageForSubtitles('English');
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setUmbrellaAddon();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    final private = sharing.getString('alldebridToken') ?? '';
    if (private.isNotEmpty) await updater.setUmbrellaAlldebridToken(private);
    await updater.setUmbrellaExternalProvider();
    await Future.delayed(const Duration(seconds: 5));

    await updater.setKodiWebserver(enabled: false, secured: true);
  }

  Future<void> setKodinerdsNexusForFrench() async {
    message.value = 'Kodinerds French';
    final package = KodinerdsOmega(android);
    await android.runFinish(package.package);
    final updater = KodinerdsNexus(android);
    // await updater.runRemove();
    await updater.runUpdate();
    await updater.setPip(enabled: false);

    await android.runFinish(updater.package);
    await updater.setEstuaryColor('SKINDEFAULT');
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiAudioPassthrough(enabled: true);
    await updater.setKodiEnableKeymapFix(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);
    await updater.setKodiSettingLevel('3');

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiEnablePreferDefaultAudio(enabled: true);
    await updater.setKodiEnableShowParentFolder(enabled: false);
    await updater.setKodiEnableUpdateFromAnyRepositories(enabled: true);
    await updater.setKodiKeyboardList(['French AZERTY']);
    await updater.setKodiLanguageForAudio('default');
    await updater.setKodiLanguageForSystem('fr_fr');
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setVstreamAddon();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await android.runFinish(updater.package);
    await updater.setVstreamEnableDisplaySeasonTitle(enabled: false);
    await updater.setVstreamEnablePlayNextEpisode(enabled: true);
    await updater.setVstreamEnableWidelistEverywhere(enabled: true);

    final private = sharing.getString('alldebridToken') ?? '';
    if (private.isNotEmpty) await updater.setVstreamAlldebridToken(private);
    await updater.setVstreamPastebinCodes();
    await updater.setVstreamPastebinUrl();

    await updater.setKodiWebserver(enabled: false, secured: true);
  }

  Future<void> setShield() async {
    message.value = 'Shield settings';
    await android.setBloatware(enabled: false);
    await android.setResolution(ShieldResolution.p2160DolbyHz59);
    await android.setUpscaling(ShieldUpscaling.enhanced);
    await android.setLanguage(DeviceLanguage.frFr);
    await android.runReboot();
  }

  Future<void> setSmarttube() async {
    message.value = 'SmartTube package';
    final updater = SmarttubeBeta(android);
    // await updater.runRemove();
    await updater.runUpdate();
    await updater.setPip(enabled: false);
  }

  /// TODO: Remove the following.

  Future<String?> getStorage() async {
    await Future.delayed(const Duration(seconds: 5));
    final results = await android.runSearch('/storage/*', maximum: 10);
    // if (results == null) throw Exception('External storage is required');
    if (results == null) return null;
    final storage = results.where((x) => !x.contains('emulated') && !x.contains('self') && !x.contains('Storage')).firstOrNull;
    // if (storage == null) throw Exception('External storage is required');
    if (storage == null) return null;
    return storage;
  }

  Future<void> setBiglybt() async {
    final storage = await getStorage();
    if (storage == null) return;
    message.value = 'Updating BiglyBT';
    await android.runInvoke(['shell', 'mkdir -p "$storage/Movies"']);
    await android.runInvoke(['shell', 'mkdir -p "$storage/Series"']);
    await android.runInvoke(['shell', 'mkdir -p "$storage/Shared"']);
    final updater = Biglybt(android);
    await updater.runRemove();
    await updater.runUpdate();
  }

  Future<void> setKodinerdsNexusForLocalOnly() async {
    message.value = 'Kodinerds Nexus package';
    final package = KodinerdsOmega(android);
    await android.runFinish(package.package);
    final updater = KodinerdsNexus(android);
    await updater.runRemove();
    await updater.runUpdate();
    await updater.setPip(enabled: false);

    await android.runFinish(updater.package);
    await updater.setEstuaryColor('SKINDEFAULT');
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiAudioPassthrough(enabled: true);
    await updater.setKodiEnableKeymapFix(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);
    await updater.setKodiSettingLevel('3');
    await updater.setKodiSmartPlaylistForAnimesOnly();
    await updater.setKodiSmartPlaylistForSeriesOnly();

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiEnablePreferDefaultAudio(enabled: true);
    await updater.setKodiEnableShowParentFolder(enabled: false);
    await updater.setKodiEnableUpdateFromAnyRepositories(enabled: true);
    await updater.setKodiKeyboardList(['French AZERTY']);
    // await updater.setKodiLanguageForAudio('default');
    // await updater.setKodiLanguageForSubtitles('default');
    await updater.setKodiLanguageForSystem('fr_fr');
    await updater.setKodiSubtitleBorderSize(payload: 50);
    await updater.setKodiSubtitleColor(payload:"FFFEFE22");
    await updater.setKodiSubtitleServiceForMovies('');
    await updater.setKodiSubtitleServiceForSeries('');
    await updater.setKodiTvShowSelectFirstUnwatchedItem(enabled: true);
    await updater.setLocalFavourites();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await updater.setKodiWebserver(enabled: false, secured: true);
  }

  Future<void> setKodinerdsNexus() async {
    message.value = 'Kodinerds Nexus package';
    final package = KodinerdsOmega(android);
    await android.runFinish(package.package);

    final updater = KodinerdsNexus(android);
    // await updater.runRemove();
    await updater.runUpdate();
    await updater.setPip(enabled: false);

    await android.runFinish(updater.package);
    await updater.setEstuaryColor('SKINDEFAULT');
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiAudioPassthrough(enabled: true);
    await updater.setKodiEnableKeymapFix(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);
    await updater.setKodiSettingLevel('3');

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiEnablePreferDefaultAudio(enabled: true);
    await updater.setKodiEnableShowParentFolder(enabled: false);
    await updater.setKodiEnableUpdateFromAnyRepositories(enabled: true);
    await updater.setKodiKeyboardList(['French AZERTY']);
    await updater.setKodiLanguageForAudio('default');
    // await updater.setKodiLanguageForSubtitles('forced_only');
    await updater.setKodiLanguageForSystem('fr_fr');
    // await updater.setKodiLanguageListForDownloadedSubtitles(['English']);
    // await updater.setKodiSubtitleServiceForMovies('');
    // await updater.setKodiSubtitleServiceForSeries('');
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setVstreamAddon();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await android.runFinish(updater.package);
    // await updater.setVstreamEnableActivateSubtitles(enabled: true);
    await updater.setVstreamEnableDisplaySeasonTitle(enabled: false);
    await updater.setVstreamEnablePlayNextEpisode(enabled: true);
    await updater.setVstreamEnableWidelistEverywhere(enabled: true);

    final private = sharing.getString('alldebridToken') ?? '';
    if (private.isNotEmpty) await updater.setVstreamAlldebridToken(private);
    await updater.setVstreamPastebinCodes();
    await updater.setVstreamPastebinUrl();

    await updater.setKodiWebserver(enabled: false, secured: true);
  }

  Future<void> setKodinerdsOmega() async {
    message.value = 'Kodinerds Omega package';
    final package = KodinerdsNexus(android);
    await android.runFinish(package.package);
    final updater = KodinerdsOmega(android);
    // await updater.runRemove();
    await updater.runUpdate();
    await updater.setPip(enabled: false);

    await android.runFinish(updater.package);
    await updater.setEstuaryColor('SKINDEFAULT');
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiAudioPassthrough(enabled: true);
    await updater.setKodiEnableKeymapFix(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);
    await updater.setKodiSettingLevel('3');

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiEnablePreferDefaultAudio(enabled: false);
    await updater.setKodiEnableShowParentFolder(enabled: false);
    await updater.setKodiEnableUpdateFromAnyRepositories(enabled: true);
    await updater.setKodiKeyboardList(['French AZERTY']);
    await updater.setKodiLanguageForAudio('English');
    await updater.setKodiLanguageForSubtitles('French');
    await updater.setKodiLanguageForSystem('fr_fr');
    await updater.setKodiLanguageListForDownloadedSubtitles(['French']);
    await updater.setKodiSubtitleServiceForMovies('service.subtitles.a4ksubtitles');
    await updater.setKodiSubtitleServiceForSeries('service.subtitles.a4ksubtitles');
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setA4ksubtitlesAddon();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));

    await android.runFinish(updater.package);
    await updater.setA4ksubtitlesEnableAutoDownload(enabled: true);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setFenAddon();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await updater.setKodiWebserver(enabled: true, secured: false);
    final private = (username: sharing.getString('realdebridUsername') ?? '', password: sharing.getString('realdebridPassword') ?? '');
    if (private.username.isNotEmpty && private.password.isNotEmpty) await updater.setFenPairForRealdebrid(private);
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));

    await android.runFinish(updater.package);
    await updater.setFenMetadataLanguage('French', 'fr');

    await updater.setKodiWebserver(enabled: false, secured: true);
  }

  Future<void> setKodinerdsOmegaForFenUmbrella() async {
    message.value = 'Kodinerds Omega package';
    final package = KodinerdsNexus(android);
    await android.runFinish(package.package);
    final updater = KodinerdsOmega(android);
    await updater.runRemove();
    await updater.runUpdate();
    await updater.setPip(enabled: false);

    await android.runFinish(updater.package);
    await updater.setEstuaryColor('SKINDEFAULT');
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiAudioPassthrough(enabled: true);
    await updater.setKodiEnableKeymapFix(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);
    await updater.setKodiSettingLevel('3');

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiEnablePreferDefaultAudio(enabled: false);
    await updater.setKodiEnableShowParentFolder(enabled: false);
    await updater.setKodiEnableUpdateFromAnyRepositories(enabled: true);
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    // UMBRELLA

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setUmbrellaAddon();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    // await updater.setKodiWebserver(enabled: true, secured: false);
    final private = sharing.getString('alldebridToken') ?? '';
    if (private.isNotEmpty) await updater.setUmbrellaAlldebridToken(private);
    await updater.setUmbrellaExternalProvider();
    // await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    // await android.runFinish(updater.package);

    // FEN

    // await updater.setKodiWebserver(enabled: true, secured: false);
    // await updater.setFenAddon();
    // await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    // await Future.delayed(const Duration(seconds: 5));
    // await android.runFinish(updater.package);
    //
    // // await updater.setKodiWebserver(enabled: true, secured: false);
    // // final private = sharing.getString('alldebridToken') ?? '';
    // // if (private.isNotEmpty) await updater.setUmbrellaAlldebridToken(private);
    // await updater.setFenExternalScraper();
    // // await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    // await Future.delayed(const Duration(seconds: 5));

    await updater.setKodiWebserver(enabled: false, secured: true);
  }

  Future<void> setSpotify() async {
    message.value = 'Spotify package';
    final updater = Spotify(android);
    // await updater.runRemove();
    await updater.runUpdate();
  }
}
