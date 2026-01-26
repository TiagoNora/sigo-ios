// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../blocs/auth_bloc.dart' as _i384;
import '../../blocs/ticket_bloc.dart' as _i62;
import '../../data/repositories/auth_repository_impl.dart' as _i895;
import '../../data/repositories/catalog_repository_impl.dart' as _i289;
import '../../data/repositories/config_repository_impl.dart' as _i797;
import '../../data/repositories/impact_severity_repository_impl.dart' as _i296;
import '../../data/repositories/priority_repository_impl.dart' as _i1026;
import '../../data/repositories/ticket_repository_impl.dart' as _i474;
import '../../data/repositories/user_repository_impl.dart' as _i790;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/repositories/catalog_repository.dart' as _i649;
import '../../domain/repositories/config_repository.dart' as _i20;
import '../../domain/repositories/impact_severity_repository.dart' as _i361;
import '../../domain/repositories/priority_repository.dart' as _i1011;
import '../../domain/repositories/ticket_repository.dart' as _i289;
import '../../domain/repositories/user_repository.dart' as _i271;
import '../../services/biometric_service.dart' as _i286;
import '../../services/connectivity_service.dart' as _i365;
import '../../services/notification_service.dart' as _i85;
import 'modules/app_module.dart' as _i349;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => appModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i892.FirebaseMessaging>(() => appModule.firebaseMessaging);
    gh.singleton<_i163.FlutterLocalNotificationsPlugin>(
      () => appModule.localNotifications,
    );
    gh.singleton<_i558.FlutterSecureStorage>(() => appModule.secureStorage);
    gh.singleton<_i974.FirebaseFirestore>(() => appModule.firestore);
    gh.singleton<_i365.ConnectivityService>(() => _i365.ConnectivityService());
    gh.factory<_i286.BiometricService>(
      () => _i286.BiometricService(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i85.NotificationService>(
      () => _i85.NotificationService(
        gh<_i892.FirebaseMessaging>(),
        gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.singleton<_i20.ConfigRepository>(
      () => _i797.ConfigRepositoryImpl(
        gh<_i558.FlutterSecureStorage>(),
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.singleton<_i1073.AuthRepository>(
      () => _i895.AuthRepositoryImpl(
        gh<_i20.ConfigRepository>(),
        gh<_i460.SharedPreferences>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.singleton<_i1011.PriorityRepository>(
      () => _i1026.PriorityRepositoryImpl(gh<_i1073.AuthRepository>()),
    );
    gh.factory<_i384.AuthBloc>(
      () => _i384.AuthBloc(gh<_i1073.AuthRepository>()),
    );
    gh.singleton<_i289.TicketRepository>(
      () => _i474.TicketRepositoryImpl(gh<_i1073.AuthRepository>()),
    );
    gh.singleton<_i649.CatalogRepository>(
      () => _i289.CatalogRepositoryImpl(gh<_i1073.AuthRepository>()),
    );
    gh.singleton<_i361.ImpactSeverityRepository>(
      () => _i296.ImpactSeverityRepositoryImpl(gh<_i1073.AuthRepository>()),
    );
    gh.singleton<_i271.UserRepository>(
      () => _i790.UserRepositoryImpl(gh<_i1073.AuthRepository>()),
    );
    gh.factory<_i62.TicketBloc>(
      () => _i62.TicketBloc(
        gh<_i289.TicketRepository>(),
        gh<_i1073.AuthRepository>(),
        gh<_i1011.PriorityRepository>(),
        gh<_i271.UserRepository>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i349.AppModule {}
