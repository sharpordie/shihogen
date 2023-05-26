import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
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
  late final loading = createProperty<bool>(false);
  late final failure = createProperty<bool>(false);
  late final success = createProperty<bool>(false);
  late final message = createProperty<String>('In progress');

  @override
  void initState() {
    super.initState();
    onDoneClicked();
  }

  Future<void> onDoneClicked() async {
    if (success.value || failure.value) {
      loading.value = true;
      await Navigator.pushNamed(context, '/discover');
      loading.value = false;
    } else {
      try {
        loading.value = true;
        await Future.delayed(const Duration(seconds: 5));
        // throw Exception();
        if (context.mounted) message.value = 'Has succeeded';
        failure.value = false;
        success.value = true;
      } catch (e) {
        debugPrint(e.toString());
        if (context.mounted) message.value = 'Has failed';
        failure.value = true;
        success.value = false;
      } finally {
        loading.value = false;
      }
    }
  }
}
