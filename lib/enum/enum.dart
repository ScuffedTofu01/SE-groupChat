enum FriendViewType { friends, friendRequests, groupView, allUsers }

enum MessageEnum { text, image, video, audio, file }

enum GroupType { private, public }

extension MessageEnumExtension on String {
  MessageEnum toMessageEnum() {
    switch (this) {
      case 'text':
        return MessageEnum.text;
      case 'image':
        return MessageEnum.image;
      case 'video':
        return MessageEnum.video;
      case 'audio':
        return MessageEnum.audio;
      case 'file':
        return MessageEnum.file;
      default:
        return MessageEnum.text;
    }
  }
}
