import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shihogen/widgets/own_appbar.dart';
import 'package:shihogen/widgets/own_header.dart';
import 'package:shihogen/widgets/own_insert.dart';
import 'package:shihogen/widgets/own_rubric.dart';

class SettingsView extends ViewWidget<SettingsViewModel> {
  SettingsView({super.key}) : super(builder: () => SettingsViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OwnAppBar(
        btnText: 'Done',
        loading: viewModel.loading.value,
        onClick: () async => await viewModel.onDoneClicked(),
      ),
      body: Column(
        children: [
          const OwnHeader(
            heading: 'Settings',
            message: 'Insert your information',
          ),
          if (!viewModel.loading.value) ...[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 23, 16, 0),
                children: [
                  const OwnRubric(heading: 'ALLDEBRID TOKEN', message: 'OPTIONAL'),
                  OwnInsert(controller: viewModel.alldebridToken, message: 'None'),
                  // const SizedBox(height: 24),
                  // const OwnRubric(heading: 'SPOTIFY', message: 'OPTIONAL'),
                  // OwnInsert(controller: viewModel.spotifyUsername, message: 'Username'),
                  // Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  // OwnInsert(controller: viewModel.spotifyPassword, message: 'Password', password: true),
                  // const SizedBox(height: 24),
                  // const OwnRubric(heading: 'TRAKT', message: 'OPTIONAL'),
                  // OwnInsert(controller: viewModel.traktUsername, message: 'Username'),
                  // Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  // OwnInsert(controller: viewModel.traktPassword, message: 'Password', password: true),
                  // const SizedBox(height: 24),
                  // const OwnRubric(heading: 'UPTOBOX', message: 'OPTIONAL'),
                  // OwnInsert(controller: viewModel.uptoboxUsername, message: 'Username'),
                  // Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  // OwnInsert(controller: viewModel.uptoboxPassword, message: 'Password', password: true),
                  // const SizedBox(height: 24),
                  // const OwnRubric(heading: 'YOUTUBE', message: 'OPTIONAL'),
                  // OwnInsert(controller: viewModel.youtubeUsername, message: 'Username'),
                  // Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  // OwnInsert(controller: viewModel.youtubePassword, message: 'Password', password: true),
                  // const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsViewModel extends ViewModel {
  late final SharedPreferences sharing;
  late final loading = createProperty<bool>(false);
  late final alldebridToken = TextEditingController();
  // late final realdebridPassword = TextEditingController();
  // late final realdebridUsername = TextEditingController();
  // late final spotifyPassword = TextEditingController();
  // late final spotifyUsername = TextEditingController();
  // late final traktPassword = TextEditingController();
  // late final traktUsername = TextEditingController();
  // late final uptoboxPassword = TextEditingController();
  // late final uptoboxUsername = TextEditingController();
  // late final youtubePassword = TextEditingController();
  // late final youtubeUsername = TextEditingController();

  @override
  void initState() {
    super.initState();
    () async {
      sharing = await SharedPreferences.getInstance();
    }();
  }

  @override
  void dispose() {
    alldebridToken.dispose();
    // realdebridPassword.dispose();
    // realdebridUsername.dispose();
    // spotifyPassword.dispose();
    // spotifyUsername.dispose();
    // traktPassword.dispose();
    // traktUsername.dispose();
    // uptoboxPassword.dispose();
    // uptoboxUsername.dispose();
    // youtubePassword.dispose();
    // youtubeUsername.dispose();
    super.dispose();
  }

  Future<void> onDoneClicked() async {
    loading.value = true;
    await sharing.setString('alldebridToken', alldebridToken.text);
    // await sharing.setString('realdebridPassword', realdebridPassword.text);
    // await sharing.setString('realdebridUsername', realdebridUsername.text);
    // await sharing.setString('spotifyPassword', spotifyPassword.text);
    // await sharing.setString('spotifyUsername', spotifyUsername.text);
    // await sharing.setString('traktPassword', traktPassword.text);
    // await sharing.setString('traktUsername', traktUsername.text);
    // await sharing.setString('uptoboxPassword', uptoboxPassword.text);
    // await sharing.setString('uptoboxUsername', uptoboxUsername.text);
    // await sharing.setString('youtubePassword', youtubePassword.text);
    // await sharing.setString('youtubeUsername', youtubeUsername.text);
    if (context.mounted) await Navigator.pushNamed(context, '/updating');
    loading.value = false;
  }
}
