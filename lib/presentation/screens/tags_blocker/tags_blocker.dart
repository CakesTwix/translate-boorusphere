import 'package:boorusphere/presentation/i18n/strings.g.dart';
import 'package:boorusphere/presentation/provider/blocked_tags.dart';
import 'package:boorusphere/presentation/widgets/notice_card.dart';
import 'package:boorusphere/utils/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TagsBlockerPage extends HookConsumerWidget {
  const TagsBlockerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t.tagsBlocker.title)),
      body: const SafeArea(
        child: _TagsBlockerContent(),
      ),
    );
  }
}

class _TagsBlockerContent extends HookConsumerWidget {
  const _TagsBlockerContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedTags = ref.watch(blockedTagsProvider);
    final controller = useTextEditingController();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
          child: Column(
            children: [
              Text(t.tagsBlocker.desc),
              TextField(
                controller: controller,
                onSubmitted: (value) {
                  final values = value.toWordList();
                  ref.read(blockedTagsProvider.notifier).pushAll(values);
                  controller.clear();
                },
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: t.tagsBlocker.hint,
                ),
              ),
            ],
          ),
        ),
        if (blockedTags.isEmpty)
          Center(
            child: NoticeCard(
              icon: const Icon(Icons.tag),
              margin: const EdgeInsets.all(32),
              children: Text(t.tagsBlocker.empty),
            ),
          ),
        for (final tag in blockedTags.entries)
          ListTile(
            title: Text(tag.value),
            leading: const Icon(Icons.block),
            trailing: IconButton(
              onPressed: () {
                ref.read(blockedTagsProvider.notifier).delete(tag.key);
              },
              icon: const Icon(Icons.close),
            ),
          ),
      ],
    );
  }
}