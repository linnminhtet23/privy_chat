import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:privy_chat/widgets/profile_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';

class InfoDetailsCard extends StatelessWidget {
  const InfoDetailsCard({
    super.key,
    this.groupProvider,
    this.isAdmin,
    this.userModel,
  });

  final GroupProvider? groupProvider;
  final bool? isAdmin;
  final UserModel? userModel;

  @override
  Widget build(BuildContext context) {
    // get current user
    final authProvider = context.read<AuthenticationProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final uid = currentUser.uid;
    final phoneNumber = currentUser.email;
    // get profile image
    final profileImage = userModel != null
        ? userModel!.image
        : groupProvider!.groupModel.groupImage;
    // get profile name
    final profileName = userModel != null
        ? userModel!.name
        : groupProvider!.groupModel.groupName;

    // get group description
    final aboutMe = userModel != null
        ? userModel!.aboutMe
        : groupProvider!.groupModel.groupDescription;

    // get isGroup
    final isGroup = userModel != null ? false : true;

    Widget getEditWidget(
      String title,
      String content,
    ) {
      if (isGroup) {
        // check if user is admin
        if (isAdmin!) {
          return InkWell(
            onTap: () {
              showMyAnimatedDialog(
                context: context,
                title: title,
                content: content,
                textAction: "Change",
                onActionTap: (value, updatedText) async {
                  print("this is content $content");
                  if (value) {
                    if (content == Constants.changeName) {
                      final name = await authProvider.updateName(
                        isGroup: isGroup,
                        id: isGroup ? groupProvider!.groupModel.groupId : uid,
                        newName: updatedText,
                        oldName: profileName,
                      );
                      if (isGroup) {
                        if (name == 'Invalid name.') return;
                        groupProvider!.setGroupName(name);
                      }
                    } else {
                      final desc = await authProvider.updateStatus(
                        isGroup: isGroup,
                        id: isGroup ? groupProvider!.groupModel.groupId : uid,
                        newDesc: updatedText,
                        oldDesc: aboutMe,
                      );
                      if (isGroup) {
                        if (desc == 'Invalid description.') return;
                        groupProvider!.setGroupDescription(desc);
                      }
                    }
                  }
                },
                editable: true,
                hintText:
                    content == Constants.changeName ? profileName : aboutMe,
              );
            },
            child: const Icon(Icons.edit_rounded),
          );
        } else {
          return const SizedBox();
        }
      } else {
        if (userModel != null && userModel!.uid != uid) {
          return const SizedBox();
        }

        return InkWell(
          onTap: () {
            showMyAnimatedDialog(
              context: context,
              title: title,
              content: content,
              textAction: "Change",
              onActionTap: (value, updatedText) {
                if (value) {
                  if (content == Constants.changeName) {
                    authProvider.updateName(
                      isGroup: isGroup,
                      id: isGroup ? groupProvider!.groupModel.groupId : uid,
                      newName: updatedText,
                      oldName: profileName,
                    );
                  } else {
                    authProvider.updateStatus(
                      isGroup: isGroup,
                      id: isGroup ? groupProvider!.groupModel.groupId : uid,
                      newDesc: updatedText,
                      oldDesc: aboutMe,
                    );
                  }
                }
              },
              editable: true,
              hintText: content == Constants.changeName ? profileName : aboutMe,
            );
          },
          child: const Icon(Icons.edit_rounded),
        );
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                userImageWidget(
                    imageUrl: profileImage,
                    fileImage: authProvider.finalFileImage,
                    radius: 50,
                    onTap: () {
                      authProvider.showBottomSheet(
                          context: context,
                          onSuccess: () async {
                            if (isGroup) {
                              groupProvider!.setIsSloading(value: true);
                            }

                            String imageUrl = await authProvider.updateImage(
                              isGroup: isGroup,
                              id: isGroup
                                  ? groupProvider!.groupModel.groupId
                                  : uid,
                            );

                            if (isGroup) {
                              groupProvider!.setIsSloading(value: false);
                              if (imageUrl == 'Error') return;
                              groupProvider!.setGroupImage(imageUrl);
                            }
                          });
                    }),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            profileName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          getEditWidget(
                            'Change Name',
                            Constants.changeName,
                          ),
                        ],
                      ),
                      // display phone number
                      userModel != null && uid == userModel!.uid
                          ? Text(
                              phoneNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 5),
                      userModel != null
                          ? ProfileStatusWidget(
                              userModel: userModel!,
                              currentUser: authProvider.userModel!,
                            )
                          : GroupStatusWidget(
                              isAdmin: isAdmin!,
                              groupProvider: groupProvider!,
                            ),

                      const SizedBox(height: 10),
                    ],
                  ),
                )
              ],
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(userModel != null ? 'About Me' : 'Group Description',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                getEditWidget(
                  'Change Status',
                  Constants.changeDesc,
                ),
              ],
            ),
            Text(
              aboutMe,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
