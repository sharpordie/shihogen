import 'dart:isolate';

import 'package:adbnerve/adbnerve.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:network_discovery/network_discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shihogen/widgets/own_appbar.dart';
import 'package:shihogen/widgets/own_header.dart';

class DiscoverView extends ViewWidget<DiscoverViewModel> {
  DiscoverView({super.key}) : super(builder: () => DiscoverViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OwnAppBar(
        btnText: 'Scan',
        loading: viewModel.loading.value,
        onClick: () async => await viewModel.onScanClicked(),
      ),
      body: Column(
        children: [
          const OwnHeader(
            heading: 'Discover',
            message: 'Choose your device',
          ),
          Expanded(
            child: viewModel.loading.value
                ? const Center(child: CircularProgressIndicator())
                : viewModel.devices.value.isNotEmpty
                    ? ListView.separated(
                        itemCount: viewModel.devices.value.length,
                        itemBuilder: (BuildContext context, int index) {
                          final address = viewModel.devices.value.elementAt(index);
                          return ListTile(
                            title: Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Text(
                                address,
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            subtitle: Text(
                              'Hostname not found',
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            trailing: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface),
                            onTap: () async => await viewModel.onTileClicked(address),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(
                            height: 1,
                            thickness: 1,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(64),
                          child: Text(
                            'No devices found on your local network, please ensure that network debugging is enabled on your device.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 2.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class DiscoverViewModel extends ViewModel {
  late final SharedPreferences sharing;
  late final loading = createProperty<bool>(false);
  late final devices = createProperty<Set<String>>({});

  @override
  void initState() {
    super.initState();
    onScanClicked();
    () async {
      sharing = await SharedPreferences.getInstance();
    }();
  }

  Future<void> onScanClicked() async {
    loading.value = true;
    devices.value.clear();
    final address = await NetworkDiscovery.discoverDeviceIpAddress();
    final network = address.substring(0, address.lastIndexOf('.'));
    devices.value = await Isolate.run(() async {
      final Set<String> members = {};
      final stream = NetworkDiscovery.discover(network, 5555);
      await stream.listen((data) => members.add(data.ip)).asFuture();
      return members;
    });
    loading.value = false;
  }

  Future<void> onTileClicked(String address) async {
    try {
      loading.value = true;
      final android = Shield(address);
      await android.runAttach();
      await sharing.clear();
      await sharing.setString('address', address);
      if (context.mounted) await Navigator.pushNamed(context, '/launcher');
      loading.value = false;
    } on Exception {
      final android = Shield(address);
      await android.runDetach();
      if (context.mounted) await Navigator.pushNamed(context, '/guidance');
      loading.value = false;
    }
  }
}
