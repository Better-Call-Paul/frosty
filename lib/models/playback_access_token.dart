class PlaybackAccessToken {
  final String value;
  final String signature;

  const PlaybackAccessToken({
    required this.value,
    required this.signature,
  });

  factory PlaybackAccessToken.fromGqlResponse(Map<String, dynamic> json) {
    final data = json['data']['streamPlaybackAccessToken']
        as Map<String, dynamic>;
    return PlaybackAccessToken(
      value: data['value'] as String,
      signature: data['signature'] as String,
    );
  }
}
