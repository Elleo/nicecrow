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

import 'package:flutter/material.dart';
import 'package:mastodon_api/mastodon_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ogg_opus_player/ogg_opus_player.dart';
import 'package:nicecrow/main.dart';
import 'package:nicecrow/widgets/timeline.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  _FeedPageState() : super();

  bool recording = false;
  OggOpusRecorder? _recorder;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 0,
        length: 3,
        child: Scaffold(
            appBar: AppBar(
              title: const TabBar(
                dividerHeight: 0,
                tabs: <Widget>[
                  Tab(
                    icon: Icon(Icons.person),
                  ),
                  Tab(
                    icon: Icon(Icons.people),
                  ),
                  Tab(
                    icon: Icon(Icons.public),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
                child: Icon(recording ? Icons.stop : Icons.mic),
                onPressed: () async {
                  var tempDir = await getTemporaryDirectory();
                  File output = File("${tempDir.path}/recording.opus");
                  if (recording) {
                    if (_recorder != null) {
                      await _recorder!.stop();
                      _recorder!.dispose();
                      mastodon!.v2.media
                          .uploadMedia(file: output)
                          .then((MastodonResponse<MediaAttachment> response) {
                        print(response);
                      });
                    }
                  } else {
                    final recorder = OggOpusRecorder(output.path);
                    _recorder = recorder;
                    recorder.start();
                  }
                  setState(() {
                    recording = !recording;
                  });
                }),
            body: mastodon != null
                ? Timeline(mastodon: mastodon!, timeline: "home", statuses: [])
                : Center(child: Text("Connecting..."))));
  }
}
