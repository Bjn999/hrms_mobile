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
}
