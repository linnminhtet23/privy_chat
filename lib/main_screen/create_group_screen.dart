import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/enums/enums.dart';
import 'package:privy_chat/models/group_model.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:privy_chat/widgets/my_app_bar.dart';
import 'package:privy_chat/widgets/display_user_image.dart';
import 'package:privy_chat/widgets/friends_list.dart';
import 'package:privy_chat/widgets/group_type_list_tile.dart';
import 'package:privy_chat/widgets/settings_list_tile.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';
import '../utils/encryptionutilsnewapproach.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  // group name controller
  final TextEditingController groupNameController = TextEditingController();
  // group description controller
  final TextEditingController groupDescriptionController =
      TextEditingController();
  File? finalFileImage;
  String userImage = '';

  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        showSnackBar(context, message);
      },
    );

    // crop image
    await cropImage(finalFileImage?.path);

    popContext();
  }

  popContext() {
    Navigator.pop(context);
  }

  Future<void> cropImage(filePath) async {
    if (filePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        setState(() {
          finalFileImage = File(croppedFile.path);
        });
      }
    }
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {
                selectImage(true);
              },
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
            ),
            ListTile(
              onTap: () {
                selectImage(false);
              },
              leading: const Icon(Icons.image),
              title: const Text('Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.dispose();
  }

  GroupType groupValue = GroupType.private;

  // create group
  void createGroup() {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    final groupProvider = context.read<GroupProvider>();
    // check if the group name is empty
    if (groupNameController.text.isEmpty) {
      showSnackBar(context, 'Please enter group name');
      return;
    }

    // name is less than 3 characters
    if (groupNameController.text.length < 3) {
      showSnackBar(context, 'Group name must be at least 3 characters');
      return;
    }

    // check if the group description is empty
    if (groupDescriptionController.text.isEmpty) {
      showSnackBar(context, 'Please enter group description');
      return;
    }

    final rsaKeyPair = generateRSAKeyPair();
    final publicKey = encodePublicKeyToPem(rsaKeyPair.publicKey);
    final privateKey = encodePrivateKeyToPem(rsaKeyPair.privateKey);
  print("group type ${GroupType}");

    GroupModel groupModel = GroupModel(
      creatorUID: uid,
      groupName: groupNameController.text,
      groupDescription: groupDescriptionController.text,
      groupImage: '',
      groupId: '',
      lastMessage: '',
      senderUID: '',
      messageType: MessageEnum.text,
      messageId: '',
      timeSent: DateTime.now(),
      createdAt: DateTime.now(),
      isPrivate: groupValue == GroupType.private ? true : false,
      editSettings: true,
      approveMembers: false,
      lockMessages: false,
      requestToJoing: false,
      membersUIDs: [],
      adminsUIDs: [],
      awaitingApprovalUIDs: [],
      publicKey:publicKey,
      privateKey: privateKey
    );

    // create group
    groupProvider.createGroup(
      newGroupModel: groupModel,
      fileImage: finalFileImage,
      onSuccess: () {
        showSnackBar(context, 'Group created successfully');
        Navigator.pop(context);
      },
      onFail: (error) {
        showSnackBar(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: Text('Create Group'),
        onPressed: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              child: context.watch<GroupProvider>().isSloading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      onPressed: () {
                        // create group
                        createGroup();
                      },
                      icon: const Icon(Icons.check)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 10.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DisplayUserImage(
                    finalFileImage: finalFileImage,
                    radius: 60,
                    onPressed: () {
                      showBottomSheet();
                    },
                  ),
                  const SizedBox(width: 10),
                  buildGroupType(),
                ],
              ),
              const SizedBox(height: 10),

              // texField for group name
              TextField(
                controller: groupNameController,
                maxLength: 25,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Group Name',
                  label: Text('Group Name'),
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              // textField for group description
              TextField(
                controller: groupDescriptionController,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Group Description',
                  label: Text('Group Description'),
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              // const SizedBox(height: 10),
              // Card(
              //   child: Padding(
              //     padding: const EdgeInsets.only(
              //       left: 8.0,
              //       right: 8.0,
              //     ),
              //     child: SettingsListTile(
              //         title: 'Group Settings',
              //         icon: Icons.settings,
              //         iconContainerColor: Colors.deepPurple,
              //         onTap: () {
              //           // navigate to group settings screen
              //           Navigator.pushNamed(
              //               context, Constants.groupSettingsScreen);
              //         }),
              //   ),
              // ),
              const SizedBox(height: 10),
              const Text(
                'Select Group Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // cuppertino search bar
              CupertinoSearchTextField(
                onChanged: (value) {},
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: const FriendsList(
                  viewType: FriendViewType.groupView,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column buildGroupType() {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: GroupTypeListTile(
            title: GroupType.private.name,
            value: GroupType.private,
            groupValue: groupValue,
            onChanged: (value) {
              setState(() {
                groupValue = value!;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: GroupTypeListTile(
            title: GroupType.public.name,
            value: GroupType.public,
            groupValue: groupValue,
            onChanged: (value) {
              setState(() {
                groupValue = value!;
              });
            },
          ),
        ),
      ],
    );
  }
}
