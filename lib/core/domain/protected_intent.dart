import 'dart:convert';

import 'post.dart';
import 'profile.dart';

const pendingProtectedIntentTtl = Duration(minutes: 15);
const commentDraftTtl = Duration(hours: 24);

final _shortCodePattern = RegExp(r'^[A-Za-z0-9]{1,32}$');
final _commentIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
final _opaqueIdPattern = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

bool isValidPostShortCode(String value) => _shortCodePattern.hasMatch(value);

bool isValidCommentId(String value) => _commentIdPattern.hasMatch(value);

bool isValidProtectedIntentToken(String value) =>
    _opaqueIdPattern.hasMatch(value);

bool isValidCommentDraftNamespace(String value) {
  if (value == 'guest') return true;
  if (!value.startsWith('user:')) return false;
  return isValidProfileLogin(value.substring(5));
}

enum ProtectedIntentKind {
  postReaction,
  commentReaction,
  commentDraft,
  createPost,
}

final class PendingProtectedIntent {
  const PendingProtectedIntent({
    required this.id,
    required this.nonce,
    required this.kind,
    required this.createdAt,
    required this.expiresAt,
    this.postShortCode,
    this.commentId,
    this.parentCommentId,
    this.draftNamespace,
    this.returnToFeed = false,
    this.reaction,
  });

  final String id;
  final String nonce;
  final ProtectedIntentKind kind;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? postShortCode;
  final String? commentId;
  final String? parentCommentId;
  final String? draftNamespace;
  final bool returnToFeed;
  final Reaction? reaction;

  String get returnLocation {
    final shortCode = postShortCode;
    if (kind == ProtectedIntentKind.createPost) return '/create';
    if (kind == ProtectedIntentKind.postReaction && returnToFeed) {
      return '/feed';
    }
    if (shortCode == null) return '/feed';
    final focusId = kind == ProtectedIntentKind.commentReaction
        ? commentId
        : parentCommentId;
    if (focusId == null) return '/post/$shortCode';
    return '/post/$shortCode/comment/$focusId';
  }

  bool isValidAt(DateTime now) {
    final utcNow = now.toUtc();
    final lifetime = expiresAt.difference(createdAt);
    if (!isValidProtectedIntentToken(id) ||
        !isValidProtectedIntentToken(nonce) ||
        createdAt.isAfter(utcNow) ||
        !expiresAt.isAfter(createdAt) ||
        lifetime > pendingProtectedIntentTtl ||
        !expiresAt.isAfter(utcNow)) {
      return false;
    }
    if (kind == ProtectedIntentKind.createPost) {
      return postShortCode == null &&
          commentId == null &&
          parentCommentId == null &&
          draftNamespace == null &&
          !returnToFeed &&
          reaction == null;
    }
    final shortCode = postShortCode;
    if (shortCode == null || !isValidPostShortCode(shortCode)) return false;
    switch (kind) {
      case ProtectedIntentKind.postReaction:
        return reaction != null &&
            reaction != Reaction.none &&
            commentId == null &&
            parentCommentId == null &&
            draftNamespace == null;
      case ProtectedIntentKind.commentReaction:
        return commentId != null &&
            isValidCommentId(commentId!) &&
            reaction != null &&
            reaction != Reaction.none &&
            parentCommentId == null &&
            draftNamespace == null &&
            !returnToFeed;
      case ProtectedIntentKind.commentDraft:
        return commentId == null &&
            reaction == null &&
            draftNamespace != null &&
            isValidCommentDraftNamespace(draftNamespace!) &&
            !returnToFeed &&
            (parentCommentId == null || isValidCommentId(parentCommentId!));
      case ProtectedIntentKind.createPost:
        return false;
    }
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'id': id,
    'nonce': nonce,
    'kind': kind.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'postShortCode': postShortCode,
    'commentId': commentId,
    'parentCommentId': parentCommentId,
    'draftNamespace': draftNamespace,
    'returnToFeed': returnToFeed,
    'reaction': reaction?.name,
  };

