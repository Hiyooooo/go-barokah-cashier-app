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

final profileUpdateProvider =
    AsyncNotifierProvider<ProfileUpdateNotifier, void>(
      ProfileUpdateNotifier.new,
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

class ProfileUpdateNotifier extends AsyncNotifier<void> {
  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<UserProfile> saveProfile({
    required String name,
    String? phoneNumber,
  }) async {
    state = const AsyncLoading();
    try {
      final profile = await _repository.updateProfile(
        name: name,
        phoneNumber: phoneNumber,
      );
      state = const AsyncData(null);
      ref.read(userProfileProvider.notifier).state = AsyncData(profile);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
