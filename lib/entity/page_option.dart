import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_option.freezed.dart';

@freezed
class PageOption with _$PageOption {
  const PageOption._();
  const factory PageOption({
    @Default('') String query,
    @Default(false) bool clear,
  }) = _PageOption;
}