  static PendingProtectedIntent fromJson(Map<String, Object?> json) {
    if (json['version'] != 1) {
      throw const FormatException('Invalid pending intent version.');
    }
    final id = json['id'];
    final nonce = json['nonce'];
    final kind = json['kind'];
    final createdAt = json['createdAt'];
    final expiresAt = json['expiresAt'];
    if (id is! String ||
        nonce is! String ||
        kind is! String ||
        createdAt is! String ||
        expiresAt is! String) {
      throw const FormatException('Invalid pending intent fields.');
    }
    final parsedCreatedAt = DateTime.tryParse(createdAt)?.toUtc();
    final parsedExpiresAt = DateTime.tryParse(expiresAt)?.toUtc();
    final parsedKind = ProtectedIntentKind.values
        .where((value) => value.name == kind)
        .firstOrNull;
    final rawReaction = json['reaction'];
    final rawReturnToFeed = json['returnToFeed'];
    final parsedReaction = rawReaction == null
        ? null
        : rawReaction is String
        ? Reaction.values
              .where((value) => value.name == rawReaction)
              .firstOrNull
        : null;
    if (parsedCreatedAt == null ||
        parsedExpiresAt == null ||
        parsedKind == null ||
        rawReturnToFeed is! bool ||
        (rawReaction != null && parsedReaction == null)) {
      throw const FormatException('Invalid pending intent values.');
    }
    return PendingProtectedIntent(
      id: id,
      nonce: nonce,
      kind: parsedKind,
      createdAt: parsedCreatedAt,
      expiresAt: parsedExpiresAt,
      postShortCode: _nullableString(json['postShortCode']),
      commentId: _nullableString(json['commentId']),
      parentCommentId: _nullableString(json['parentCommentId']),
      draftNamespace: _nullableString(json['draftNamespace']),
      returnToFeed: rawReturnToFeed,
      reaction: parsedReaction,
    );
  }
}

final class CommentDraft {
  const CommentDraft({
    required this.postShortCode,
    required this.body,
    required this.updatedAt,
    required this.expiresAt,
    this.parentCommentId,
  });

  final String postShortCode;
  final String body;
  final String? parentCommentId;
  final DateTime updatedAt;
  final DateTime expiresAt;

  bool isValidAt(DateTime now) {
    final utcNow = now.toUtc();
    final lifetime = expiresAt.difference(updatedAt);
    return isValidPostShortCode(postShortCode) &&
        body.length <= 2000 &&
        !updatedAt.isAfter(utcNow) &&
        expiresAt.isAfter(updatedAt) &&
        lifetime <= commentDraftTtl &&
        expiresAt.isAfter(utcNow) &&
        (parentCommentId == null || isValidCommentId(parentCommentId!));
  }

  String encode() => jsonEncode({
    'version': 1,
    'postShortCode': postShortCode,
    'body': body,
    'parentCommentId': parentCommentId,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  });

  static CommentDraft decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['version'] != 1) {
      throw const FormatException('Invalid comment draft payload.');
    }
    final postShortCode = decoded['postShortCode'];
    final body = decoded['body'];
    final updatedAt = decoded['updatedAt'];
    final expiresAt = decoded['expiresAt'];
    if (postShortCode is! String ||
        body is! String ||
        updatedAt is! String ||
        expiresAt is! String) {
      throw const FormatException('Invalid comment draft fields.');
    }
    final parsedUpdatedAt = DateTime.tryParse(updatedAt)?.toUtc();
    final parsedExpiresAt = DateTime.tryParse(expiresAt)?.toUtc();
    if (parsedUpdatedAt == null || parsedExpiresAt == null) {
      throw const FormatException('Invalid comment draft dates.');
    }
    return CommentDraft(
      postShortCode: postShortCode,
      body: body,
      parentCommentId: _nullableString(decoded['parentCommentId']),
      updatedAt: parsedUpdatedAt,
      expiresAt: parsedExpiresAt,
    );
  }
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Invalid optional string field.');
  }
  return value;
}
