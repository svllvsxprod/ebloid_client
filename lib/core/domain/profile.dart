import 'content_state.dart';
import 'post.dart';

final _profileLoginPattern = RegExp(r'^[A-Za-z0-9_]{1,25}$');

bool isValidProfileLogin(String login) => _profileLoginPattern.hasMatch(login);

final class ProfilePostsPage {
  const ProfilePostsPage({
    required this.login,
    required this.items,
    required this.total,
    this.nextCursor,
  });

  final String login;
  final List<PostSummary> items;
  final int total;
  final PageCursor? nextCursor;

  UserRef? get inferredOwner => items.firstOrNull?.author;
}
