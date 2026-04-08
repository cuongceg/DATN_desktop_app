import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_web_rtc/widgets/app_react_button.dart';

enum PostMenuAction { modify, delete }

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onDeletePost,
    required this.onModifyPost,
  });

  final PostCardData post;
  final void Function(PostCardData post) onDeletePost;
  final void Function(PostCardData post) onModifyPost;

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

                      Text(
                        post.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _PostBodyView(post: post),
                      const SizedBox(height: 16),

                      // Link Preview Card
                      if (post.linkSummary.isNotEmpty ||
                          post.linkDomain.isNotEmpty)
                        LinkPreviewCard(post: post),
                    ],
                  ),
                ),
                // Icon nhóm góc phải
                if (post.authorName == 'Do Manh Cuong 20225172')
                  PopupMenuButton<PostMenuAction>(
                    tooltip: 'Post actions',
                    onSelected: (action) {
                      switch (action) {
                        case PostMenuAction.modify:
                          onModifyPost(post);
                        case PostMenuAction.delete:
                          onDeletePost(post);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<PostMenuAction>(
                        value: PostMenuAction.modify,
                        child: Text('Modify post'),
                      ),
                      PopupMenuItem<PostMenuAction>(
                        value: PostMenuAction.delete,
                        child: Text('Delete post'),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 58, bottom: 8),
            child: AppReactButton(
              tooltip: 'React to post',
              icon: Icons.add_reaction_outlined,
              iconColor: colors.onSurfaceVariant,
              itemSize: const Size(44, 44),
              boxColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              onReactionChanged: (_) {},
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
    this.bodyDelta,
    required this.linkSummary,
    required this.linkDomain,
    required this.replyInitials,
  });

  final String authorName;
  final String authorInitials;
  final String postedAt;
  final String title;
  final String content;
  final List<dynamic>? bodyDelta;
  final String linkSummary;
  final String linkDomain;
  final String replyInitials;
}

class _PostBodyView extends StatefulWidget {
  const _PostBodyView({required this.post});

  final PostCardData post;

  @override
  State<_PostBodyView> createState() => _PostBodyViewState();
}

class _PostBodyViewState extends State<_PostBodyView> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  @override
  void didUpdateWidget(covariant _PostBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _controller.dispose();
      _controller = _buildController();
    }
  }

  QuillController _buildController() {
    final delta = widget.post.bodyDelta;
    final document = (delta != null && delta.isNotEmpty)
        ? Document.fromJson(delta)
        : (Document()..insert(0, widget.post.content));
    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return QuillEditor.basic(
      controller: _controller,
      config: QuillEditorConfig(
        scrollable: false,
        expands: false,
        showCursor: false,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  height: 1.5,
                ) ??
                TextStyle(color: colors.onSurface, height: 1.5),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }
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
      replyInitials: 'DC',
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
      replyInitials: 'DC',
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
      replyInitials: 'DC',
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
      replyInitials: 'DC',
    ),
  ];
}

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
