import 'dart:io';

import 'package:netnerve/netnerve.dart';
import 'package:shihogen/updaters/updater.dart';

class SmarttubeBeta extends Updater {
  SmarttubeBeta(super.android);

  @override
  String get package => 'com.liskovsoft.smarttubetv.beta';

  @override
  String get heading => 'SmartTube beta';

  @override
  Future<File?> runGather() async {
    const address = 'https://github.com/yuliskov/SmartTubeNext/releases/download/latest/smarttube_beta.apk';
    return await getFromAddress(address);
  }
}
