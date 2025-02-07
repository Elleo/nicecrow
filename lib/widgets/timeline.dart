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

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:mastodon_api/mastodon_api.dart' as api;
import 'package:siri_wave/siri_wave.dart';

class Timeline extends StatefulWidget {
  final api.MastodonApi mastodon;
  final List<api.Status> statuses;
  final String timeline;
  const Timeline(
      {super.key,
      required this.mastodon,
      required this.statuses,
      required this.timeline});
  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<String> revealedStatuses = [];
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  final player = AudioPlayer();
  _TimelineState() : super();

  @override
  void initState() {
    super.initState();
    updateTimeline(false);
  }

  void onRefresh() async {
    updateTimeline(true);
  }

  void updateTimeline(bool refresh) async {
    String? maxId;
    String? minId;
    if (widget.statuses.isNotEmpty) {
      if (refresh) {
        minId = widget.statuses.first.id;
      } else {
        maxId = widget.statuses.last.id;
      }
    }
    try {
      Future<api.MastodonResponse<List<api.Status>>> tlFuture;
      if (widget.timeline == "home") {
        tlFuture = widget.mastodon.v1.timelines
            .lookupHomeTimeline(minStatusId: minId, maxStatusId: maxId);
      } else if (widget.timeline == "local") {
        tlFuture = widget.mastodon.v1.timelines.lookupPublicTimeline(
            onlyLocal: true, minStatusId: minId, maxStatusId: maxId);
      } else if (widget.timeline == "federated") {
        tlFuture = widget.mastodon.v1.timelines.lookupPublicTimeline(
            onlyLocal: false, minStatusId: minId, maxStatusId: maxId);
      } else {
        return;
      }
      tlFuture.then((timeline) => {
            if (mounted)
              {
                setState(() {
                  for (var status in timeline.data.reversed) {
                    if (refresh) {
                      widget.statuses.insert(0, status);
                    } else {
                      widget.statuses.add(status);
                    }
                  }
                  if (refresh) {
                    refreshController.refreshCompleted();
                  } else {
                    refreshController.loadComplete();
                  }
                })
              }
          });
    } on api.DataNotFoundException catch (_) {
      if (refresh) {
        refreshController.refreshCompleted();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  void onLoading() async {
    updateTimeline(false);
  }

  @override
  Widget build(BuildContext context) {
    print(widget.statuses);
    return Scaffold(
        body: SmartRefresher(
      enablePullDown: true,
      enablePullUp: true,
      controller: refreshController,
      onRefresh: onRefresh,
      onLoading: onLoading,
      child: widget.statuses.isEmpty
          ? const Center(
              child: SizedBox(
                  height: 64, width: 64, child: CircularProgressIndicator()))
          : ListView.builder(
              itemBuilder: (c, i) => Card(
                  clipBehavior: Clip.hardEdge,
                  margin: const EdgeInsets.only(
                      left: 10, right: 10, top: 10, bottom: 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(children: [
                        Row(
                          children: [
                            Stack(clipBehavior: Clip.none, children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image(
                                      image: NetworkImage(
                                          widget.statuses[i].reblog != null
                                              ? widget.statuses[i].reblog!
                                                  .account.avatar
                                              : widget
                                                  .statuses[i].account.avatar),
                                      width: 32,
                                      height: 32)),
                              Visibility(
                                  visible: widget.statuses[i].reblog != null,
                                  child: Positioned(
                                      left: 16,
                                      top: 18,
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          child: Image(
                                              image: NetworkImage(widget
                                                  .statuses[i].account.avatar),
                                              width: 18,
                                              height: 18)))),
                            ]),
                            const SizedBox(width: 5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Visibility(
                                    visible: widget.statuses[i].reblog != null,
                                    child: Text(
                                      widget.statuses[i].account.displayName !=
                                              ""
                                          ? "${widget.statuses[i].account.displayName} boosted"
                                          : "${widget.statuses[i].account.username} boosted",
                                      style:
                                          const TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.left,
                                    )),
                                Text(
                                    widget.statuses[i].reblog != null
                                        ? widget.statuses[i].reblog!.account
                                                    .displayName !=
                                                ""
                                            ? widget.statuses[i].reblog!.account
                                                .displayName
                                            : widget.statuses[i].reblog!.account
                                                .username
                                        : widget.statuses[i].account
                                                    .displayName !=
                                                ""
                                            ? widget
                                                .statuses[i].account.displayName
                                            : widget
                                                .statuses[i].account.username,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.clip,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  widget.statuses[i].reblog != null
                                      ? "@${widget.statuses[i].reblog!.account.username}"
                                      : "@${widget.statuses[i].account.username}",
                                  style: const TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.left,
                                )
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                            child: HtmlWidget(widget.statuses[i].reblog != null
                                ? widget.statuses[i].reblog!.spoilerText != ""
                                    ? widget.statuses[i].reblog!.spoilerText
                                    : widget.statuses[i].reblog!.content
                                : widget.statuses[i].spoilerText != ""
                                    ? widget.statuses[i].spoilerText
                                    : widget.statuses[i].content)),
                        Visibility(
                            visible: (widget.statuses[i].spoilerText != "" ||
                                    (widget.statuses[i].reblog != null &&
                                        widget.statuses[i].reblog!
                                                .spoilerText !=
                                            "")) &&
                                !revealedStatuses
                                    .contains(widget.statuses[i].id),
                            child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    revealedStatuses.add(widget.statuses[i].id);
                                  });
                                },
                                child: const Text("Show More"))),
                        Visibility(
                            visible: revealedStatuses
                                .contains(widget.statuses[i].id),
                            child: HtmlWidget(widget.statuses[i].reblog != null
                                ? widget.statuses[i].reblog!.content
                                : widget.statuses[i].content)),
                        Visibility(
                            visible: (widget.statuses[i].spoilerText == "" ||
                                    (widget.statuses[i].reblog != null &&
                                        widget.statuses[i].reblog!
                                                .spoilerText ==
                                            "")) &&
                                !revealedStatuses
                                    .contains(widget.statuses[i].id),
                            child: Column(children: [
                              for (var media in widget.statuses[i].reblog != null
                                  ? widget.statuses[i].reblog!.mediaAttachments
                                  : widget.statuses[i].mediaAttachments)
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: media.type ==
                                                api.MediaAttachmentType.audio
                                            ? SiriWaveform.ios9(
                                                controller:
                                                    IOS9SiriWaveformController(
                                                        amplitude: 0),
                                                options: IOS9SiriWaveformOptions(
                                                    height: 40,
                                                    width: MediaQuery.of(context)
                                                            .size
                                                            .width -
                                                        20))
                                            : Image(
                                                image: NetworkImage(media.previewUrl ?? ''),
                                                width: MediaQuery.of(context).size.width - 20)))
                            ]))
                      ]))),
              itemCount: widget.statuses.length,
            ),
    ));
  }
}
