import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(apiClient: ref.watch(apiClientProvider)),
);

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  @override
  Future<UserProfile> build() => _repository.getProfile();

  Future<void> updateProfile({
    required String name,
    String? phoneNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updateProfile(name: name, phoneNumber: phoneNumber),
    );
  }
}
