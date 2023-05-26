import 'dart:isolate';

import 'package:adbnerve/adbnerve.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:network_discovery/network_discovery.dart';
import 'package:shihogen/widgets/own_appbar.dart';
import 'package:shihogen/widgets/own_header.dart';

class GuidanceView extends ViewWidget<GuidanceViewModel> {
  GuidanceView({super.key}) : super(builder: () => GuidanceViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OwnAppBar(
        btnText: 'Back',
        onClick: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          const OwnHeader(
            heading: 'Guidance',
            message: 'Follow the instructions',
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Text(
                  'Authorization is required, you have to press the allow button from the newly appeared dialog.\n\n'
                  'Once done, press back and reselect your device.',
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

class GuidanceViewModel extends ViewModel {}
