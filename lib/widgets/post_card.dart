import 'package:flutter/material.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final PostCardData post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final cardColor = isLight
        ? Color.alphaBlend(const Color(0x0A000000), colors.surface)
        : Color.alphaBlend(const Color(0x12FFFFFF), colors.surface);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: colors.secondary,
            width: 4,
          ), // Dải viền màu cam đặc trưng
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Tên, Thời gian
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    post.authorInitials,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.postedAt,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tiêu đề bài viết
                      Text(
                        post.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        post.content,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Link Preview Card
                      LinkPreviewCard(post: post),
                    ],
                  ),
                ),
                // Icon nhóm góc phải
                Icon(
                  Icons.people_alt_outlined,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 58, bottom: 8),
            child: ReactionButton<String>(
              itemSize: const Size(44, 44), // Kích thước icon cảm xúc),
              onReactionChanged: (Reaction<String>? reaction) {
                if (reaction != null) {
                  debugPrint('Người dùng vừa thả cảm xúc: ${reaction.value}');
                  // TODO: Gọi API hoặc cập nhật State để hiển thị số lượng reaction
                }
              },
              reactions: myReactions,
              // Icon mặc định hiển thị khi chưa có cảm xúc nào được chọn
              placeholder: Reaction<String>(
                value: 'none',
                icon: Icon(
                  Icons.add_reaction_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
              // Cấu hình UI cho hộp chứa cảm xúc (Pop-up box)
              boxColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh, // Nền hộp trùng với theme
              boxRadius: 30, // Bo góc tròn trịa
              boxElevation: 4, // Đổ bóng nhẹ tạo chiều sâu
              boxPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
            ),
          ),

          // Vùng Reply (Phản hồi)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.outlineVariant.withOpacity(0.6)),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.surfaceContainerHighest,
                  child: Text(
                    post.replyInitials,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reply',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostCardData {
  const PostCardData({
    required this.authorName,
    required this.authorInitials,
    required this.postedAt,
    required this.title,
    required this.content,
    required this.linkSummary,
    required this.linkDomain,
    required this.replyInitials,
  });

  final String authorName;
  final String authorInitials;
  final String postedAt;
  final String title;
  final String content;
  final String linkSummary;
  final String linkDomain;
  final String replyInitials;
}

class PostCardSamples {
  static const List<PostCardData> posts = [
    PostCardData(
      authorName: 'Trịnh Thành Trung',
      authorInitials: 'TT',
      postedAt: 'Yesterday 11:38 AM',
      title: 'Thông báo lịch seminar AI ứng dụng trong giáo dục',
      content:
          'Chào các bạn K67 - Trường CNTT&TT, mời tham gia seminar AI ứng dụng trong giáo dục vào 14:00 thứ Sáu tuần này tại phòng 505 C7.\n\nDiễn giả: TS. Nguyễn Minh Quân.\nĐăng ký trước 17:00 ngày mai để nhận tài liệu.',
      linkSummary:
          'Seminar AI trong giáo dục sẽ chia sẻ case study thực tế và demo hệ thống trợ giảng thông minh cho lớp học đại học.',
      linkDomain: 'ctsv.soict.hust.edu.vn',
      replyInitials: 'D2',
    ),
    PostCardData(
      authorName: 'Lê Hải Đăng',
      authorInitials: 'LD',
      postedAt: 'Today 8:12 AM',
      title: 'Mời đăng ký cuộc thi Hackathon Smart Campus 2026',
      content:
          'Phòng Công tác sinh viên mở đăng ký Hackathon Smart Campus 2026 dành cho sinh viên toàn trường.\n\nMỗi đội 3-5 thành viên, vòng sơ loại nộp đề cương trước 20/04/2026.\nGiải nhất: 30.000.000đ và cơ hội ươm tạo dự án.',
      linkSummary:
          'Hackathon Smart Campus 2026 tập trung các bài toán quản lý đào tạo, tối ưu năng lượng và trải nghiệm học tập số.',
      linkDomain: 'hackathon.hust.edu.vn',
      replyInitials: 'N7',
    ),
    PostCardData(
      authorName: 'Phạm Thu Hà',
      authorInitials: 'PH',
      postedAt: 'Mar 30, 4:45 PM',
      title: 'Thông báo lịch bảo trì hệ thống LMS cuối tuần',
      content:
          'Trung tâm CNTT sẽ bảo trì hệ thống LMS từ 23:00 thứ Bảy đến 05:00 Chủ nhật.\n\nTrong thời gian này, chức năng nộp bài và chấm điểm tạm thời gián đoạn.\nĐề nghị giảng viên và sinh viên chủ động kế hoạch học tập.',
      linkSummary:
          'Kế hoạch bảo trì LMS tháng 4/2026: nâng cấp cơ sở dữ liệu, tối ưu tốc độ truy cập và tăng độ ổn định hệ thống.',
      linkDomain: 'lms.hust.edu.vn',
      replyInitials: 'K3',
    ),
    PostCardData(
      authorName: 'Đoàn Thanh niên SOICT',
      authorInitials: 'DT',
      postedAt: 'Mar 29, 9:10 AM',
      title: 'Tuyển tình nguyện viên Ngày hội việc làm 2026',
      content:
          'Đoàn trường tuyển 60 tình nguyện viên hỗ trợ sự kiện Ngày hội việc làm 2026 diễn ra tại hội trường C2.\n\nQuyền lợi: giấy chứng nhận, áo sự kiện, hỗ trợ ăn trưa.\nPhỏng vấn nhanh vào chiều thứ Năm tuần này.',
      linkSummary:
          'Ngày hội việc làm 2026 quy tụ hơn 80 doanh nghiệp công nghệ và hàng nghìn vị trí thực tập, tuyển dụng cho sinh viên.',
      linkDomain: 'youth.soict.hust.edu.vn',
      replyInitials: 'A1',
    ),
  ];
}

// Widget giả lập thẻ xem trước link (Link Preview)
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.post});

  final PostCardData post;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 100
            ? constraints.maxWidth
            : 100.0;
        final previewColor = isLight
            ? Color.alphaBlend(const Color(0x14000000), colors.surface)
            : Color.alphaBlend(
                const Color(0x10FFFFFF),
                colors.surfaceContainer,
              );
        final previewImageColor = isLight
            ? colors.surfaceContainerHighest
            : colors.surfaceContainerHigh;

        return SizedBox(
          width: cardWidth,
          child: Container(
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: cardWidth,
                  height: cardWidth * 0.62,
                  color: previewImageColor,
                  child: Icon(
                    Icons.account_balance,
                    color: colors.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.linkSummary,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.linkDomain,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final List<Reaction<String>> myReactions = [
  Reaction<String>(
    value: 'like',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text('👍', style: TextStyle(fontSize: 24)),
    ),
  ),
  Reaction<String>(
    value: 'love',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '❤️',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'laugh',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😆',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'wow',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😮',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'sad',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😢',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'angry',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😡',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
];
