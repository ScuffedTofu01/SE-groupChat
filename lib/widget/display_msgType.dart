import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/enum/enum.dart';

class DisplayMessageType extends StatelessWidget {
  final String message;
  final MessageEnum type;
  final Color color;
  final bool isReply; // To adjust styling if it's a reply preview
  final int? maxLines;
  final TextOverflow? overFlow;

  const DisplayMessageType({
    super.key,
    required this.message,
    required this.type,
    required this.color,
    required this.isReply,
    this.maxLines,
    this.overFlow,
  });

  @override
  Widget build(BuildContext context) {
    Widget messageToShow;
    TextStyle textStyle = TextStyle(
      fontSize: isReply ? 13 : 15, // Smaller font for replies
      color: color,
    );

    switch (type) {
      case MessageEnum.text:
        messageToShow = Text(
          message,
          style: textStyle,
          maxLines: maxLines ?? (isReply ? 2 : null), // Max lines for reply
          overflow: overFlow ?? (isReply ? TextOverflow.ellipsis : null),
        );
        break;
      case MessageEnum.image:
        if (isReply) {
          messageToShow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera_back_outlined,
                color: color,
                size: isReply ? 16 : 20,
              ),
              const SizedBox(width: 8),
              Text('Photo', style: textStyle),
            ],
          );
        } else {
          messageToShow = ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: message, // message here is the URL
              fit: BoxFit.cover,
              // Adjust height/width as needed, or let the parent MessageBubble constrain it
              height: 200,
              width: 200,
              placeholder:
                  (context, url) => Container(
                    height: 200,
                    width: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    height: 200,
                    width: 200,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 50,
                    ),
                  ),
            ),
          );
        }
        break;
      case MessageEnum.video:
        messageToShow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_rounded, color: color, size: isReply ? 16 : 20),
            const SizedBox(width: 8),
            Text('Video', style: textStyle),
          ],
        );
        break;
      case MessageEnum.audio:
        messageToShow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_rounded, color: color, size: isReply ? 16 : 20),
            const SizedBox(width: 8),
            Text('Audio', style: textStyle),
          ],
        );
        break;
      case MessageEnum.file:
        messageToShow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              color: color,
              size: isReply ? 16 : 20,
            ),
            const SizedBox(width: 8),
            Text('File', style: textStyle),
          ],
        );
        break;
      default:
        messageToShow = Text(
          message,
          style: textStyle,
          maxLines: maxLines ?? (isReply ? 2 : null),
          overflow: overFlow ?? (isReply ? TextOverflow.ellipsis : null),
        );
    }
    return messageToShow;
  }
}
