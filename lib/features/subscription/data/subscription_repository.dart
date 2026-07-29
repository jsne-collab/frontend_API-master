import '../domain/subscription_model.dart';
import 'subscription_api.dart';

class SubscriptionRepository {
  SubscriptionRepository({SubscriptionApi? api})
    : _api = api ?? SubscriptionApi();

  final SubscriptionApi _api;

  Future<SubscriptionInfo> show() async {
    final response = await _api.show();
    return SubscriptionInfo.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> initiate(Map<String, dynamic> data) => _api.initiate(data);
}
