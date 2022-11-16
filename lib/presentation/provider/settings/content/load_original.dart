import 'package:boorusphere/data/repository/setting/entity/setting.dart';
import 'package:boorusphere/domain/repository/setting_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadOriginalPostSettingNotifier extends StateNotifier<bool> {
  LoadOriginalPostSettingNotifier(super.state, this.repo);

  final SettingRepo repo;

  Future<void> update(bool value) async {
    state = value;
    await repo.put(Setting.postLoadOriginal, value);
  }
}