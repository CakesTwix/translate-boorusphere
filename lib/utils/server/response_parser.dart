import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:xml2json/xml2json.dart';

import '../../entity/post.dart';
import '../../entity/server_data.dart';
import '../../entity/sphere_exception.dart';
import '../extensions/map.dart';

class ServerResponseParser {
  static List<Post> parsePage(ServerData server, Response res) {
    final data = res.data;

    if (res.statusCode != 200) {
      throw SphereException(
          message: 'Cannot fetch page (HTTP ${res.statusCode})');
    } else if (!data.toString().contains(RegExp('https?'))) {
      // no url founds in the document means no image(s) available to display
      return [];
    }

    const cantParse = SphereException(message: 'Cannot parse result');

    final entries = [];
    if (data is List) {
      entries.addAll(res.data);
    } else if (data is Map && data.keys.contains('post')) {
      entries.addAll(data['post']);
    } else if (data is String && data.contains('<?xml')) {
      final xjson = Xml2Json();
      xjson.parse(data.replaceAll('\\', ''));

      final jsonObj = jsonDecode(xjson.toGData());
      if (!jsonObj.values.first.keys.contains('post')) {
        throw cantParse;
      }

      final posts = jsonObj.values.first['post'];
      if (posts is LinkedHashMap) {
        entries.add(posts);
      } else if (posts is List) {
        entries.addAll(posts);
      } else {
        throw cantParse;
      }
    } else {
      throw cantParse;
    }

    final result = <Post>[];

    final idKey = ['id'];
    final originalFileKey = ['file_url'];
    final sampleFileKey = ['large_file_url', 'sample_url'];
    final previewFileKey = ['preview_url', 'preview_file_url'];
    final tagsKey = ['tags', 'tag_string'];
    final widthKey = ['image_width', 'width'];
    final heightKey = ['image_height', 'height'];
    final sampleWidthKey = ['sample_width'];
    final sampleHeightKey = ['sample_height'];
    final previewWidthKey = ['preview_width'];
    final previewHeightKey = ['preview_height'];
    final sourceKey = ['source'];
    final ratingKey = ['rating'];
    final tagsArtistKey = ['tag_string_artist'];
    final tagsCharacterKey = ['tag_string_character'];
    final tagsCopyrightKey = ['tag_string_copyright'];
    final tagsGeneralKey = ['tag_string_general'];
    final tagsMetaKey = ['tag_string_meta'];

    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final post = entry;
      final id = post.take(idKey, orElse: -1);
      if (result.any((it) => it.id == id)) {
        // duplicated result, skipping
        continue;
      }

      final originalFile = post.take(originalFileKey, orElse: '');
      final sampleFile = post.take(sampleFileKey, orElse: '');
      final previewFile = post.take(previewFileKey, orElse: '');
      final tags = post.take(tagsKey, orElse: <String>[]);
      final width = post.take(widthKey, orElse: -1);
      final height = post.take(heightKey, orElse: -1);
      final sampleWidth = post.take(sampleWidthKey, orElse: -1);
      final sampleHeight = post.take(sampleHeightKey, orElse: -1);
      final previewWidth = post.take(previewWidthKey, orElse: -1);
      final previewHeight = post.take(previewHeightKey, orElse: -1);
      final rating = post.take(ratingKey, orElse: 'q');
      final source = post.take(sourceKey, orElse: '');
      final tagsArtist = post.take(tagsArtistKey, orElse: <String>[]);
      final tagsCharacter = post.take(tagsCharacterKey, orElse: <String>[]);
      final tagsCopyright = post.take(tagsCopyrightKey, orElse: <String>[]);
      final tagsGeneral = post.take(tagsGeneralKey, orElse: <String>[]);
      final tagsMeta = post.take(tagsMetaKey, orElse: <String>[]);

      final hasFile = originalFile.isNotEmpty && previewFile.isNotEmpty;
      final hasContent = width > 0 && height > 0;
      final postUrl = id < 0 ? '' : server.postUrlOf(id);

      if (hasFile && hasContent) {
        result.add(
          Post(
            id: id,
            originalFile: normalizeUrl(server, originalFile),
            sampleFile: normalizeUrl(server, sampleFile),
            previewFile: normalizeUrl(server, previewFile),
            tags: tags,
            width: width,
            height: height,
            sampleWidth: sampleWidth,
            sampleHeight: sampleHeight,
            previewWidth: previewWidth,
            previewHeight: previewHeight,
            serverName: server.name,
            postUrl: postUrl,
            rateValue: rating.isEmpty ? 'q' : rating,
            source: source,
            tagsArtist: tagsArtist,
            tagsCharacter: tagsCharacter,
            tagsCopyright: tagsCopyright,
            tagsGeneral: tagsGeneral,
            tagsMeta: tagsMeta,
          ),
        );
      }
    }

    return result;
  }

  static Set<String> parseTagSuggestion(Response res, String query) {
    final data = res.data;
    if (res.statusCode != 200) {
      throw SphereException(
          message: 'Cannot fetch data (HTTP ${res.statusCode})');
    }

    final noTagsError =
        SphereException(message: 'No tags that matches \'$query\'');

    final entries = [];
    if (data is List) {
      entries.addAll(data);
    } else if (data is Map && data.keys.contains('tag')) {
      entries.addAll(data['tag']);
    } else if (data.toString().isEmpty) {
      return {};
    } else if (data is String && data.contains('<?xml')) {
      final xjson = Xml2Json();
      xjson.parse(data.replaceAll('\\', ''));

      final jsonObj = jsonDecode(xjson.toGData());
      if (!jsonObj.values.first.keys.contains('tag')) {
        throw noTagsError;
      }

      final tags = jsonObj.values.first['tag'];
      if (tags is LinkedHashMap) {
        entries.add(tags);
      } else if (tags is List) {
        entries.addAll(tags);
      } else {
        throw noTagsError;
      }
    } else {
      throw noTagsError;
    }

    final result = <String>{};
    for (final Map<String, dynamic> entry in entries) {
      final tag = entry.take(['name', 'tag'], orElse: '');
      final postCount = entry.take(['post_count', 'count'], orElse: 0);
      if (postCount > 0) result.add(tag);
    }

    return result;
  }

  static String normalizeUrl(ServerData serverData, String urlString) {
    try {
      final uri = Uri.parse(urlString);
      if (uri.hasScheme && uri.hasAuthority && uri.hasAbsolutePath) {
        // valid url, there's nothing to do
        return urlString;
      }

      if (uri.hasAuthority && uri.hasAbsolutePath && !uri.hasScheme) {
        final origin = Uri.parse(serverData.apiAddress);
        final scheme = origin.scheme == 'https' ? Uri.https : Uri.http;
        return scheme(uri.authority, uri.path,
                uri.hasQuery ? uri.queryParametersAll : null)
            .toString();
      }

      // nothing we can do when there's no authority and path
      return '';
    } catch (e) {
      return '';
    }
  }
}
