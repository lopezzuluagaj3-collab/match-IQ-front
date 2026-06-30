import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({required this.message, this.statusCode = 500});
  final String message;
  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network and try again.',
    super.statusCode = 503,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode = 400});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode = 401});
}
