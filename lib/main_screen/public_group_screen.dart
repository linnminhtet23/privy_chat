import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/models/group_model.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/widgets/chat_widget.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';

class PublicGroupScreen extends StatefulWidget {
  const PublicGroupScreen({super.key});

  @override
  State<PublicGroupScreen> createState() => _PublicGroupScreenState();
}

class _PublicGroupScreenState extends State<PublicGroupScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => searchQuery = query.trim());
    });
  }
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    return SafeArea(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoSearchTextField(
             placeholder: 'Search',
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSuffixTap: () {
                _searchController.clear();
                setState(() => searchQuery = '');
                FocusScope.of(context).unfocus();
              },
          ),
        ),

        // stream builder for private groups
        Expanded(
          child: searchQuery.isNotEmpty
                ? StreamBuilder<List<GroupModel>>(
                    stream: context.read<GroupProvider>().getAllPublicGroupsStream(
                      searchQuery: searchQuery,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Something went wrong'));
                      }
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No private groups Found'));
                      }

                      final groups = snapshot.data!;
                      return ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final groupModel = groups[index];
                          return 
                          ChatWidget(
                            group: groupModel,
                            isGroup: true,
                            onTap: () => _navigateToGroupChat(context, groupModel),
                          );
                        },
                      );
                    },
                  )
                : StreamBuilder<List<GroupModel>>(
            stream:
                context.read<GroupProvider>().getPublicGroupsStream(userId: uid),
            builder: (context, snapshot) {
              
             if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Something went wrong'));
                      }
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No groups found'));
                      }
                                            final groups = snapshot.data!;

              return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final groupModel = groups![index];
                    return Stack(
                            children: [
                              ChatWidget(
                                group: groupModel,
                                isGroup: true,
                                onTap: () => _navigateToGroupChat(context, groupModel),
                              ),
                              if (groupModel.adminsUIDs.contains(uid) && 
                                  groupModel.awaitingApprovalUIDs.isNotEmpty)

                                     Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        groupModel.awaitingApprovalUIDs.length.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                            ],
                          );
                    // return Stack(
                    //   children: [
                    //     ChatWidget(
                    //         group: groupModel,
                    //         isGroup: true,
                    //         onTap: () {
                    //           // check if user is already a member of the group
                    //           if (groupModel.membersUIDs.contains(uid)) {
                    //             context
                    //                 .read<GroupProvider>()
                    //                 .setGroupModel(groupModel: groupModel)
                    //                 .whenComplete(() {
                    //               Navigator.pushNamed(
                    //                 context,
                    //                 Constants.chatScreen,
                    //                 arguments: {
                    //                   Constants.contactUID: groupModel.groupId,
                    //                   Constants.contactName: groupModel.groupName,
                    //                   Constants.contactImage: groupModel.groupImage,
                    //                   Constants.groupId: groupModel.groupId,
                    //                 },
                    //               );
                    //             });
                    //             return;
                    //           }
                                  
                    //           // check if request to join settings is enabled
                    //           if (groupModel.requestToJoing) {
                    //             // check if user has already requested to join the group
                    //             if (groupModel.awaitingApprovalUIDs.contains(uid)) {
                    //               showSnackBar(context, 'Request already sent');
                    //               return;
                    //             }
                                  
                    //             // show animation to join group to request to join
                    //             showMyAnimatedDialog(
                    //               context: context,
                    //               title: 'Request to join',
                    //               content:
                    //                   'You need to request to join this group, before you can view the group content',
                    //               textAction: 'Request to join',
                    //               onActionTap: (value, updatedText) async {
                    //                 // send request to join group
                    //                 if (value) {
                    //                   await context
                    //                       .read<GroupProvider>()
                    //                       .sendRequestToJoinGroup(
                    //                         groupId: groupModel.groupId,
                    //                         uid: uid,
                    //                         groupName: groupModel.groupName,
                    //                         groupImage: groupModel.groupImage,
                    //                       )
                    //                       .whenComplete(() {
                    //                     showSnackBar(context, 'Request sent');
                    //                   });
                    //                 }
                    //               },
                    //             );
                    //             return;
                    //           }
                                  
                    //           context
                    //               .read<GroupProvider>()
                    //               .setGroupModel(groupModel: groupModel)
                    //               .whenComplete(() {
                    //             Navigator.pushNamed(
                    //               context,
                    //               Constants.chatScreen,
                    //               arguments: {
                    //                 Constants.contactUID: groupModel.groupId,
                    //                 Constants.contactName: groupModel.groupName,
                    //                 Constants.contactImage: groupModel.groupImage,
                    //                 Constants.groupId: groupModel.groupId,
                    //               },
                    //             );
                    //           });
                    //         }),
                    //   ],
                    // );
                  },
                );
              
            },
          ),
        )
      ],
    ));
  }
   void _navigateToGroupChat(BuildContext context, GroupModel groupModel) {
    context
        .read<GroupProvider>()
        .setGroupModel(groupModel: groupModel)
        .whenComplete(() {
      Navigator.pushNamed(
        context,
        Constants.chatScreen,
        arguments: {
          Constants.contactUID: groupModel.groupId,
          Constants.contactName: groupModel.groupName,
          Constants.contactImage: groupModel.groupImage,
          Constants.groupId: groupModel.groupId,
        },
      );
    });
  }
}
