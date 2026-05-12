import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_rtc/features/auth/presentation/controllers/auth_notifier.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onClose,
    required this.onPost,
    this.initialSubject = '',
    this.initialBody = '',
    this.initialBodyDelta,
    this.postButtonLabel = 'Post',
  });

  final VoidCallback onClose;
  final void Function(String subject, String bodyPlain, List<dynamic> bodyDelta)
  onPost;
  final String initialSubject;
  final String initialBody;
  final List<dynamic>? initialBodyDelta;
  final String postButtonLabel;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  late final TextEditingController _subjectController;
  late QuillController _bodyController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.initialSubject);
    _bodyController = QuillController(
      document: _buildDocumentFromInputs(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void didUpdateWidget(covariant MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubject != widget.initialSubject) {
      _subjectController.text = widget.initialSubject;
    }
    if (oldWidget.initialBody != widget.initialBody ||
        !listEquals(oldWidget.initialBodyDelta, widget.initialBodyDelta)) {
      _bodyController.dispose();
      _bodyController = QuillController(
        document: _buildDocumentFromInputs(),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  Document _buildDocumentFromInputs() {
    final delta = widget.initialBodyDelta;
    if (delta != null && delta.isNotEmpty) {
      try {
        return Document.fromJson(delta);
      } catch (_) {
        // fallback to plain text when delta is invalid
      }
    }
    return Document()..insert(0, widget.initialBody);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? colors.outline.withValues(alpha: 0.65)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.6)),
          _buildSubjectField(context),
          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
          _buildMessageBody(context),
          _buildToolbar(context),
          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.6)),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = context.watch<AuthNotifier>().currentUser;
    final userName = user?.fullName ?? '';
    final userInitials = _buildInitials(userName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colors.primaryContainer,
            child: Text(
              userInitials,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Close composer',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectField(BuildContext context) {
    return TextField(
      controller: _subjectController,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Add a subject',
      ),
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildMessageBody(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 260),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: QuillEditor.basic(
          controller: _bodyController,
          config: QuillEditorConfig(
            placeholder: 'Type a message',
            padding: EdgeInsets.zero,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      height: 1.45,
                    ) ??
                    TextStyle(color: colors.onSurface, height: 1.45),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      child: QuillSimpleToolbar(
        controller: _bodyController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showSubscript: false,
          showSuperscript: false,
          showSearchButton: false,
          showCodeBlock: false,
          showQuote: false,
          showBackgroundColorButton: false,
          showColorButton: false,
          showHeaderStyle: false,
          showAlignmentButtons: false,
          showFontFamily: false,
          showFontSize: false,
          showInlineCode: false,
          showListCheck: false,
          showIndent: false,
          showDirection: false,
          showDividers: false,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(
                  color: colors.onPrimaryContainer,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Emoji',
            onPressed: () {},
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Attachment',
            onPressed: () {},
            icon: const Icon(Icons.attach_file),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'More',
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              final subject = _subjectController.text.trim();
              final bodyPlain = _bodyController.document.toPlainText().trim();
              final bodyDelta = _bodyController.document.toDelta().toJson();
              widget.onPost(subject, bodyPlain, bodyDelta);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(88, 40),
            ),
            child: Text(widget.postButtonLabel),
          ),
        ],
      ),
    );
  }

  String _buildInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first.toUpperCase();
      return w.length >= 2 ? w.substring(0, 2) : w;
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }
}
