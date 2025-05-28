import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/main_screen/group_setting_screen.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:chatapp/widget/setting_list_tile.dart';
import 'package:flutter/material.dart';

class SettingsAndMedia extends StatelessWidget {
  const SettingsAndMedia({
    super.key,
    required this.groupProvider,
    required this.isAdmin,
  });

  final GroupProvider groupProvider;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Column(
          children: [
            SettingsListTile(
              title: 'Media',
              icon: Icons.image,
              iconContainerColor: Colors.deepPurple,
              onTap: () {
                // navigate to media screen
              },
            ),
            const Divider(thickness: 0.5, color: Colors.grey),
            SettingsListTile(
              title: 'Group Seetings',
              icon: Icons.settings,
              iconContainerColor: Colors.deepPurple,
              onTap: () {
                if (!isAdmin) {
                  // show snackbar
                  showCustomSnackbar(
                    context: context,
                    title: 'Permission Denied',
                    message: 'Only admins can change group settings.',
                    backgroundColor: Colors.orange,
                    icon: Icons.admin_panel_settings_outlined,
                  );
                } else {
                  groupProvider.updateGroupAdminsList().whenComplete(() {
                    // navigate to group settings screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GroupSettingsScreen(),
                      ),
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
