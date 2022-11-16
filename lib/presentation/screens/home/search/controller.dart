import 'package:boorusphere/presentation/provider/booru/page_state.dart';
import 'package:boorusphere/utils/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final searchBarController = ChangeNotifierProvider((ref) {
  final pageQuery = ref.read(pageProvider.select((it) => it.data.option.query));
  return SearchBarController(ref, pageQuery);
});

class SearchBarController extends ChangeNotifier {
  SearchBarController(this.ref, this.initialText);

  final Ref ref;
  final String initialText;
  late final _textController = TextEditingController(text: initialText);
  bool _isOpen = false;

  bool get isOpen => _isOpen;
  bool get isTextChanged => _textController.value.text != initialText;
  TextEditingController get textFieldController => _textController;

  String get text => _textController.value.text;

  set text(String value) {
    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange(start: value.length, end: value.length),
    );
  }

  void submit(String value) {
    text = value;
    close();
    ref
        .read(pageProvider.notifier)
        .update((state) => state.copyWith(query: value, clear: true));
  }

  void append(String value) {
    final current = text.toWordList();
    final result = {...current.take(current.length), ...value.toWordList()};
    text = '${result.join(' ')} ';
  }

  void reset() {
    text = initialText;
    notifyListeners();
  }

  void clear() {
    _textController.clear();
    notifyListeners();
  }

  void open() {
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }

  void addTextListener(Function() cb) {
    _textController.addListener(cb);
  }

  void removeTextListener(Function() cb) {
    _textController.removeListener(cb);
  }
}