import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/market_analytics.dart';
import '../../infrastructure/datasources/app_datasource.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.market,
    this.insights,
    this.isLoadingMarket = false,
    this.isLoadingInsights = false,
    this.error,
  });

  final MarketAnalytics? market;
  final MarketAnalytics? insights;
  final bool isLoadingMarket;
  final bool isLoadingInsights;
  final String? error;

  AnalyticsState copyWith({
    MarketAnalytics? market,
    MarketAnalytics? insights,
    bool? isLoadingMarket,
    bool? isLoadingInsights,
    String? error,
  }) =>
      AnalyticsState(
        market: market ?? this.market,
        insights: insights ?? this.insights,
        isLoadingMarket: isLoadingMarket ?? this.isLoadingMarket,
        isLoadingInsights: isLoadingInsights ?? this.isLoadingInsights,
        error: error,
      );

  @override
  List<Object?> get props =>
      [market, insights, isLoadingMarket, isLoadingInsights, error];
}

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(this._datasource) : super(const AnalyticsState());

  final AppDatasource _datasource;

  Future<void> loadMarket() async {
    emit(state.copyWith(isLoadingMarket: true, error: null));
    final result = await _datasource.getMarketAnalytics();
    result.fold(
      (f) => emit(state.copyWith(isLoadingMarket: false, error: f.message)),
      (data) => emit(state.copyWith(isLoadingMarket: false, market: data)),
    );
  }

  Future<void> loadInsights() async {
    emit(state.copyWith(isLoadingInsights: true, error: null));
    final result = await _datasource.getCandidateInsights();
    result.fold(
      (f) => emit(state.copyWith(isLoadingInsights: false, error: f.message)),
      (data) => emit(state.copyWith(isLoadingInsights: false, insights: data)),
    );
  }
}
