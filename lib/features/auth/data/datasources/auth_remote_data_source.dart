import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> getUserProfile();

  Future<UserModel> updateProfile({
    String? email,
    String? username,
    String? password,
    String? passwordConfirmation,
    String? phone,
    String? address,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) async {
    final response = await client.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
        'device_name': 'hrms_mobile_app',
      },
    );

    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await client.post(ApiEndpoints.logout);
  }

  @override
  Future<UserModel> getUserProfile() async {
    final response = await client.get(ApiEndpoints.userProfile);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> updateProfile({
    String? email,
    String? username,
    String? password,
    String? passwordConfirmation,
    String? phone,
    String? address,
  }) async {
    final payload = <String, dynamic>{};
    if (email != null && email.trim().isNotEmpty) payload['email'] = email.trim();
    if (username != null && username.trim().isNotEmpty) payload['username'] = username.trim();
    if (password != null && password.isNotEmpty) {
      payload['password'] = password;
      payload['password_confirmation'] = passwordConfirmation ?? password;
    }
    if (phone != null) payload['emp_home_tel'] = phone.trim();
    if (address != null) payload['staies_address'] = address.trim();

    final response = await client.put(
      ApiEndpoints.updateProfile,
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
