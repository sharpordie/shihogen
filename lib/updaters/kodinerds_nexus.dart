import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shihogen/updaters/kodi.dart';
import 'package:netnerve/netnerve.dart';

class KodinerdsNexus extends Kodi {
  KodinerdsNexus(super.android);

  @override
  String get package => 'net.kodinerds.maven.kodi20';

  @override
  String get heading => 'Kodinerds';

  @override
  String get release => 'nexus';

  @override
  Future<File?> runGather() async {
    final fetcher = Dio()
      ..options.followRedirects = true
      ..options.headers = {'user-agent': 'mozilla/5.0'};
    const baseurl = 'https://repo.kodinerds.net';
    const website = '$baseurl/index.php?action=list&scope=cat&item=Binary%20(arm64-v8a)';
    final pattern = RegExp('aktuelle.*download=(.*Nexus.apk)(?=")');
    final content = await (await fetcher.get(website)).data;
    final address = pattern.firstMatch(content)?.group(1);
    if (address == null) return null;
    return await getFromAddress('$baseurl/$address');
  }
}