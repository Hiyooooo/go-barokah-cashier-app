import '../../../../core/network/api_client.dart';
import '../models/user_profile.dart';

class UserProfileRemoteDataSource {
  const UserProfileRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfile> getProfile() async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/users/me',
    );
    return UserProfile.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required String name,
    String? phoneNumber,
  }) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/users',
      method: 'PATCH',
      data: {'username': name, 'phone_number': phoneNumber},
    );
    return UserProfile.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
