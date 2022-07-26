import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../model/post.dart';
import '../../provider/page_manager.dart';
import '../components/appbar_visibility.dart';
import '../components/post_error.dart';
import '../components/post_image.dart';
import '../components/post_toolbox.dart';
import '../components/post_video.dart';
import '../hooks/extended_page_controller.dart';

final lastOpenedPostProvider = StateProvider((_) => -1);
final postFullscreenProvider = StateProvider((_) => false);

class PostPage extends HookConsumerWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beginPage = ModalRoute.of(context)?.settings.arguments as int;
    final pageController = useExtendedPageController(initialPage: beginPage);
    final pageManager = ref.watch(pageManagerProvider);
    final lastOpenedIndex = ref.watch(lastOpenedPostProvider.state);
    final page = useState(beginPage);
    final isFullscreen = ref.watch(postFullscreenProvider.state);
    final appbarAnimController =
        useAnimationController(duration: const Duration(milliseconds: 300));

    final isNotVideo =
        pageManager.posts[page.value].contentType != PostType.video;

    useEffect(() {
      SystemChrome.setSystemUIChangeCallback((fullscreen) async {
        isFullscreen.state = fullscreen;
      });

      // reset SystemChrome when pop back to timeline
      return () {
        isFullscreen.state = false;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([]);
      };
    }, const []);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppbarVisibility(
        controller: appbarAnimController,
        visible: !isFullscreen.state,
        child: _PostAppBar(
          subtitle: pageManager.posts[page.value].tags.join(' '),
          title: '#${page.value + 1} of ${pageManager.posts.length}',
        ),
      ),
      body: ExtendedImageGesturePageView.builder(
        controller: pageController,
        onPageChanged: (index) {
          page.value = index;
          lastOpenedIndex.state = index;
        },
        itemCount: pageManager.posts.length,
        itemBuilder: (_, index) {
          final post = pageManager.posts[index];
          switch (post.contentType) {
            case PostType.photo:
              return PostImageDisplay(post: post);
            case PostType.video:
              return PostVideoDisplay(post: post);
            default:
              return PostErrorDisplay(post: post);
          }
        },
      ),
      bottomNavigationBar: isNotVideo
          ? BottomBarVisibility(
              controller: appbarAnimController,
              visible: !isFullscreen.state,
              child: PostToolbox(pageManager.posts[page.value]),
            )
          : null,
    );
  }
}

class _PostAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PostAppBar({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomLeft,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w300),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 64);
}
