import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_initializer.dart';
import '../models/post.dart';

class RealtimePostStreamService {
  RealtimePostStreamService._();

  static final RealtimePostStreamService instance =
      RealtimePostStreamService._();

  bool get isAvailable => FirebaseInitializer.isReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<List<PostModel>> watchFeed({int limit = 50}) {
    if (!isAvailable) {
      return const Stream<List<PostModel>>.empty();
    }

    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromJson(_normalizePostData(doc)))
              .toList(growable: false);
        })
        .handleError((error, stackTrace) {
          debugPrint('Realtime feed error: $error');
          debugPrintStack(label: 'Realtime feed stack', stackTrace: stackTrace);
        });
  }

  Stream<PostModel?> watchPostById(String postId) {
    if (!isAvailable) {
      return const Stream<PostModel?>.empty();
    }

    final docRef = _firestore.collection('posts').doc(postId);
    final commentsQuery = docRef
        .collection('comments')
        .orderBy('createdAt', descending: false);

    return Stream.multi((controller) {
      DocumentSnapshot<Map<String, dynamic>>? latestDoc;
      QuerySnapshot<Map<String, dynamic>>? latestComments;

      void emitLatest() {
        final doc = latestDoc;
        if (doc == null || !doc.exists) {
          controller.add(null);
          return;
        }
        final normalized = _normalizePostData(
          doc,
          latestComments?.docs
                  .map(_normalizeCommentData)
                  .toList(growable: false),
        );
        try {
          controller.add(PostModel.fromJson(normalized));
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }

      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? postSub;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? commentsSub;

      controller.onListen = () {
        postSub = docRef.snapshots().listen((snapshot) {
          latestDoc = snapshot;
          emitLatest();
        }, onError: controller.addError);

        commentsSub = commentsQuery.snapshots().listen((snapshot) {
          latestComments = snapshot;
          emitLatest();
        }, onError: controller.addError);
      };

      controller.onCancel = () async {
        await postSub?.cancel();
        await commentsSub?.cancel();
      };
    });
  }

  Map<String, dynamic> _normalizePostData(
    DocumentSnapshot<Map<String, dynamic>> doc, [
    List<Map<String, dynamic>>? comments,
  ]) {
    final rawData = doc.data() ?? const <String, dynamic>{};
    final normalized = <String, dynamic>{
      ..._sanitizeMap(rawData),
    };
    normalized.putIfAbsent('id', () => doc.id);
    normalized.putIfAbsent('postId', () => doc.id);

    if (comments != null) {
      normalized['comments'] = comments;
      normalized['commentCount'] = comments.length;
    }

    final likeArrays = normalized['likedByUserIds'] ??
        normalized['likedBy'] ??
        normalized['likesArray'];
    if (likeArrays is Iterable) {
      normalized['likedByUserIds'] = likeArrays
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      normalized['likes'] ??= normalized['likedByUserIds'];
    }

    final likeCount = normalized['likeCount'];
    if (likeCount is num) {
      normalized['likes'] = likeCount.toInt();
    }

    if (!normalized.containsKey('createdAt') &&
        normalized.containsKey('created_at')) {
      normalized['createdAt'] = normalized['created_at'];
    }

    return normalized;
  }

  Map<String, dynamic> _normalizeCommentData(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = <String, dynamic>{
      ..._sanitizeMap(doc.data()),
    };
    map.putIfAbsent('id', () => doc.id);
    return map;
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> raw) {
    final sanitized = <String, dynamic>{};
    raw.forEach((key, value) {
      sanitized[key] = _sanitizeValue(value);
    });
    return sanitized;
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList(growable: false);
    }
    if (value is Map<String, dynamic>) {
      return value.map((key, inner) => MapEntry(key, _sanitizeValue(inner)));
    }
    return value;
  }
}
