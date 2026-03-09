// Models for Twitch GQL VOD chat comments.
//
// Manually parsed (no codegen) because the GQL response uses camelCase
// and deeply nested edges/node patterns.

class GqlChatEmote {
  final String emoteId;

  const GqlChatEmote({required this.emoteId});

  factory GqlChatEmote.fromJson(Map<String, dynamic> json) {
    return GqlChatEmote(emoteId: json['emoteID'] as String);
  }
}

class GqlChatFragment {
  final String? text;
  final GqlChatEmote? emote;

  const GqlChatFragment({this.text, this.emote});

  factory GqlChatFragment.fromJson(Map<String, dynamic> json) {
    return GqlChatFragment(
      text: json['text'] as String?,
      emote: json['emote'] != null
          ? GqlChatEmote.fromJson(json['emote'] as Map<String, dynamic>)
          : null,
    );
  }
}

class GqlChatBadge {
  final String setId;
  final String version;

  const GqlChatBadge({required this.setId, required this.version});

  factory GqlChatBadge.fromJson(Map<String, dynamic> json) {
    return GqlChatBadge(
      setId: json['setID'] as String,
      version: json['version'] as String,
    );
  }
}

class GqlChatComment {
  final String id;
  final int contentOffsetSeconds;
  final String? commenterLogin;
  final String? commenterDisplayName;
  final String? commenterId;
  final String? userColor;
  final List<GqlChatBadge> userBadges;
  final List<GqlChatFragment> messageFragments;

  const GqlChatComment({
    required this.id,
    required this.contentOffsetSeconds,
    this.commenterLogin,
    this.commenterDisplayName,
    this.commenterId,
    this.userColor,
    required this.userBadges,
    required this.messageFragments,
  });

  factory GqlChatComment.fromGqlNode(Map<String, dynamic> node) {
    final commenter = node['commenter'] as Map<String, dynamic>?;
    final message = node['message'] as Map<String, dynamic>;

    return GqlChatComment(
      id: node['id'] as String,
      contentOffsetSeconds: node['contentOffsetSeconds'] as int,
      commenterLogin: commenter?['login'] as String?,
      commenterDisplayName: commenter?['displayName'] as String?,
      commenterId: commenter?['id'] as String?,
      userColor: message['userColor'] as String?,
      userBadges: (message['userBadges'] as List)
          .map((b) => GqlChatBadge.fromJson(b as Map<String, dynamic>))
          .toList(),
      messageFragments: (message['fragments'] as List)
          .map((f) => GqlChatFragment.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GqlChatResponse {
  final List<GqlChatComment> comments;
  final bool hasNextPage;
  final String? cursor;

  const GqlChatResponse({
    required this.comments,
    required this.hasNextPage,
    this.cursor,
  });

  factory GqlChatResponse.fromJson(Map<String, dynamic> json) {
    // GQL returns 200 even on errors — check for errors array.
    if (json['errors'] != null) {
      final errors = json['errors'] as List;
      final message = errors.isNotEmpty
          ? (errors.first as Map<String, dynamic>)['message'] as String?
          : 'Unknown GQL error';
      throw Exception('GQL error: $message');
    }

    final video = json['data']?['video'] as Map<String, dynamic>?;
    if (video == null) {
      return const GqlChatResponse(
        comments: [],
        hasNextPage: false,
      );
    }

    final commentsData = video['comments'] as Map<String, dynamic>;
    final edges = commentsData['edges'] as List;
    final pageInfo = commentsData['pageInfo'] as Map<String, dynamic>;

    final comments = edges
        .map((edge) => GqlChatComment.fromGqlNode(
              (edge as Map<String, dynamic>)['node'] as Map<String, dynamic>,
            ))
        .toList();

    final cursor = edges.isNotEmpty
        ? (edges.last as Map<String, dynamic>)['cursor'] as String?
        : null;

    return GqlChatResponse(
      comments: comments,
      hasNextPage: pageInfo['hasNextPage'] as bool,
      cursor: cursor,
    );
  }
}
