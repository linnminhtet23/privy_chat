import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/streams/all_people_search_stream.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    return Scaffold(
        body: SafeArea(
      child: Column(
        children: [
          // cupertino search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search',
              prefixIcon: const Icon(CupertinoIcons.search),
              suffixMode: OverlayVisibilityMode.editing,
              suffixIcon: const Icon(CupertinoIcons.clear_circled_solid),
              onChanged: (value) => setState(() => searchQuery = value),
              onSuffixTap: () {
                _searchController.clear();
                setState(() => searchQuery = '');
                FocusScope.of(context).unfocus();
              },
            ),
          ),

          // list of users
          Expanded(
            child: searchQuery.isEmpty
                ? const Center(
                    child: Text(
                      'Search People',
                    ),
                  )
                : AllPeopleSearchStream(
                    uid: currentUser.uid,
                    searchText: searchQuery,
                  ),
          ),
        ],
      ),
    ));
  }
}
