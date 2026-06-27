import '../utils/typedef.dart';

abstract class UseCase<Type, Params> {
  const UseCase();
  ResultFuture<Type> call(Params params);
}

class NoParams {
  const NoParams();
}
