import '../../../../core/network/api_client.dart';
import '../datasources/user_profile_remote_data_source.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({required ApiClient apiClient})
    : _dataSource = UserProfileRemoteDataSource(apiClient);

  final UserProfileRemoteDataSource _dataSource;

  Future<UserProfile> getProfile() => _dataSource.getProfile();

  Future<UserProfile> updateProfile({
    required String name,
    String? phoneNumber,
  }) => _dataSource.updateProfile(name: name, phoneNumber: phoneNumber);
}
