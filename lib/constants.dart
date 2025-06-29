class Constants {
// screens routs
  static const String landingScreen = '/landingScreen';
  static const String loginScreen = '/loginScreen';
  static const String registerScreen = '/registerScreen';
  static const String otpScreen = '/otpScreen';
  static const String userInformationScreen = '/userInformationScreen';
  static const String homeScreen = '/homeScreen';
  static const String chatScreen = '/chatScreen';
  static const String profileScreen = '/profileScreen';
  static const String editProfileScreen = '/editProfileScreen';
  static const String searchScreen = '/searchScreen';
  static const String friendRequestsScreen = '/friendRequestsScreen';
  static const String friendsScreen = '/friendsScreen';
  static const String settingsScreen = '/settingsScreen';
  static const String aboutScreen = '/aboutScreen';
  static const String privacyPolicyScreen = '/privacyPolicyScreen';
  static const String termsAndConditionsScreen = '/termsAndConditionsScreen';
  static const String groupSettingsScreen = '/groupSettingsScreen';
  static const String groupInformationScreen = '/groupInformationScreen';

  static const String uid = 'uid';
  static const String name = 'name';
  static const String phoneNumber = 'phoneNumber';
  static const String email = 'email';
  static const String password = 'password';

  static const String image = 'image';
  static const String token = 'token';
  static const String aboutMe = 'aboutMe';
  static const String lastSeen = 'lastSeen';
  static const String createdAt = 'createdAt';
  static const String isOnline = 'isOnline';
  static const String friendsUIDs = 'friendsUIDs';
  static const String publicKey ='publicKey';
  static const String privateKey ='privateKey';
  static const String friendRequestsUIDs = 'friendRequestsUIDs';
  static const String sentFriendRequestsUIDs = 'sentFriendRequestsUIDs';

  static const String verificationId = 'verificationId';

  static const String users = 'users';
  static const String userImages = 'userImages';
  static const String userModel = 'userModel';

  static const String contactName = 'contactName';
  static const String contactImage = 'contactImage';
  static const String groupId = 'groupId';
  static const String groupModel = 'groupModel';

  static const String senderUID = 'senderUID';
  static const String senderName = 'senderName';
  static const String senderImage = 'senderImage';
  static const String contactUID = 'contactUID';
  static const String message = 'message';
    static const String tempMessage = 'tempMessage';
        static const String tempFileMessage = 'tempFileMessage';

    static const String messageForSender = 'messageForSender';
  static const String messageForReceiver = 'messageForReceiver';
  static const String aesKeyEncryptedForSender = 'aesKeyEncryptedForSender';
  static const String aesKeyEncryptedForReceiver = 'aesKeyEncryptedForReceiver';

  static const String messageType = 'messageType';
  static const String timeSent = 'timeSent';
  static const String isTyping = 'isTyping';
  static const String typingInChatRoom = 'typingInChatRoom';
  static const String messageId = 'messageId';
  static const String isSeen = 'isSeen';
  static const String repliedMessage = 'repliedMessage';
  static const String tempRepliedMessage = 'tempRepliedMessage';
  static const String tempRepliedFileMessage = 'tempRepliedFileMessage';
  static const String repliedTo = 'repliedTo';
  static const String repliedMessageType = 'repliedMessageType';
  static const String isMe = 'isMe';
  static const String reactions = 'reactions';
  static const String isSeenBy = 'isSeenBy';
  static const String deletedBy = 'deletedBy';
  static const String encryptedAesKey = 'encryptedAesKey';
  static const String iv = 'iv';
  static const String additionalData = 'additionalData';
  static const String aesKeyEncrypted = 'aesKeyEncrypted';
  static const String aesKeyMessageReplied = 'aesKeyMessageReplied';
  static const String typingUserId ='typingUserId';



  static const String lastMessage = 'lastMessage';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String groups = 'groups';
  static const chatFiles = 'chatFiles';

  static const String private = 'private';
  static const String public = 'public';

  static const String creatorUID = 'creatorUID';
  static const String groupName = 'groupName';
  static const String groupDescription = 'groupDescription';
  static const String groupImage = 'groupImage';
  static const String isPrivate = 'isPrivate';
  static const String editSettings = 'editSettings';
  static const String approveMembers = 'approveMembers';
  static const String lockMessages = 'lockMessages';
  static const String requestToJoing = 'requestToJoing';
  static const String membersUIDs = 'membersUIDs';
  static const String adminsUIDs = 'adminsUIDs';
  static const String awaitingApprovalUIDs = 'awaitingApprovalUIDs';

  static const String groupImages = 'groupImages';

  static const String changeName = 'changeName';
  static const String changeDesc = 'changeDesc';

  // notification
  static const String notificationType = 'notificationType';
  static const String groupChatNotification = 'groupChatNotification';
  static const String chatNotification = 'chatNotification';
  static const String friendRequestNotification = 'friendRequestNotification';
  static const String requestReplyNotification = 'requestReplyNotification';
  static const String groupRequestNotification = 'groupRequestNotification';
}


// keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android