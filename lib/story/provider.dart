import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class Story {
  final Map story;
  Story(this.story);

  String get url => story['url'];
  String get caption => story['caption'];
  DocumentReference get sponsor => story['sponsor'];
  bool get isPromoted => story['promoted'] ?? false;
  String get promotionUrl => story['promotionUrl'];
  GeoPoint get geoPoint => story['geoPoint'];
  String get location => story['locationPlaceholder'];
  Color get color => Color(story['color']);
  String get mime => story['mime'];
  int get timestamp => story['timestamp'];
  Future<Post> get post async => Post(doc: await story['postRef'].get());
  String get postId => story['postId'];
  StoryType get type {
    if (story['type'] == "image") return StoryType.image;
    else if (story['type'] == "video") return StoryType.video;
    else if (story['type'] == "text") return StoryType.text;
    else if (story['type'] == "post") return StoryType.post;
    else return null;
  }
  /// Font of text
  String get font => story['font'] ?? 'Roboto';
  /// Get duration of VIDEO in seconds
  int get duration => story['duration'] ?? 10;
  Map get views => story['views'];
  Map get swipes => story['swipes'];
  String get since => getTimeAgo(new DateTime.fromMillisecondsSinceEpoch(story['timestamp']), includeHour: false);

  Future<void> delete() async {
    await me.update({
      'story.$timestamp': FieldValue.delete()
    });
    await me.reload();
    print('Story Deleted');
  }

  Future<void> updateCaption(String caption) async {
    await me.update({
      'story.$timestamp.caption': caption
    });
  }

  Future<void> updateColor(Color color) async {
    await me.update({
      'story.$timestamp.color': color.value
    });
  }

}

enum StoryType {
  video,
  image,
  post,
  text
}