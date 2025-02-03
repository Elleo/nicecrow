/*
 * This file is part of Nice Crow
 *
 * Copyright (c) 2025 Mike Sheldon <mike@mikeasoft.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:flutter/material.dart';
import 'package:adwaita/adwaita.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:mastodon_api/mastodon_api.dart';
import 'package:nicecrow/pages/feed_page.dart';
import 'package:nicecrow/pages/messages_page.dart';
import 'package:nicecrow/pages/music_page.dart';
import 'package:nicecrow/pages/notifications.dart';
import 'package:nicecrow/pages/settings_page.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:nicecrow/auth.dart';
import 'package:nicecrow/opus/proxy_ffi.dart';

late StreamingSharedPreferences prefs;
MastodonApi? mastodon;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await StreamingSharedPreferences.instance;
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    Permission.microphone.request().isGranted.then((value) async {
      if (!value) {
        await [Permission.microphone].request();
      }
    });
  }
  Recorder.instance.init(sampleRate: 48000, channels: RecorderChannels.stereo);

  try {
    initOpus(await opus_flutter.load());
  } on UnsupportedError {
    await initFfi();
    initOpus(openOpus());
  }
  print(getOpusVersion());
  runApp(const NiceCrowApp());
}

class NiceCrowApp extends StatelessWidget {
  const NiceCrowApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Nice Crow',
        theme: AdwaitaThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const MainPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Preference<String> tokenPref =
      prefs.getString('accessToken', defaultValue: "");
  Preference<String> instancePref =
      prefs.getString('instance', defaultValue: "");
  int currentPageIndex = 0;

  @override
  void initState() {
    tokenPref.listen((token) {
      if (token.isEmpty) {
        openAuthPage();
      } else {
        setState(() {
          mastodon = MastodonApi(
            instance: instancePref.getValue(),
            bearerToken: tokenPref.getValue(),
            retryConfig: RetryConfig(
              maxAttempts: 5,
              jitter: Jitter(
                minInSeconds: 2,
                maxInSeconds: 5,
              ),
              onExecute: (event) => print(
                'Retry after ${event.intervalInSeconds} seconds...'
                '[${event.retryCount} times]',
              ),
            ),
            timeout: const Duration(seconds: 20),
          );
        });
      }
    });

    super.initState();
  }

  void openAuthPage() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AuthPage()))
        .then((result) async {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: [
          FeedPage(),
          MusicPage(),
          NotificationsPage(),
          MessagesPage(),
          SettingsPage()
        ][currentPageIndex],
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Theme.of(context).dialogBackgroundColor,
          selectedIndex: currentPageIndex,
          destinations: <Widget>[
            NavigationDestination(
              icon: Icon(Icons.voice_chat),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.music_note),
              label: 'Music',
            ),
            NavigationDestination(
                icon: Icon(Icons.notifications), label: 'Notifications'),
            NavigationDestination(
              icon: Badge(
                label: Text('1'),
                backgroundColor: Theme.of(context).primaryColor,
                textColor: Colors.white,
                child: Icon(Icons.messenger_sharp),
              ),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ));
  }
}
