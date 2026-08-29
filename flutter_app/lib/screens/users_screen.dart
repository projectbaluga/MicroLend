import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/app_state.dart';
import '../widgets/app_badge.dart';
import '../widgets/custom_card.dart';
import '../widgets/responsive_container.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  void _showChangePasswordDialog(BuildContext context, String userId) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    String? errorMsg;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMsg != null) ...[
                      Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: oldPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password *', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final oldP = oldPasswordCtrl.text.trim();
                          final newP = newPasswordCtrl.text.trim();
                          final confP = confirmPasswordCtrl.text.trim();

                          if (oldP.isEmpty || newP.isEmpty) {
                            setModalState(() => errorMsg = 'Please fill in all required fields.');
                            return;
                          }

                          if (newP != confP) {
                            setModalState(() => errorMsg = 'New passwords do not match.');
                            return;
                          }

                          setModalState(() {
                            isSaving = true;
                            errorMsg = null;
                          });

                          try {
                            final state = Provider.of<AppState>(context, listen: false);
                            await state.changePassword(userId, oldP, newP);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully.')),
                            );
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              errorMsg = e.toString().replaceAll('ArgumentError: ', '');
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'officer';
    String? errorMsg;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Create New User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMsg != null) ...[
                      Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'approver', child: Text('Approver (Full Access)')),
                        DropdownMenuItem(value: 'officer', child: Text('Officer (Loans & Payments)')),
                        DropdownMenuItem(value: 'viewer', child: Text('Viewer (Read-Only)')),
                      ],
                      onChanged: (val) => selectedRole = val ?? 'officer',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final uName = usernameCtrl.text.trim();
                          final pwd = passwordCtrl.text.trim();

                          if (uName.isEmpty || pwd.isEmpty) {
                            setModalState(() => errorMsg = 'Please enter username and password.');
                            return;
                          }

                          setModalState(() {
                            isSaving = true;
                            errorMsg = null;
                          });

                          try {
                            final state = Provider.of<AppState>(context, listen: false);
                            await state.createUser(uName, pwd, selectedRole);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('User "$uName" created successfully.')),
                            );
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              errorMsg = e.toString().replaceAll('ArgumentError: ', '').replaceAll('StateError: ', '');
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currentUser = state.currentUser;
    final isApprover = currentUser?.role == 'approver';
    final allUsers = state.users;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('User Management & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (isApprover)
                    ElevatedButton.icon(
                      onPressed: () => _showCreateUserDialog(context),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('New User'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Current User Profile Card
              if (currentUser != null)
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentUser.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Role: ${currentUser.role.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showChangePasswordDialog(context, currentUser.id),
                            icon: const Icon(Icons.key, size: 16),
                            label: const Text('Change Password'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Users List Section
              if (isApprover) ...[
                const Text('Registered Operators', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final u = allUsers[idx];
                    final isSelf = u.id == currentUser?.id;

                    return CustomCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.person, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(u.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (isSelf) ...[
                                        const SizedBox(width: 6),
                                        const AppBadge(text: 'You', variant: 'low'),
                                      ],
                                    ],
                                  ),
                                  Text('Role: ${u.role}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              DropdownButton<String>(
                                value: u.role,
                                items: const [
                                  DropdownMenuItem(value: 'approver', child: Text('Approver')),
                                  DropdownMenuItem(value: 'officer', child: Text('Officer')),
                                  DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                                ],
                                onChanged: (newRole) {
                                  if (newRole != null && newRole != u.role) {
                                    state.updateUserRole(u.id, newRole);
                                  }
                                },
                              ),
                              if (!isSelf) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete User'),
                                        content: Text('Are you sure you want to delete user "${u.username}"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await state.deleteUser(u.id);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
