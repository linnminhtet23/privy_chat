import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:privy_chat/enums/enums.dart';
import 'package:privy_chat/widgets/audio_player_widget.dart';
import 'package:privy_chat/widgets/video_player_widget.dart';

class DisplayMessageType extends StatefulWidget {
  const DisplayMessageType({
    super.key,
    required this.message,
    required this.type,
    required this.color,
    required this.isReply,
    this.maxLines,
    this.overFlow,
    required this.viewOnly,
  });

  final String message;
  final MessageEnum type;
  final Color color;
  final bool isReply;
  final int? maxLines;
  final TextOverflow? overFlow;
  final bool viewOnly;

  @override
  _DisplayMessageTypeState createState() => _DisplayMessageTypeState();
}

class _DisplayMessageTypeState extends State<DisplayMessageType> {

  @override
  Widget build(BuildContext context) {
    Widget messageToShow() {
      switch (widget.type) {
        case MessageEnum.text:
          if (widget.message.toLowerCase().startsWith('http')) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse(widget.message);
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      throw Exception('Could not launch $url');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.color.withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnyLinkPreview(
                        link: widget.message,
                        displayDirection: UIDirection.uiDirectionVertical,
                        showMultimedia: true,
                        bodyMaxLines: 3,
                        bodyTextOverflow: TextOverflow.ellipsis,
                        titleStyle: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        bodyStyle: TextStyle(
                          color: widget.color.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.2,
                        ),
                        errorWidget: Text(
                          widget.message,
                          style: TextStyle(color: widget.color),
                        ),
                        cache: Duration(days: 7),
                        backgroundColor: widget.color.withOpacity(0.1),
                        borderRadius: 12,
                  ),
                ),
                )
                )
              ],
            );
          }
          return Text(
            widget.message,
            style: TextStyle(
              color: widget.color,
              fontSize: 16.0,
            ),
            maxLines: widget.maxLines,
            overflow: widget.overFlow,
          );

        case MessageEnum.image:
          return widget.isReply
              ? const Icon(Icons.image)
              : CachedNetworkImage(
                  width: 200,
                  height: 200,
                  imageUrl: widget.message,
                  fit: BoxFit.cover,
                );

        case MessageEnum.video:
          return widget.isReply
              ? const Icon(Icons.video_collection)
              : VideoPlayerWidget(
                  videoUrl: widget.message,
                  color: widget.color,
                  viewOnly: widget.viewOnly,
                );

        case MessageEnum.audio:
          return widget.isReply
              ? const Icon(Icons.audiotrack)
              : AudioPlayerWidget(
                  audioUrl: widget.message,
                  color: widget.color,
                  viewOnly: widget.viewOnly,
                );

        default:
          return Text(
            widget.message,
            style: TextStyle(
              color: widget.color,
              fontSize: 16.0,
            ),
            maxLines: widget.maxLines,
            overflow: widget.overFlow,
          );
      }
    }

    return messageToShow();
  }
}
