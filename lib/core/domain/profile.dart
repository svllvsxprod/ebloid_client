import 'content_state.dart';
import 'post.dart';

final _profileLoginPattern = RegExp(r'^[A-Za-z0-9_]{1,25}$');

bool isValidProfileLogin(String login) => _profileLoginPattern.hasMatch(login);

final class SessionUser {
  const SessionUser({required this.login, required this.avatarUrl});

  final String login;
  final Uri avatarUrl;
}

final class ProfilePostsPage {
  const ProfilePostsPage({
    required this.login,
    required this.items,
    required this.total,
    this.nextCursor,
    this.source = PageSource.remote,
    this.scope = PageScope.public,
    this.fetchedAt,
  }) : assert(
         source != PageSource.cache || fetchedAt != null,
         'Cached profile page requires fetchedAt.',
       );

  final String login;
  final List<PostSummary> items;
  final int total;
  final PageCursor? nextCursor;
  final PageSource source;
  final PageScope scope;
  final DateTime? fetchedAt;

  UserRef? get inferredOwner => items.firstOrNull?.author;
}
