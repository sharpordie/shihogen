import 'package:adbnerve/adbnerve.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shihogen/updaters/alauncher.dart';
import 'package:shihogen/updaters/kodinerds_nexus.dart';
import 'package:shihogen/updaters/kodinerds_omega.dart';
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
  late final message = createProperty<String>('In progress');
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
        await setAlauncher1();
        await setKodinerdsNexus();
        await setKodinerdsOmega();
        // await setSpotify();
        // await setStn();
        await setAlauncher2();
        // await setShield();
        if (context.mounted) message.value = 'Has succeeded';
        failure.value = false;
        success.value = true;
      } catch (e, stacktrace) {
        debugPrint(stacktrace.toString());
        debugPrint(e.toString());
        if (context.mounted) message.value = 'Has failed';
        failure.value = true;
        success.value = false;
      } finally {
        loading.value = false;
      }
    }
  }

  Future<void> setAlauncher1() async {
    message.value = 'Alauncher package';
    final updater = Alauncher(android);
    await updater.runUpdate();
    await updater.runVanishCategories();
    await updater.setWallpaper(sharing.getString('picture')!);
  }

  Future<void> setAlauncher2() async {
    message.value = 'Alauncher package';
    final updater = Alauncher(android);
    await updater.setCategory('_', 130);
    await updater.setCategory('_', 90);
    await updater.setCategory('_', 90);
    await updater.setApplicationByIndex('Kodinerds', 3);
    await updater.setApplicationByIndex('Kodinerds Omega', 3);
  }

  Future<void> setKodinerdsNexus() async {
    message.value = 'Kodinerds Nexus package';
    final package = KodinerdsOmega(android);
    await android.runFinish(package.package);
    final updater = KodinerdsNexus(android);
    await updater.runRemove();
    await updater.runUpdate();

    await android.runFinish(updater.package);
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiAudioPassthrough(enabled: true);
    await updater.setKodiEnablePreferDefaultAudio(enabled: true);
    await updater.setKodiEnableShowParentFolder(enabled: false);
    await updater.setKodiEnableUpdateFromAnyRepositories(enabled: true);
    await updater.setKodiKeyboardList(['French AZERTY']);
    await updater.setKodiLanguageForAudio('default');
    await updater.setKodiLanguageForSubtitles('forced_only');
    await updater.setKodiLanguageForSystem('fr_fr');
    await updater.setKodiLanguageListForDownloadedSubtitles(['English']);
    await updater.setKodiSubtitleServiceForMovies('');
    await updater.setKodiSubtitleServiceForSeries('');
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setVstreamAddon();
    await updater.setRpc({'jsonrpc': '2.0', 'method': 'Application.Quit', 'params': {}, 'id': 1});
    await Future.delayed(const Duration(seconds: 5));
    await android.runFinish(updater.package);

    await android.runFinish(updater.package);
    await updater.setVstreamEnableActivateSubtitles(enabled: true);
    await updater.setVstreamEnableDisplaySeasonTitle(enabled: false);
    await updater.setVstreamEnablePlayNextEpisode(enabled: true);
    await updater.setVstreamEnableWidelistEverywhere(enabled: true);
    final private = (username: sharing.getString('realdebridUsername') ?? '', password: sharing.getString('realdebridPassword') ?? '');
    if (private.username.isNotEmpty && private.password.isNotEmpty) await updater.setVstreamPairForRealdebrid(private);
    await updater.setVstreamPastebinCodes();

    await updater.setKodiWebserver(enabled: false, secured: true);
  }

  Future<void> setKodinerdsOmega() async {
    message.value = 'Kodinerds Omega package';
    final package = KodinerdsNexus(android);
    await android.runFinish(package.package);
    final updater = KodinerdsOmega(android);
    await updater.runRemove();
    await updater.runUpdate();

    await android.runFinish(updater.package);
    await updater.setEstuaryMenuList(enabled: false);
    await updater.setEstuaryFavourites(enabled: true);
    await updater.setKodiEnableUnknownSources(enabled: true);

    await updater.setKodiWebserver(enabled: true, secured: false);
    await updater.setKodiAfr(enabled: true);
    await updater.setKodiAfrDelay(seconds: 3.5);
    await updater.setKodiAudioPassthrough(enabled: true);
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

  Future<void> setShield() async {
    message.value = 'Shield settings';
    await Future.delayed(const Duration(seconds: 5));
  }

  Future<void> setSpotify() async {
    message.value = 'Spotify package';
    await Future.delayed(const Duration(seconds: 5));
  }

  Future<void> setStn() async {
    message.value = 'SmartTubeNext package';
    await Future.delayed(const Duration(seconds: 5));
  }
}
