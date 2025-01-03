import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/models/group_model.dart';
import 'package:privy_chat/providers/authentication_provider_unused.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/widgets/chat_widget.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';

class PrivateGroupScreen extends StatefulWidget {
  const PrivateGroupScreen({super.key});

  @override
  State<PrivateGroupScreen> createState() => _PrivateGroupScreenState();
}

class _PrivateGroupScreenState extends State<PrivateGroupScreen> {
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
      setState(() => searchQuery = query);
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
          Expanded(
            child: MyPrivateGroups(uid: uid, searchQuery: searchQuery),
          ),
        ],
      ),
    );
  }
}

class MyPrivateGroups extends StatelessWidget {
  const MyPrivateGroups({
    super.key,
    required this.uid,
    required this.searchQuery,
  });

  final String uid;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupModel>>(
      stream: context.read<GroupProvider>().getPrivateGroupsStream(userId: uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No private groups'));
        }

        final groups = snapshot.data!;
        final filteredGroups = searchQuery.isEmpty
            ? groups
            : groups
                .where((group) => group.groupName
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();

        if (filteredGroups.isEmpty) {
          return const Center(child: Text('No group found'));
        }

        return ListView.builder(
          itemCount: filteredGroups.length,
          itemBuilder: (context, index) {
            final groupModel = filteredGroups[index];
            return ChatWidget(
              group: groupModel,
              isGroup: true,
              onTap: () => _navigateToGroupChat(context, groupModel),
            );
          },
        );
      },
    );
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
