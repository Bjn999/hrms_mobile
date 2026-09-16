import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/biometric_login_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../network/dio_client.dart';
import '../services/biometric_service.dart';
import '../storage/secure_storage_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // -------------------------------------------------------------
  // 1. External & Core Services
  // -------------------------------------------------------------
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  sl.registerLazySingleton<LocalAuthentication>(
    () => LocalAuthentication(),
  );

  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(storage: sl()),
  );

  sl.registerLazySingleton<BiometricService>(
    () => BiometricService(auth: sl()),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(sl()),
  );

  // -------------------------------------------------------------
  // 2. Data Sources
  // -------------------------------------------------------------
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(storage: sl()),
  );

  // -------------------------------------------------------------
  // 3. Repositories
  // -------------------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      biometricService: sl(),
    ),
  );

  // -------------------------------------------------------------
  // 4. Use Cases
  // -------------------------------------------------------------
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => BiometricLoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));

  // -------------------------------------------------------------
  // 5. Cubits (Factory for fresh instances per view if needed)
  // -------------------------------------------------------------
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      biometricLoginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      authRepository: sl(),
    ),
  );
}
