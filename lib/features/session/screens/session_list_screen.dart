import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/controllers/auth_notifier.dart';
import '../../../models/user_role.dart';
import '../providers/session_provider.dart';
import '../models/session_model.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/glass_theme.dart';
import 'session_detail_screen.dart';

class SessionListScreen extends StatefulWidget {
  final String classId;

  const SessionListScreen({super.key, required this.classId});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().fetchSessions(widget.classId);
    });
  }

  void _showCreateSessionDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo buổi học mới'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Tên buổi học'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text;
              if (title.isNotEmpty) {
                await context.read<SessionProvider>().createSession(widget.classId, title);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthNotifier>().currentUser?.role;
    final isTeacher = userRole != null && UserRoleX.fromApiValue(userRole) == UserRole.teacher;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? GlassTheme.darkBackground 
          : GlassTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Danh sách buổi học'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isTeacher)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tạo buổi học'),
                onPressed: _showCreateSessionDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          if (provider.loadState == SessionLoadState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadState == SessionLoadState.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }
          
          if (provider.sessions.isEmpty) {
            return const Center(child: Text('Chưa có buổi học nào.'));
          }

          return Row(
            children: [
              Expanded(
                flex: 1,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.sessions.length,
                  itemBuilder: (context, index) {
                    final session = provider.sessions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailScreen(sessionId: session.id),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    session.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                _buildStatusBadge(session.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bắt đầu: ${session.startTime?.toLocal().toString() ?? "Chưa bắt đầu"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? GlassTheme.darkSubText 
                                    : GlassTheme.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: const Center(
                  child: Text('Chọn một buổi học để xem chi tiết', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status) {
    Color color;
    String text;
    switch (status) {
      case SessionStatus.scheduled:
        color = Colors.blue;
        text = 'Sắp tới';
        break;
      case SessionStatus.ongoing:
        color = Colors.green;
        text = 'Đang diễn ra';
        break;
      case SessionStatus.completed:
        color = Colors.grey;
        text = 'Đã kết thúc';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
