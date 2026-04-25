import 'package:flutter/material.dart';

import '../../models/class_model.dart';
import '../../models/class_notification.dart';

class StudentJoinClassScreen extends StatefulWidget {
  const StudentJoinClassScreen({
    super.key,
    required this.joinedClasses,
    required this.notifications,
    required this.onJoin,
  });

  final List<ClassModel> joinedClasses;
  final List<ClassNotification> notifications;
  final Future<ClassModel?> Function(String classId) onJoin;

  @override
  State<StudentJoinClassScreen> createState() => _StudentJoinClassScreenState();
}

class _StudentJoinClassScreenState extends State<StudentJoinClassScreen> {
  final TextEditingController _classCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final classCode = _classCodeController.text.trim();
    if (classCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class code.')),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final joinedClass = await widget.onJoin(classCode);
      if (!mounted) {
        return;
      }
      _classCodeController.clear();
      final successText = joinedClass == null
          ? 'Joined class successfully.'
          : 'Joined ${joinedClass.name} successfully.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successText)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Class')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join by Class Code',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _classCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Class Code',
                          hintText: 'Enter code like A1B2C3',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isJoining ? null : _handleJoin,
                        icon: _isJoining
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(_isJoining ? 'Joining...' : 'Join Class'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Joined Classes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: widget.joinedClasses.isEmpty
                            ? const Center(
                                child: Text('No classes joined yet.'),
                              )
                            : ListView.separated(
                                itemCount: widget.joinedClasses.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final classModel =
                                      widget.joinedClasses[index];
                                  return ListTile(
                                    leading: const Icon(Icons.class_outlined),
                                    title: Text(classModel.name),
                                    subtitle: Text(
                                      classModel.description ??
                                          'No description available.',
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: widget.notifications.isEmpty
                            ? const Center(
                                child: Text('No class notifications yet.'),
                              )
                            : ListView.separated(
                                itemCount: widget.notifications.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final notification =
                                      widget.notifications[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.notifications_active_outlined,
                                    ),
                                    title: Text(notification.message),
                                    subtitle: Text(
                                      notification.createdAt
                                          .toLocal()
                                          .toString()
                                          .split('.')
                                          .first,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
