import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:shihogen/widgets/own_appbar.dart';
import 'package:shihogen/widgets/own_header.dart';
import 'package:shihogen/widgets/own_insert.dart';
import 'package:shihogen/widgets/own_rubric.dart';

class AccountsView extends ViewWidget<AccountsViewModel> {
  AccountsView({super.key}) : super(builder: () => AccountsViewModel());

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
            heading: 'Accounts',
            message: 'Insert your information',
          ),
          if (!viewModel.loading.value) ...[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 23, 16, 0),
                children: [
                  const OwnRubric(heading: 'REALDEBRID', message: 'OPTIONAL'),
                  OwnInsert(controller: viewModel.realdebridUsername, message: 'Username'),
                  Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  OwnInsert(controller: viewModel.realdebridPassword, message: 'Password', password: true),
                  const SizedBox(height: 24),
                  const OwnRubric(heading: 'SPOTIFY', message: 'OPTIONAL'),
                  OwnInsert(controller: viewModel.spotifyUsername, message: 'Username'),
                  Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  OwnInsert(controller: viewModel.spotifyPassword, message: 'Password', password: true),
                  const SizedBox(height: 24),
                  const OwnRubric(heading: 'TRAKT', message: 'OPTIONAL'),
                  OwnInsert(controller: viewModel.traktUsername, message: 'Username'),
                  Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  OwnInsert(controller: viewModel.traktPassword, message: 'Password', password: true),
                  const SizedBox(height: 24),
                  const OwnRubric(heading: 'UPTOBOX', message: 'OPTIONAL'),
                  OwnInsert(controller: viewModel.uptoboxUsername, message: 'Username'),
                  Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  OwnInsert(controller: viewModel.uptoboxPassword, message: 'Password', password: true),
                  const SizedBox(height: 24),
                  const OwnRubric(heading: 'YOUTUBE', message: 'OPTIONAL'),
                  OwnInsert(controller: viewModel.youtubeUsername, message: 'Username'),
                  Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
                  OwnInsert(controller: viewModel.youtubePassword, message: 'Password', password: true),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AccountsViewModel extends ViewModel {
  late final loading = createProperty<bool>(false);
  late final realdebridPassword = TextEditingController();
  late final realdebridUsername = TextEditingController();
  late final spotifyPassword = TextEditingController();
  late final spotifyUsername = TextEditingController();
  late final traktPassword = TextEditingController();
  late final traktUsername = TextEditingController();
  late final uptoboxPassword = TextEditingController();
  late final uptoboxUsername = TextEditingController();
  late final youtubePassword = TextEditingController();
  late final youtubeUsername = TextEditingController();

  @override
  void dispose() {
    realdebridPassword.dispose();
    realdebridUsername.dispose();
    spotifyPassword.dispose();
    spotifyUsername.dispose();
    traktPassword.dispose();
    traktUsername.dispose();
    uptoboxPassword.dispose();
    uptoboxUsername.dispose();
    youtubePassword.dispose();
    youtubeUsername.dispose();
    super.dispose();
  }

  Future<void> onDoneClicked() async {
    loading.value = true;
    if (context.mounted) await Navigator.pushNamed(context, '/updating');
    loading.value = false;
  }
}
