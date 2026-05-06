import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/controllers/auth_notifier.dart';
import '../../../models/user_role.dart';
import '../providers/session_provider.dart';
import '../models/session_model.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/glass_theme.dart';
import 'meeting_room_screen.dart';
import '../providers/meeting_room_provider.dart';

class SessionDetailScreen extends StatelessWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthNotifier>().currentUser?.role;
    final isTeacher = userRole != null && UserRoleX.fromApiValue(userRole) == UserRole.teacher;

    return Consumer<SessionProvider>(
      builder: (context, provider, child) {
        final session = provider.sessions.firstWhere(
          (s) => s.id == sessionId,
          orElse: () => const SessionModel(
            id: '', classId: '', title: 'Not Found', status: SessionStatus.completed
          ),
        );

        if (session.id.isEmpty) {
          return const Scaffold(body: Center(child: Text('Không tìm thấy buổi học.')));
        }

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? GlassTheme.darkBackground 
              : GlassTheme.lightBackground,
          appBar: AppBar(
            title: const Text('Chi tiết buổi học'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusBadge(session.status),
                    const SizedBox(height: 24),
                    Text('Thời gian bắt đầu: ${session.startTime?.toLocal().toString() ?? "Chưa rõ"}'),
                    Text('Thời gian kết thúc: ${session.endTime?.toLocal().toString() ?? "Chưa rõ"}'),
                    const SizedBox(height: 32),
                    if (isTeacher) ...[ 
                      if (session.status == SessionStatus.scheduled)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: GlassTheme.accent),
                          onPressed: () async {
                            await provider.startSession(session.id);
                            if (!context.mounted) return;
                            final joinData = await provider.joinSession(session.id);
                            if (!context.mounted) return;
                            if (joinData == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage ?? 'Không lấy được token'), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(
                              create: (_) => MeetingRoomProvider(),
                              child: MeetingRoomScreen(
                                sessionId: session.id,
                                livekitUrl: joinData.livekitUrl,
                                token: joinData.token,
                                sessionTitle: session.title,
                                isTeacher: true,
                              ),
                            )));
                          },
                          child: const Text('Bắt đầu buổi học', style: TextStyle(color: Colors.white)),
                        ),
                      if (session.status == SessionStatus.ongoing) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: GlassTheme.accent),
                          onPressed: () async {
                            final joinData = await provider.joinSession(session.id);
                            if (!context.mounted) return;
                            if (joinData == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage ?? 'Không lấy được token'), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(
                              create: (_) => MeetingRoomProvider(),
                              child: MeetingRoomScreen(
                                sessionId: session.id,
                                livekitUrl: joinData.livekitUrl,
                                token: joinData.token,
                                sessionTitle: session.title,
                                isTeacher: true,
                              ),
                            )));
                          },
                          child: const Text('Vào phòng', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => provider.endSession(session.id),
                          child: const Text('Kết thúc buổi học'),
                        ),
                      ],
                    ] else ...[
                      if (session.status == SessionStatus.ongoing)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: GlassTheme.accent),
                          onPressed: () async {
                            final joinData = await provider.joinSession(session.id);
                            if (!context.mounted) return;
                            if (joinData == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage ?? 'Không lấy được token'), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(
                              create: (_) => MeetingRoomProvider(),
                              child: MeetingRoomScreen(
                                sessionId: session.id,
                                livekitUrl: joinData.livekitUrl,
                                token: joinData.token,
                                sessionTitle: session.title,
                                isTeacher: false,
                              ),
                            )));
                          },
                          child: const Text('Tham gia', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
